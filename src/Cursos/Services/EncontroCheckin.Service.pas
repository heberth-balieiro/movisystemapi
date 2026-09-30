unit EncontroCheckin.Service;

interface

uses EncontroCheckin.Model;

type
  TEncontroCheckinService = class
  public
    class function Administrar(Tenant, Usuario, Turma, Encontro: Int64;
      const Acao: string): TEncontroCheckinInfo; static;
    class function Aluno(Tenant, Usuario: Int64; const Token: string;
      Confirmar: Boolean): TEncontroCheckinInfo; static;
    class function AdministrarTurma(Tenant, Usuario, Turma: Int64;
      const Acao: string): TEncontroCheckinInfo; static;
  end;

implementation

uses System.SysUtils, System.Classes, System.Hash, Uni, App.Config,
  Database.Connection, APP.Errors, InstituicaoPermissao.Service,
  AlunoPortal.DAO, AlunoPortal.Model, EncontroCheckin.DAO;

{$IFDEF MSWINDOWS}
function BCryptGenRandom(Algorithm: Pointer; Buffer: PByte; Size, Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll' name 'BCryptGenRandom';
{$ENDIF}

function NovoToken: string;
var Bytes: TBytes; B: Byte;
{$IFNDEF MSWINDOWS}
  Stream: TFileStream;
{$ENDIF}
begin
  SetLength(Bytes, 32);
  {$IFDEF MSWINDOWS}
  if BCryptGenRandom(nil, @Bytes[0], Length(Bytes), 2) <> 0 then
    raise Exception.Create('Falha ao gerar token seguro.');
  {$ELSE}
  Stream := TFileStream.Create('/dev/urandom', fmOpenRead or fmShareDenyNone);
  try Stream.ReadBuffer(Bytes[0], Length(Bytes)); finally Stream.Free; end;
  {$ENDIF}
  Result := '';
  for B in Bytes do Result := Result + LowerCase(IntToHex(B, 2));
end;

function NovaConexao: TUniConnection;
var Config: TAppApiConfig;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Result := TDatabaseConnection.NewConnection(Config.Database);
end;

class function TEncontroCheckinService.Administrar(Tenant, Usuario, Turma,
  Encontro: Int64; const Acao: string): TEncontroCheckinInfo;
var C: TUniConnection; Token, Hash: string;
begin
  if (Turma <= 0) or (Encontro <= 0) then TAppErrors.RaiseBadRequest('Turma/encontro inválido.');
  TInstituicaoPermissaoService.Exigir(Tenant, Usuario, 'presenca.editar');
  if (Acao <> 'consultar') and (Acao <> 'abrir') and (Acao <> 'encerrar') then
    TAppErrors.RaiseBadRequest('Operação inválida.');
  Token := '';
  Hash := '';
  if Acao = 'abrir' then
  begin
    Token := NovoToken;
    Hash := LowerCase(THashSHA2.GetHashString(Token));
  end;
  C := NovaConexao;
  try
    C.StartTransaction;
    try
      Result := TEncontroCheckinDAO.Administrar(C, Tenant, Usuario, Turma, Encontro, Acao, Hash);
      C.Commit;
      Result.Token := Token;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
  finally C.Free; end;
end;

class function TEncontroCheckinService.AdministrarTurma(Tenant, Usuario, Turma: Int64;
  const Acao: string): TEncontroCheckinInfo;
var C: TUniConnection; Token, Hash: string;
begin
  if Turma <= 0 then TAppErrors.RaiseBadRequest('Turma inválida.');
  TInstituicaoPermissaoService.Exigir(Tenant, Usuario, 'presenca.editar');
  if (Acao <> 'consultar') and (Acao <> 'abrir') and (Acao <> 'encerrar') then
    TAppErrors.RaiseBadRequest('Operação inválida.');
  Token := '';
  Hash := '';
  if Acao = 'abrir' then
  begin
    Token := NovoToken;
    Hash := LowerCase(THashSHA2.GetHashString(Token));
  end;
  C := NovaConexao;
  try
    C.StartTransaction;
    try
      Result := TEncontroCheckinDAO.AdministrarTurma(C, Tenant, Usuario, Turma, Acao, Hash);
      C.Commit;
      Result.Token := Token;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
  finally C.Free; end;
end;

class function TEncontroCheckinService.Aluno(Tenant, Usuario: Int64;
  const Token: string; Confirmar: Boolean): TEncontroCheckinInfo;
var C: TUniConnection; Contexto: TAlunoContexto; Ch: Char;
begin
  if (Tenant <= 0) or (Usuario <= 0) then TAppErrors.RaiseUnauthorized('Autenticação necessária.');
  if Length(Token) <> 64 then TAppErrors.RaiseBadRequest('QR inválido.');
  for Ch in Token do
    if not CharInSet(Ch, ['0'..'9','a'..'f']) then TAppErrors.RaiseBadRequest('QR inválido.');
  C := NovaConexao;
  try
    C.StartTransaction;
    try
      Contexto := TAlunoPortalDAO.BuscarContexto(C, Tenant, Usuario);
      try
        if Contexto = nil then TAppErrors.RaiseForbidden('Participante ativo não vinculado ao usuário.');
        if TEncontroCheckinDAO.TokenTurmaExiste(
          C,
          Tenant,
          LowerCase(THashSHA2.GetHashString(Token))
        ) then
        begin
          Result := TEncontroCheckinDAO.ConsultarTurma(
            C,
            Tenant,
            Contexto.IdParticipante,
            LowerCase(THashSHA2.GetHashString(Token))
          );
          if Confirmar then
            TEncontroCheckinDAO.ConfirmarTurma(C, Tenant, Usuario, Result);
        end
        else
        begin
          Result := TEncontroCheckinDAO.Consultar(
            C,
            Tenant,
            Contexto.IdParticipante,
            LowerCase(THashSHA2.GetHashString(Token))
          );
          if Confirmar then
            TEncontroCheckinDAO.Confirmar(C, Tenant, Usuario, Result);
        end;
      finally Contexto.Free; end;
      C.Commit;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
  finally C.Free; end;
end;
end.
