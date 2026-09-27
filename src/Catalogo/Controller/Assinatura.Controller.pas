unit Assinatura.Controller;

interface

type
  TAssinaturaController = class
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
  App.Token,
  Assinatura.Model,
  Assinatura.Service;

function DateToJsonValue(const AData: TDateTime): TJSONValue;
begin
  if AData > 0 then
    Result := TJSONString.Create(FormatDateTime('yyyy-mm-dd hh:nn:ss', AData))
  else
    Result := TJSONNull.Create;
end;

function AssinaturaToJson(const AAssinatura: TAssinaturaModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_assinatura', TJSONNumber.Create(AAssinatura.IdAssinatura));
  Result.AddPair('id_empresa', TJSONNumber.Create(AAssinatura.IdEmpresa));
  Result.AddPair('id_plano', TJSONNumber.Create(AAssinatura.IdPlano));
  Result.AddPair('recorrencia', AAssinatura.Recorrencia);
  Result.AddPair('situacao', AAssinatura.Situacao);
  Result.AddPair('iniciado_em', DateToJsonValue(AAssinatura.IniciadoEm));
  Result.AddPair('trial_termina_em', DateToJsonValue(AAssinatura.TrialTerminaEm));
  Result.AddPair('proximo_vencimento', DateToJsonValue(AAssinatura.ProximoVencimento));
  Result.AddPair('cancelado_em', DateToJsonValue(AAssinatura.CanceladoEm));
  Result.AddPair('termina_em', DateToJsonValue(AAssinatura.TerminaEm));
  Result.AddPair('valor', TJSONNumber.Create(AAssinatura.Valor));
  Result.AddPair('observacao', AAssinatura.Observacao);
  Result.AddPair('data_criacao', DateToJsonValue(AAssinatura.DataCriacao));
  Result.AddPair('data_alteracao', DateToJsonValue(AAssinatura.DataAlteracao));
end;

function JsonToAssinatura(const AJson: TJSONObject): TAssinaturaModel;
begin
  Result := TAssinaturaModel.Create;

  Result.IdPlano            := TAppClasses.GetJsonInt(AJson, 'id_plano',0);
  Result.Recorrencia        := TAppClasses.GetJsonString(AJson, 'recorrencia', 'MENSAL');
  Result.Situacao           := TAppClasses.GetJsonString(AJson, 'situacao', 'TRIAL');

  Result.IniciadoEm         := TAppClasses.GetJsonDate(AJson, 'iniciado_em');
  Result.TrialTerminaEm     := TAppClasses.GetJsonDate(AJson, 'trial_termina_em');
  Result.ProximoVencimento  := TAppClasses.GetJsonDate(AJson, 'proximo_vencimento');
  Result.CanceladoEm        := TAppClasses.GetJsonDate(AJson, 'cancelado_em');
  Result.TerminaEm          := TAppClasses.GetJsonDate(AJson, 'termina_em');

  Result.Valor              := TAppClasses.GetJsonCurrency(AJson, 'valor', 0);
  Result.Observacao         := TAppClasses.GetJsonString(AJson, 'observacao');
end;

function BooleanToJson(const AValue: Boolean): TJSONBool;
begin
  Result := TJSONBool.Create(AValue);
end;

function AssinaturaStatusToJson(const AStatus: TAssinaturaStatusResult): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_assinatura',       TJSONNumber.Create(AStatus.IdAssinatura));
  Result.AddPair('id_plano',            TJSONNumber.Create(AStatus.IdPlano));
  Result.AddPair('recorrencia',         AStatus.Recorrencia);
  Result.AddPair('situacao',            AStatus.Situacao);
  Result.AddPair('situacao_atual',      AStatus.SituacaoAtual);
  Result.AddPair('valor',               TJSONNumber.Create(AStatus.Valor));
  Result.AddPair('iniciado_em',         DateToJsonValue(AStatus.IniciadoEm));
  Result.AddPair('trial_termina_em',    DateToJsonValue(AStatus.TrialTerminaEm));
  Result.AddPair('proximo_vencimento',  DateToJsonValue(AStatus.ProximoVencimento));
  Result.AddPair('pode_acessar',        BooleanToJson(AStatus.PodeAcessar));
  Result.AddPair('bloqueado',           BooleanToJson(AStatus.Bloqueado));
  Result.AddPair('em_trial',            BooleanToJson(AStatus.EmTrial));
  Result.AddPair('exibir_alerta',       BooleanToJson(AStatus.ExibirAlerta));
  Result.AddPair('dias_restantes_trial', TJSONNumber.Create(AStatus.DiasRestantesTrial));
  Result.AddPair('dias_para_vencimento', TJSONNumber.Create(AStatus.DiasParaVencimento));
  Result.AddPair('mensagem',            AStatus.Mensagem);
end;


class procedure TAssinaturaController.Registry;
begin
  THorse.Get('/v1/assinaturas',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TAssinaturaModel>;
      Assinatura: TAssinaturaModel;
      Arr: TJSONArray;
      Pesquisa: string;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Pesquisa := Req.Query.Items['pesquisa'];

        Lista := TAssinaturaService.Listar(Claims.IdEmpresa, Pesquisa);
        try
          Arr := TJSONArray.Create;

          for Assinatura in Lista do
            Arr.AddElement(AssinaturaToJson(Assinatura));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/assinaturas/atual',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Assinatura: TAssinaturaModel;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Assinatura := TAssinaturaService.BuscarAtualEmpresa(Claims.IdEmpresa);
        try
          TAppResponse.Ok(Res, AssinaturaToJson(Assinatura));
        finally
          Assinatura.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  // rota processar vencimento
  THorse.Put('/v1/assinaturas/processar-vencimentos',
  procedure(Req: THorseRequest; Res: THorseResponse)
  var
    Claims: TJWTClaims;
    Resultado: TProcessarVencimentosResult;
    Retorno: TJSONObject;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      Resultado := TAssinaturaService.ProcessarVencimentos(Claims.IdEmpresa);

      Retorno := TJSONObject.Create;
      Retorno.AddPair('cobrancas_vencidas',   TJSONNumber.Create(Resultado.CobrancasVencidas));
      Retorno.AddPair('assinaturas_vencidas', TJSONNumber.Create(Resultado.AssinaturasVencidas));
      Retorno.AddPair('trials_vencidos',      TJSONNumber.Create(Resultado.TrialsVencidos));

      TAppResponse.Ok(
        Res,
        Retorno,
        'Processamento de vencimentos realizado com sucesso.'
      );
    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end);

  THorse.Put('/v1/assinaturas/processar-bloqueios',
  procedure(Req: THorseRequest; Res: THorseResponse)
  var
    Claims: TJWTClaims;
    Resultado: TProcessarBloqueiosResult;
    Retorno: TJSONObject;
    Dias: Integer;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      Dias := StrToIntDef(Req.Query.Items['dias'], 3);

      Resultado := TAssinaturaService.ProcessarBloqueios(
        Claims.IdEmpresa,
        Dias
      );

      Retorno := TJSONObject.Create;
      Retorno.AddPair('assinaturas_bloqueadas', TJSONNumber.Create(Resultado.AssinaturasBloqueadas));
      Retorno.AddPair('dias_apos_vencimento',   TJSONNumber.Create(Resultado.DiasAposVencimento));

      TAppResponse.Ok(
        Res,
        Retorno,
        'Processamento de bloqueios realizado com sucesso.'
      );
    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end);

  THorse.Put('/v1/assinaturas/processar-rotina',
  procedure(Req: THorseRequest; Res: THorseResponse)
  var
    Claims: TJWTClaims;
    Resultado: TProcessarRotinaAssinaturaResult;
    Retorno: TJSONObject;
    Dias: Integer;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      Dias := StrToIntDef(Req.Query.Items['dias'], 3);

      Resultado := TAssinaturaService.ProcessarRotinaAssinaturas(
        Claims.IdEmpresa,
        Dias
      );

      Retorno := TJSONObject.Create;
      Retorno.AddPair('cobrancas_vencidas',     TJSONNumber.Create(Resultado.CobrancasVencidas));
      Retorno.AddPair('assinaturas_vencidas',   TJSONNumber.Create(Resultado.AssinaturasVencidas));
      Retorno.AddPair('trials_vencidos',        TJSONNumber.Create(Resultado.TrialsVencidos));
      Retorno.AddPair('assinaturas_bloqueadas', TJSONNumber.Create(Resultado.AssinaturasBloqueadas));
      Retorno.AddPair('dias_apos_vencimento',   TJSONNumber.Create(Resultado.DiasAposVencimento));

      TAppResponse.Ok(
        Res,
        Retorno,
        'Rotina de assinaturas processada com sucesso.'
      );
    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end);

  //Rota publica
  THorse.Put('/v1/admin/assinaturas/processar-rotina',
  procedure(Req: THorseRequest; Res: THorseResponse)
  var
    Claims: TJWTClaims;
    Resultado: TProcessarRotinaGlobalAssinaturaResult;
    Retorno: TJSONObject;
    Dias: Integer;
  begin
    try
//      if not ValidarToken(Req, Res, Claims) then
//        Exit;
//
//      if not SameText(Claims.Perfil, 'ADMIN') then
//        TAppErrors.RaiseUnauthorized('Acesso permitido somente para administrador.');

      Dias := StrToIntDef(Req.Query.Items['dias'], 3);

      Resultado := TAssinaturaService.ProcessarRotinaAssinaturasGlobal(Dias);

      Retorno := TJSONObject.Create;
      Retorno.AddPair('empresas_processadas',   TJSONNumber.Create(Resultado.EmpresasProcessadas));
      Retorno.AddPair('cobrancas_vencidas',     TJSONNumber.Create(Resultado.CobrancasVencidas));
      Retorno.AddPair('assinaturas_vencidas',   TJSONNumber.Create(Resultado.AssinaturasVencidas));
      Retorno.AddPair('trials_vencidos',        TJSONNumber.Create(Resultado.TrialsVencidos));
      Retorno.AddPair('assinaturas_bloqueadas', TJSONNumber.Create(Resultado.AssinaturasBloqueadas));
      Retorno.AddPair('dias_apos_vencimento',   TJSONNumber.Create(Resultado.DiasAposVencimento));

      TAppResponse.Ok(
        Res,
        Retorno,
        'Rotina geral de assinaturas processada com sucesso.'
      );
    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end);

  THorse.Get('/v1/assinaturas/status',
  procedure(Req: THorseRequest; Res: THorseResponse)
  var
    Claims: TJWTClaims;
    Status: TAssinaturaStatusResult;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      Status := TAssinaturaService.ConsultarStatus(Claims.IdEmpresa);

      TAppResponse.Ok(
        Res,
        AssinaturaStatusToJson(Status)
      );
    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end);



  THorse.Get('/v1/assinaturas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Assinatura: TAssinaturaModel;
      IdAssinatura: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdAssinatura := StrToInt64Def(Req.Params['id'], 0);

        Assinatura := TAssinaturaService.Buscar(Claims.IdEmpresa, IdAssinatura);
        try
          TAppResponse.Ok(Res, AssinaturaToJson(Assinatura));
        finally
          Assinatura.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/v1/assinaturas',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Assinatura: TAssinaturaModel;
      IdAssinatura: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Json := Req.Body<TJSONObject>;
        Assinatura := JsonToAssinatura(Json);
        try
          IdAssinatura := TAssinaturaService.Inserir(Claims.IdEmpresa, Assinatura);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_assinatura', TJSONNumber.Create(IdAssinatura));

          TAppResponse.Created(Res, Retorno, 'Assinatura cadastrada com sucesso.');
        finally
          Assinatura.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  //rota para contrato
  THorse.Put('/v1/assinaturas/:id/contratar',
  procedure(Req: THorseRequest; Res: THorseResponse)
  var
    Claims: TJWTClaims;
    IdAssinatura: Int64;
    IdCobranca: Int64;
    Retorno: TJSONObject;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;
      IdAssinatura := StrToInt64Def(Req.Params['id'], 0);
      IdCobranca := TAssinaturaService.ConfirmarContratacao(Claims.IdEmpresa, IdAssinatura);
      Retorno := TJSONObject.Create;
      Retorno.AddPair('id_assinatura',  TJSONNumber.Create(IdAssinatura));
      Retorno.AddPair('id_cobranca',    TJSONNumber.Create(IdCobranca));
      TAppResponse.Ok(
        Res,
        Retorno,
        'Assinatura ativada e cobrança gerada com sucesso.'
      );
    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end);

  THorse.Put('/v1/assinaturas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Assinatura: TAssinaturaModel;
      IdAssinatura: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdAssinatura := StrToInt64Def(Req.Params['id'], 0);

        Json := Req.Body<TJSONObject>;
        Assinatura := JsonToAssinatura(Json);
        try
          TAssinaturaService.Atualizar(Claims.IdEmpresa, IdAssinatura, Assinatura);
          TAppResponse.Ok(Res, TJSONObject.Create, 'Assinatura atualizada com sucesso.');
        finally
          Assinatura.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/assinaturas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdAssinatura: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdAssinatura := StrToInt64Def(Req.Params['id'], 0);

        TAssinaturaService.Excluir(Claims.IdEmpresa, IdAssinatura);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Assinatura excluída com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/assinaturas/:id/cancelar',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdAssinatura: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdAssinatura := StrToInt64Def(Req.Params['id'], 0);

        TAssinaturaService.Cancelar(Claims.IdEmpresa, IdAssinatura);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Assinatura cancelada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/assinaturas/:id/bloquear',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdAssinatura: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdAssinatura := StrToInt64Def(Req.Params['id'], 0);

        TAssinaturaService.Bloquear(Claims.IdEmpresa, IdAssinatura);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Assinatura bloqueada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/assinaturas/:id/ativar',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdAssinatura: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdAssinatura := StrToInt64Def(Req.Params['id'], 0);

        TAssinaturaService.Ativar(Claims.IdEmpresa, IdAssinatura);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Assinatura ativada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
