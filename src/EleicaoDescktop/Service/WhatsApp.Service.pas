unit WhatsApp.Service;

interface

uses
  System.JSON,
  RESTRequest4D,
  REST.Types,
  DataSet.Serialize.Adapter.RESTRequest4D,
  System.SysUtils;

type
  TWhatsAppService = class
  private
    class function SomenteNumeros(const AValor: string): string; static;
    class function RespostaSucesso(const Resposta: IResponse): Boolean; static;
    function RecursoInstancia(const Prefixo, NomeInstancia: string): string;
    class function MensagemResposta(const Resposta: IResponse): string; static;
    class function JSONTexto(const Conteudo, Caminho: string): string; static;
  public
    class function EnviarCodigoConfirmacao(
      const AURL: string;
      const AInstancia: string;
      const AAPIKey: string;
      const ANumero: string;
      const ANome: string;
      const ACodigo: string;
      out AMensagemRetorno: string
    ): Boolean; static;

    class function MessageText(
      out AMsg: string;
      const AURL: string;
      const ANomeInstanciaweb: string;
      const ANumero: string;
      const AMensagem: string;
      const AAPIKEY: string
    ): Boolean; static;

    class function EnviarComprovanteVotacao(
      const AURL: string;
      const AInstancia: string;
      const AAPIKey: string;
      const ANumero: string;
      const ANome: string;
      const AComprovante: string;
      out AMensagemRetorno: string
    ): Boolean; static;
  end;

implementation

{ TWhatsAppService }

class function TWhatsAppService.SomenteNumeros(const AValor: string): string;
var
  C: Char;
begin
  Result := '';

  for C in AValor do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

class function TWhatsAppService.EnviarCodigoConfirmacao(
  const AURL: string;
  const AInstancia: string;
  const AAPIKey: string;
  const ANumero: string;
  const ANome: string;
  const ACodigo: string;
  out AMensagemRetorno: string): Boolean;
var
  Numero: string;
  Mensagem: string;
begin
  Numero := SomenteNumeros(ANumero);

  if Numero.IsEmpty then
  begin
    AMensagemRetorno := 'Número de WhatsApp não informado.';
    Exit(False);
  end;

  if Trim(AURL).IsEmpty then
  begin
    AMensagemRetorno := 'URL do WhatsApp não informada.';
    Exit(False);
  end;

  if Trim(AInstancia).IsEmpty then
  begin
    AMensagemRetorno := 'Instância do WhatsApp não informada.';
    Exit(False);
  end;

  if Trim(AAPIKey).IsEmpty then
  begin
    AMensagemRetorno := 'Token do WhatsApp não informado.';
    Exit(False);
  end;

  Mensagem :=
    'Olá, ' + Trim(ANome) + '.' + sLineBreak + sLineBreak +
    'Seu código de confirmação para acessar a votação é:' + sLineBreak + sLineBreak +
    '*' + Trim(ACodigo) + '*' + sLineBreak + sLineBreak +
    'Este código é válido por 1 minuto.' + sLineBreak +
    'Não compartilhe este código com outras pessoas.';

  Result := MessageText(
    AMensagemRetorno,
    AURL,
    AInstancia,
    Numero,
    Mensagem,
    AAPIKey
  );
end;

class function TWhatsAppService.JSONTexto(const Conteudo, Caminho: string): string;
var
  JSON, Valor: TJSONValue;
begin
  Result := '';

  if Trim(Conteudo) = '' then
    Exit;

  JSON := TJSONObject.ParseJSONValue(Conteudo);
  try
    if not Assigned(JSON) then
      Exit;

    Valor := JSON.FindValue(Caminho);

    if not Assigned(Valor) or (Valor is TJSONNull) then
      Exit;

    if Valor is TJSONString then
      Result := Valor.Value
    else
      Result := Valor.ToJSON;
  finally
    JSON.Free;
  end;
end;

class function TWhatsAppService.MensagemResposta(const Resposta: IResponse): string;
begin
  if not Assigned(Resposta) then
    Exit('A Evolution API não retornou uma resposta.');

  Result := JSONTexto(Resposta.Content, 'response.message');

  if Result = '' then
    Result := JSONTexto(Resposta.Content, 'error.message');

  if Result = '' then
    Result := JSONTexto(Resposta.Content, 'message');

  if Result = '' then
    Result := Trim(Resposta.Content);

  if Result = '' then
    Result := Format('HTTP %d sem conteúdo de resposta.', [Resposta.StatusCode]);
end;

class function TWhatsAppService.RespostaSucesso(const Resposta: IResponse): Boolean;
begin
  Result := Assigned(Resposta) and
            (Resposta.StatusCode >= 200) and
            (Resposta.StatusCode < 300);

  if not Result then
    Exit;

  if SameText(JSONTexto(Resposta.Content, 'error'), 'true') then
    Exit(False);

  if SameText(JSONTexto(Resposta.Content, 'success'), 'false') then
    Exit(False);
