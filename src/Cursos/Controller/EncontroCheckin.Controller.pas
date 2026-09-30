unit EncontroCheckin.Controller;

interface

type
  TEncontroCheckinController = class
  public
    class procedure Registry; static;
  end;

implementation

uses Horse, System.SysUtils, System.JSON, App.JWT, App.Token, App.Response,
  APP.Errors, EncontroCheckin.Model, EncontroCheckin.Service;

function InfoJson(const I: TEncontroCheckinInfo): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_turma', TJSONNumber.Create(I.IdTurma));
  Result.AddPair('id_encontro', TJSONNumber.Create(I.IdEncontro));
  Result.AddPair('tipo', I.Tipo);
  Result.AddPair('titulo', I.Titulo);
  Result.AddPair('turma_nome', I.TurmaNome);
  Result.AddPair('aberto', TJSONBool.Create(I.Aberto));
  Result.AddPair('segundos_restantes', TJSONNumber.Create(I.SegundosRestantes));
  Result.AddPair('ja_registrada', TJSONBool.Create(I.JaRegistrada));
  Result.AddPair('situacao', I.Situacao);
  if I.Token <> '' then Result.AddPair('token', I.Token);
  if I.CheckinEm > 0 then
    Result.AddPair('checkin_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', I.CheckinEm));
end;

procedure Admin(Req: THorseRequest; Res: THorseResponse; const Acao: string);
var Claims: TJWTClaims; Info: TEncontroCheckinInfo;
begin
  try
    Res.RawWebResponse.SetCustomHeader('Cache-Control', 'no-store');
    if not TAppToken.ValidarToken(Req, Res, Claims) then Exit;
    Info := TEncontroCheckinService.Administrar(Claims.IdInstituicao,
      Claims.IdUsuarioInstituicao, StrToInt64Def(Req.Params.Items['id_turma'], 0),
      StrToInt64Def(Req.Params.Items['id_encontro'], 0), Acao);
    TAppResponse.Ok(Res, InfoJson(Info), 'Check-in atualizado.');
  except on E: Exception do TAppErrors.HandleException(Res, E); end;
end;

procedure AdminTurma(Req: THorseRequest; Res: THorseResponse; const Acao: string);
var Claims: TJWTClaims; Info: TEncontroCheckinInfo;
begin
  try
    Res.RawWebResponse.SetCustomHeader('Cache-Control', 'no-store');
    if not TAppToken.ValidarToken(Req, Res, Claims) then Exit;
    Info := TEncontroCheckinService.AdministrarTurma(
      Claims.IdInstituicao,
      Claims.IdUsuarioInstituicao,
      StrToInt64Def(Req.Params.Items['id_turma'], 0),
      Acao
    );
    TAppResponse.Ok(Res, InfoJson(Info), 'Check-in da turma atualizado.');
  except on E: Exception do TAppErrors.HandleException(Res, E); end;
end;

procedure Aluno(Req: THorseRequest; Res: THorseResponse; Confirmar: Boolean);
var Claims: TJWTClaims; Body, V: TJSONValue; Token: string; Info: TEncontroCheckinInfo;
begin
  try
    Res.RawWebResponse.SetCustomHeader('Cache-Control', 'no-store');
    if not TAppToken.ValidarToken(Req, Res, Claims) then Exit;
    if Length(Req.Body) > 256 then TAppErrors.RaiseBadRequest('Requisição inválida.');
    Body := TJSONObject.ParseJSONValue(Req.Body);
    try
      if not (Body is TJSONObject) then TAppErrors.RaiseBadRequest('JSON inválido.');
      V := TJSONObject(Body).GetValue('token');
      if not (V is TJSONString) then TAppErrors.RaiseBadRequest('QR não informado.');
      Token := V.Value;
    finally Body.Free; end;
    Info := TEncontroCheckinService.Aluno(Claims.IdInstituicao, Claims.IdUsuarioInstituicao, Token, Confirmar);
    TAppResponse.Ok(Res, InfoJson(Info), 'Check-in consultado ou confirmado com sucesso.');
  except on E: Exception do TAppErrors.HandleException(Res, E); end;
end;

class procedure TEncontroCheckinController.Registry;
const Base = '/v1/certifica/instituicao/turmas/:id_turma/encontros/:id_encontro/checkin';
begin
  THorse.Get(Base, procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin Admin(Req, Res, 'consultar'); end);
  THorse.Post(Base + '/abrir', procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin Admin(Req, Res, 'abrir'); end);
  THorse.Post(Base + '/encerrar', procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin Admin(Req, Res, 'encerrar'); end);
  THorse.Get('/v1/certifica/instituicao/turmas/:id_turma/checkin', procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin AdminTurma(Req, Res, 'consultar'); end);
  THorse.Post('/v1/certifica/instituicao/turmas/:id_turma/checkin/abrir', procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin AdminTurma(Req, Res, 'abrir'); end);
  THorse.Post('/v1/certifica/instituicao/turmas/:id_turma/checkin/encerrar', procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin AdminTurma(Req, Res, 'encerrar'); end);
  THorse.Post('/v1/certifica/aluno/checkin/consultar', procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin Aluno(Req, Res, False); end);
  THorse.Post('/v1/certifica/aluno/checkin/confirmar', procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin Aluno(Req, Res, True); end);
end;
end.
