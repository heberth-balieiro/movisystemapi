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
  InstituicaoParticipanteAcesso.Service,
  InstituicaoPermissao.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  const APermissao: string;
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

  if AClaims.IdUsuarioInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(Res, 'Token sem vínculo de usuário com a instituição.');
    Exit;
  end;

  TInstituicaoPermissaoService.Exigir(
    AClaims.IdInstituicao,
    AClaims.IdUsuarioInstituicao,
    APermissao
  );

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
  Result.AddPair('primeiro_acesso_necessario', TJSONBool.Create(AInfo.PrimeiroAcessoNecessario));
  Result.AddPair('convite_whatsapp_enviado', TJSONBool.Create(AInfo.ConviteWhatsAppEnviado));

  if Trim(AInfo.ConviteMensagem).IsEmpty then
    Result.AddPair('convite_mensagem', TJSONNull.Create)
  else
    Result.AddPair('convite_mensagem', AInfo.ConviteMensagem);

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
        if not AutorizarInstituicao(
          Req,
          Res,
          'participante.visualizar',
          Claims
        ) then
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
      Info: TParticipanteAcessoInfo;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'participante.editar',
          Claims
        ) then
          Exit;

        IdParticipante := StrToInt64Def(Req.Params.Items['id'], 0);

        Info := TInstituicaoParticipanteAcessoService.Liberar(
          Claims.IdInstituicao,
          IdParticipante
        );
        try
          TAppResponse.Ok(
            Res,
            AcessoParaJson(Info),
            'Acesso ao portal liberado com sucesso.'
          );
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
        if not AutorizarInstituicao(
          Req,
          Res,
          'participante.editar',
          Claims
        ) then
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