end;

function TWhatsAppService.RecursoInstancia(const Prefixo, NomeInstancia: string): string;
begin
  if Trim(NomeInstancia) = '' then
    raise EArgumentException.Create('Nome da instância não informado.');

  Result := Prefixo + Trim(NomeInstancia);
end;

function FormatarNumeroWhatsApp(const AValor: string): string;
var
  C: Char;
begin
  Result := '';

  for C in AValor do
    if C in ['0'..'9'] then
      Result := Result + C;

  if Length(Result) in [10, 11] then
    Result := '55' + Result;
end;

class function TWhatsAppService.MessageText(
  out AMsg: string;
  const AURL: string;
  const ANomeInstanciaweb: string;
  const ANumero: string;
  const AMensagem: string;
  const AAPIKEY: string): Boolean;
var
  Resposta   : IResponse;
  Body       : TJSONObject;
  JSON       : TJSONValue;
  Valor      : TJSONValue;
  MessageID  : string;
  NumeroEnvio: string;
begin
  Result := False;
  AMsg := '';
  MessageID := '';
  Body := TJSONObject.Create;
  JSON := nil;

  try
    NumeroEnvio := FormatarNumeroWhatsApp(ANumero);

    if not (Length(NumeroEnvio) in [12, 13]) then
    begin
      AMsg := 'Número inválido: ' + NumeroEnvio;
      Exit;
    end;

    Body.AddPair('number', Trim(NumeroEnvio));
    Body.AddPair('text', AMensagem);

    try
      Resposta := TRequest.New
        .BaseURL(AURL)
        .Resource('message/sendText/' + Trim(ANomeInstanciaweb))
        .Accept('application/json')
        .ContentType('application/json')
        .AddHeader('apikey', AAPIKEY)
        .AddBody(Body.ToJSON, TRESTContentType.ctAPPLICATION_JSON)
        .Timeout(1200)
        .Post;

      Result := Assigned(Resposta) and
                (Resposta.StatusCode >= 200) and
                (Resposta.StatusCode <= 299);

      if not Result then
      begin
        if Assigned(Resposta) then
          AMsg := Format('HTTP %d - %s', [Resposta.StatusCode, Resposta.Content])
        else
          AMsg := 'A Evolution API não retornou uma resposta.';

        Exit;
      end;

      JSON := TJSONObject.ParseJSONValue(Resposta.Content);

      if Assigned(JSON) then
      begin
        Valor := JSON.FindValue('key.id');

        if Assigned(Valor) and not (Valor is TJSONNull) then
          MessageID := Valor.Value;
      end;

      if MessageID <> '' then
        AMsg := 'Mensagem enviada com sucesso. ID: ' + MessageID
      else
        AMsg := 'Mensagem enviada com sucesso.';

    except
      on E: Exception do
      begin
        Result := False;
        AMsg := E.ClassName + ': ' + E.Message;
      end;
    end;

  finally
    JSON.Free;
    Body.Free;
  end;
end;

class function TWhatsAppService.EnviarComprovanteVotacao(
  const AURL: string;
  const AInstancia: string;
  const AAPIKey: string;
  const ANumero: string;
  const ANome: string;
  const AComprovante: string;
  out AMensagemRetorno: string): Boolean;
var
  Numero: string;
  Mensagem: string;
begin
  Numero := SomenteNumeros(ANumero);

  if Numero.IsEmpty then
  begin
    AMensagemRetorno := 'Número de WhatsApp não informado.';
    Exit(False);
  end;

  if Trim(AURL).IsEmpty then
  begin
    AMensagemRetorno := 'URL do WhatsApp não informada.';
    Exit(False);
  end;

  if Trim(AInstancia).IsEmpty then
  begin
    AMensagemRetorno := 'Instância do WhatsApp não informada.';
    Exit(False);
  end;

  if Trim(AAPIKey).IsEmpty then
  begin
    AMensagemRetorno := 'Token do WhatsApp não informado.';
    Exit(False);
  end;

  Mensagem :=
    'Olá, ' + Trim(ANome) + '.' + sLineBreak +
    sLineBreak +
    'Seu voto foi registrado com sucesso.' + sLineBreak +
    sLineBreak +
    'Comprovante:' + sLineBreak +
    '*' + Trim(AComprovante) + '*' + sLineBreak +
    sLineBreak +
    'Guarde este código para eventual conferência.' + sLineBreak +
    sLineBreak +
    'Por segurança e sigilo, este comprovante não identifica a opção escolhida.';

  Result := MessageText(
    AMensagemRetorno,
    AURL,
    AInstancia,
    Numero,
    Mensagem,
    AAPIKey
  );
end;

end.
