import { createInterface } from 'node:readline';

const PREFIX = '/v1/certifica/plataforma/campanhas';
const TOKEN = process.env.MOVISYSTEM_API_TOKEN || '';
const API_URL = process.env.MOVISYSTEM_API_URL || '';
const ALLOW_HTTP_LOCAL = process.env.MOVISYSTEM_ALLOW_HTTP_LOCAL === 'true';
const TIMEOUT_MS = 15000;
const MAX_RESPONSE_BYTES = 2 * 1024 * 1024;

function config() {
  if (!TOKEN) throw new Error('MOVISYSTEM_API_TOKEN não configurado.');
  let url;
  try { url = new URL(API_URL); } catch { throw new Error('MOVISYSTEM_API_URL inválida.'); }
  const local = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
  if (url.protocol !== 'https:' && !(ALLOW_HTTP_LOCAL && local && url.protocol === 'http:'))
    throw new Error('A API deve usar HTTPS (HTTP somente para desenvolvimento local explícito).');
  if (url.username || url.password || url.search || url.hash) throw new Error('URL base não pode conter credenciais, query ou fragmento.');
  return url.toString().replace(/\/$/, '');
}

function fail(message) { throw new Error(message); }
function object(value) { return value && typeof value === 'object' && !Array.isArray(value); }
function str(value, name, max) {
  if (typeof value !== 'string' || !value.trim() || value.length > max) fail(`${name} deve ser texto não vazio (até ${max} caracteres).`);
  return value.trim();
}

async function api(method, path, body) {
  const base = config();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(base + path, {
      method, redirect: 'error', signal: controller.signal,
      headers: { Authorization: `Bearer ${TOKEN}`, Accept: 'application/json', ...(body ? { 'Content-Type': 'application/json' } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {})
    });
    const length = Number(response.headers.get('content-length') || 0);
    if (length > MAX_RESPONSE_BYTES) fail('Resposta da API acima do limite.');
    const raw = await response.text();
    if (Buffer.byteLength(raw, 'utf8') > MAX_RESPONSE_BYTES) fail('Resposta da API acima do limite.');
    let payload;
    try { payload = JSON.parse(raw); } catch { fail(`Resposta JSON inválida da API (HTTP ${response.status}).`); }
    if (!response.ok) fail(`API recusou a operação (HTTP ${response.status}): ${String(payload?.message || payload?.mensagem || 'Verifique permissões e dados.').slice(0,300)}`);
    return payload;
  } finally { clearTimeout(timer); }
}

const tools = [
  { name: 'criar_rascunho_campanha', description: 'Cria SOMENTE um rascunho de campanha na plataforma SaaS. Nunca inicia envio, não adiciona destinatários ou anexos.', inputSchema: { type: 'object', additionalProperties: false, properties: {
    nome: { type: 'string', maxLength: 180, description: 'Nome da campanha' },
    canal: { type: 'string', enum: ['WHATSAPP', 'EMAIL', 'AMBOS'] },
    mensagem_whatsapp: { type: 'string', description: 'Obrigatória para WHATSAPP ou AMBOS' },
    assunto_email: { type: 'string', description: 'Obrigatório para EMAIL ou AMBOS' },
    corpo_email: { type: 'string', description: 'Obrigatório para EMAIL ou AMBOS' }
  }, required: ['nome', 'canal'] } },
  { name: 'consultar_campanha', description: 'Consulta uma campanha existente por ID, sem alterá-la.', inputSchema: { type: 'object', additionalProperties: false, properties: { id: { type: 'integer', minimum: 1 } }, required: ['id'] } }
];

async function callTool(name, args) {
  if (!object(args)) fail('Argumentos inválidos.');
  if (name === 'criar_rascunho_campanha') {
    if (Object.keys(args).some(k => !['nome','canal','mensagem_whatsapp','assunto_email','corpo_email'].includes(k))) fail('Campos desconhecidos.');
    const nome = str(args.nome, 'nome', 180);
    const canal = args.canal;
    if (!['WHATSAPP','EMAIL','AMBOS'].includes(canal)) fail('Canal inválido.');
    const mensagem_whatsapp = canal !== 'EMAIL' ? str(args.mensagem_whatsapp, 'mensagem_whatsapp', 50000) : '';
    const assunto_email = canal !== 'WHATSAPP' ? str(args.assunto_email, 'assunto_email', 500) : '';
    const corpo_email = canal !== 'WHATSAPP' ? str(args.corpo_email, 'corpo_email', 500000) : '';
    const data = await api('POST', PREFIX, { nome, canal, mensagem_whatsapp, assunto_email, corpo_email, tipo_envio: 'IMEDIATO' });
    return { aviso: 'Rascunho criado. Nenhum envio foi iniciado.', resultado: data };
  }
  if (name === 'consultar_campanha') {
    if (Object.keys(args).some(k => k !== 'id') || !Number.isSafeInteger(args.id) || args.id <= 0) fail('ID inválido.');
    return await api('GET', `${PREFIX}/${args.id}`);
  }
  fail('Ferramenta não disponível.');
}

function reply(id, result) { process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, result }) + '\n'); }
function error(id, code, message) { process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, error: { code, message } }) + '\n'); }
async function dispatch(msg) {
  if (!object(msg) || msg.jsonrpc !== '2.0') return;
  if (!Object.hasOwn(msg, 'id')) return; // notifications never receive replies
  const id = msg.id;
  try {
    if (msg.method === 'initialize') return reply(id, { protocolVersion: '2024-11-05', capabilities: { tools: {} }, serverInfo: { name: 'movisystem-campanhas', version: '0.1.0' } });
    if (msg.method === 'ping') return reply(id, {});
    if (msg.method === 'tools/list') return reply(id, { tools });
    if (msg.method === 'tools/call') {
      const name = msg.params?.name;
      try {
        const result = await callTool(name, msg.params?.arguments ?? {});
        return reply(id, { content: [{ type: 'text', text: JSON.stringify(result) }] });
      } catch (e) {
        return reply(id, { isError: true, content: [{ type: 'text', text: e instanceof Error ? e.message : 'Erro desconhecido.' }] });
      }
    }
    error(id, -32601, 'Método não encontrado.');
  } catch { error(id, -32603, 'Erro interno.'); }
}
const rl = createInterface({ input: process.stdin, crlfDelay: Infinity });
rl.on('line', line => {
  if (Buffer.byteLength(line, 'utf8') > 1024 * 1024) return;
  try { void dispatch(JSON.parse(line)); } catch { /* ignore malformed input */ }
});
