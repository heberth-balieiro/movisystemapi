unit InstituicaoParticipanteAcesso.Controller;

interface

type
  TInstituicaoParticipanteAcessoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  InstituicaoParticipanteAcesso.Model,
  InstituicaoParticipanteAcesso.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(Res, 'Token sem contexto de instituição.');
    Exit;
  end;

  Result := True;
end;

function AcessoParaJson(
  const AInfo: TParticipanteAcessoInfo
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_participante', TJSONNumber.Create(AInfo.IdParticipante));
  Result.AddPair('nome', AInfo.Nome);
  Result.AddPair('email', AInfo.Email);
  Result.AddPair('acesso_liberado', TJSONBool.Create(AInfo.AcessoLiberado));

  if AInfo.AcessoLiberado then
  begin
    Result.AddPair('id_usuario', TJSONNumber.Create(AInfo.IdUsuario));
    Result.AddPair('id_usuario_instituicao', TJSONNumber.Create(AInfo.IdUsuarioInstituicao));
    Result.AddPair('situacao_usuario', AInfo.SituacaoUsuario);
    Result.AddPair('situacao_vinculo', AInfo.SituacaoVinculo);
  end
  else
  begin
    Result.AddPair('id_usuario', TJSONNull.Create);
    Result.AddPair('id_usuario_instituicao', TJSONNull.Create);
    Result.AddPair('situacao_usuario', TJSONNull.Create);
    Result.AddPair('situacao_vinculo', TJSONNull.Create);
  end;
end;

class procedure TInstituicaoParticipanteAcessoController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/participantes/:id/acesso',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdParticipante: Int64;
      Info: TParticipanteAcessoInfo;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdParticipante := StrToInt64Def(Req.Params.Items['id'], 0);

        Info := TInstituicaoParticipanteAcessoService.Consultar(
          Claims.IdInstituicao,
          IdParticipante
        );
        try
          TAppResponse.Ok(Res, AcessoParaJson(Info), 'Acesso do participante carregado com sucesso.');
        finally
          Info.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/instituicao/participantes/:id/acesso',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdParticipante: Int64;
      BodyValue: TJSONValue;
      Body: TJSONObject;
      SenhaInicial: string;
      Info: TParticipanteAcessoInfo;
      V: TJSONValue;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdParticipante := StrToInt64Def(Req.Params.Items['id'], 0);
        SenhaInicial := '';

        if not Trim(Req.Body).IsEmpty then
        begin
          BodyValue := TJSONObject.ParseJSONValue(Req.Body);
          if not (BodyValue is TJSONObject) then
          begin
            BodyValue.Free;
            TAppErrors.RaiseBadRequest('JSON inválido.');
          end;

          Body := BodyValue as TJSONObject;
          try
            V := Body.GetValue('senha_inicial');
            if (V <> nil) and not (V is TJSONNull) then
              SenhaInicial := V.Value;
          finally
            Body.Free;
          end;
        end;

        Info := TInstituicaoParticipanteAcessoService.Liberar(
          Claims.IdInstituicao,
          IdParticipante,
          SenhaInicial
        );
        try
          TAppResponse.Ok(Res, AcessoParaJson(Info), 'Acesso ao portal liberado com sucesso.');
        finally
          Info.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Delete(
    '/v1/certifica/instituicao/participantes/:id/acesso',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdParticipante: Int64;
      Info: TParticipanteAcessoInfo;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdParticipante := StrToInt64Def(Req.Params.Items['id'], 0);

        Info := TInstituicaoParticipanteAcessoService.Revogar(
          Claims.IdInstituicao,
          IdParticipante
        );
        try
          TAppResponse.Ok(Res, AcessoParaJson(Info), 'Acesso ao portal revogado com sucesso.');
        finally
          Info.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
