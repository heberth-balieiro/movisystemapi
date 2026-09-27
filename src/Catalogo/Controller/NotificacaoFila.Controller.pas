unit NotificacaoFila.Controller;

interface

type
  TNotificacaoFilaController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.Config,
  App.JWT,
  App.Response,
  APP.Errors,
  App.Classes,
  app.Token,
  NotificacaoFila.Model,
  NotificacaoFila.Service;


function NotificacaoToJson(const ANotificacao: TNotificacaoFilaModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_notificacao', TJSONNumber.Create(ANotificacao.IdNotificacao));
  Result.AddPair('id_empresa', TJSONNumber.Create(ANotificacao.IdEmpresa));

  if ANotificacao.IdPedido > 0 then
    Result.AddPair('id_pedido', TJSONNumber.Create(ANotificacao.IdPedido))
  else
    Result.AddPair('id_pedido', TJSONNull.Create);

  Result.AddPair('canal', ANotificacao.Canal);
  Result.AddPair('destinatario', ANotificacao.Destinatario);
  Result.AddPair('titulo', ANotificacao.Titulo);
  Result.AddPair('mensagem', ANotificacao.Mensagem);
  Result.AddPair('status', ANotificacao.Status);
  Result.AddPair('tentativas', TJSONNumber.Create(ANotificacao.Tentativas));
  Result.AddPair('ultimo_erro', ANotificacao.UltimoErro);
  Result.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', ANotificacao.DataCriacao));

  if ANotificacao.DataEnvio > 0 then
    Result.AddPair('data_envio', FormatDateTime('yyyy-mm-dd hh:nn:ss', ANotificacao.DataEnvio))
  else
    Result.AddPair('data_envio', TJSONNull.Create);

  if ANotificacao.DataAlteracao > 0 then
    Result.AddPair('data_alteracao', FormatDateTime('yyyy-mm-dd hh:nn:ss', ANotificacao.DataAlteracao))
  else
    Result.AddPair('data_alteracao', TJSONNull.Create);
end;

class procedure TNotificacaoFilaController.Registry;
begin
  // Lista notificações da empresa logada
  THorse.Get('/v1/notificacoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TNotificacaoFilaModel>;
      Notificacao: TNotificacaoFilaModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Lista := TNotificacaoFilaService.ListarPorEmpresa(Claims.IdEmpresa);
        try
          Arr := TJSONArray.Create;

          for Notificacao in Lista do
            Arr.AddElement(NotificacaoToJson(Notificacao));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  // Lista notificações pendentes para serviço externo processar
  THorse.Get('/v1/notificacoes/pendentes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Canal: string;
      Limite: Integer;
      Lista: TObjectList<TNotificacaoFilaModel>;
      Notificacao: TNotificacaoFilaModel;
      Arr: TJSONArray;
    begin
      try
        //if not ValidarToken(Req, Res, Claims) then
        //  Exit;

        Canal := UpperCase(Trim(Req.Query['canal']));
        Limite := StrToIntDef(Req.Query['limite'], 50);

        Lista := TNotificacaoFilaService.ListarPendentes(Canal, Limite);
        try
          Arr := TJSONArray.Create;

          for Notificacao in Lista do
            Arr.AddElement(NotificacaoToJson(Notificacao));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  // Marca notificação como enviada
  THorse.Put('/v1/notificacoes/:id/enviado',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdNotificacao: Int64;
    begin
      try
        //if not ValidarToken(Req, Res, Claims) then
        //  Exit;

        IdNotificacao := StrToInt64Def(Req.Params['id'], 0);

        TNotificacaoFilaService.MarcarEnviado(IdNotificacao);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Notificação marcada como enviada.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  // Marca notificação como erro
  THorse.Put('/v1/notificacoes/:id/erro',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdNotificacao: Int64;
      Body: TJSONObject;
      MensagemErro: string;
    begin
      try
        //if not ValidarToken(Req, Res, Claims) then
        //  Exit;

        IdNotificacao := StrToInt64Def(Req.Params['id'], 0);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        MensagemErro := TAppClasses.GetJsonString(Body, 'erro');

        TNotificacaoFilaService.MarcarErro(IdNotificacao, MensagemErro);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Notificação marcada com erro.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  // Cancela notificação da empresa logada
  THorse.Put('/v1/notificacoes/:id/cancelar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdNotificacao: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdNotificacao := StrToInt64Def(Req.Params['id'], 0);

        TNotificacaoFilaService.Cancelar(Claims.IdEmpresa, IdNotificacao);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Notificação cancelada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
