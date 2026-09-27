unit Empresa.Controller;

interface

type
  TEmpresaController = class
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
  Empresa.Model,
  Empresa.Service,
  App.Response,
  APP.Errors,
  App.Classes,
  App.Token;

function EmpresaToJson(const AEmpresa: TEmpresaModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_empresa', TJSONNumber.Create(AEmpresa.IdEmpresa));
  Result.AddPair('nome', AEmpresa.Nome);
  Result.AddPair('cnpj', AEmpresa.Cnpj);
  Result.AddPair('cep', AEmpresa.Cep);
  Result.AddPair('endereco', AEmpresa.Endereco);
  Result.AddPair('numero', AEmpresa.Numero);
  Result.AddPair('complemento', AEmpresa.Complemento);
  Result.AddPair('bairro', AEmpresa.Bairro);
  Result.AddPair('cidade', AEmpresa.Cidade);
  Result.AddPair('uf', AEmpresa.Uf);
  Result.AddPair('whatsapp', AEmpresa.Whatsapp);
  Result.AddPair('email', AEmpresa.Email);
  Result.AddPair('nome_responsavel', AEmpresa.NomeResponsavel);

  if AEmpresa.DataCriacao > 0 then
    Result.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', AEmpresa.DataCriacao))
  else
    Result.AddPair('data_criacao', TJSONNull.Create);

  if AEmpresa.DataValidade > 0 then
    Result.AddPair('data_validade', FormatDateTime('yyyy-mm-dd', AEmpresa.DataValidade))
  else
    Result.AddPair('data_validade', TJSONNull.Create);

  Result.AddPair('ativo', AEmpresa.Ativo);
  Result.AddPair('notificar_pedido_whatsapp', AEmpresa.NotificarPedidoWhatsapp);
  Result.AddPair('notificar_pedido_email', AEmpresa.NotificarPedidoEmail);
  Result.AddPair('resumo_diario', AEmpresa.ResumoDiario);
  Result.AddPair('mensagem_modelo', AEmpresa.MensagemModelo);
  Result.AddPair('idplano', AEmpresa.idplano);

end;

procedure PreencherEmpresaFromJson(const AJson: TJSONObject; const AEmpresa: TEmpresaModel);
begin
  AEmpresa.Nome                           := TAppClasses.GetJsonString(AJson, 'nome');
  AEmpresa.Cnpj                           := TAppClasses.GetJsonString(AJson, 'cnpj');
  AEmpresa.Cep                            := TAppClasses.GetJsonString(AJson, 'cep');
  AEmpresa.Endereco                       := TAppClasses.GetJsonString(AJson, 'endereco');
  AEmpresa.Numero                         := TAppClasses.GetJsonString(AJson, 'numero');
  AEmpresa.Complemento                    := TAppClasses.GetJsonString(AJson, 'complemento');
  AEmpresa.Bairro                         := TAppClasses.GetJsonString(AJson, 'bairro');
  AEmpresa.Cidade                         := TAppClasses.GetJsonString(AJson, 'cidade');
  AEmpresa.Uf                             := TAppClasses.GetJsonString(AJson, 'uf');
  AEmpresa.Whatsapp                       := TAppClasses.GetJsonString(AJson, 'whatsapp');
  AEmpresa.Email                          := TAppClasses.GetJsonString(AJson, 'email');
  AEmpresa.NomeResponsavel                := TAppClasses.GetJsonString(AJson, 'nome_responsavel');
  AEmpresa.DataValidade                   := date;//TAppClasses.GetJsonDate(AJson, 'data_validade');
  AEmpresa.Ativo                          := TAppClasses.GetJsonString(AJson, 'ativo', 'S');
  AEmpresa.NotificarPedidoWhatsapp        := TAppClasses.GetJsonString(AJson, 'notificar_pedido_whatsapp', 'N');
  AEmpresa.NotificarPedidoEmail           := TAppClasses.GetJsonString(AJson, 'notificar_pedido_email', 'N');
  AEmpresa.ResumoDiario                   := TAppClasses.GetJsonString(AJson, 'resumo_diario', 'N');
  AEmpresa.MensagemModelo                 := TAppClasses.GetJsonString(AJson, 'mensagem_modelo');
  AEmpresa.idplano                        := TAppClasses.GetJsonInt(AJson, 'idplano',0);
  AEmpresa.idsegmento                     := TAppClasses.GetJsonInt(AJson, 'idsegmento',0);
end;

class procedure TEmpresaController.Registry;
begin
  //para cadastro de empresa
  THorse.Post('/v1/empresas/cadastro',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body: TJSONObject;
      Empresa: TEmpresaModel;
      Resultado: TCadastroEmpresaResult;
      Retorno: TJSONObject;
      Senha: string;
    begin
      try
        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Empresa := TEmpresaModel.Create;
        try
          PreencherEmpresaFromJson(Body, Empresa);

          Senha := TAppClasses.GetJsonString(Body, 'senha');

          Resultado := TEmpresaService.CadastrarEmpresa(Empresa, Senha);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_empresa', TJSONNumber.Create(Resultado.IdEmpresa));
          Retorno.AddPair('id_usuario', TJSONNumber.Create(Resultado.IdUsuario));

          TAppResponse.Created(Res, Retorno, 'Empresa cadastrada com sucesso.');
        finally
          Empresa.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/admin/empresas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Pesquisa: string;
      Lista: TObjectList<TEmpresaModel>;
      Empresa: TEmpresaModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if not TAppClasses.PossuiPerfil(Claims, 'ADMIN') then
        begin
          TAppResponse.Forbidden(Res, 'Sem permissão para acessar este recurso.');
          Exit;
        end;

        Pesquisa := Req.Query['pesquisa'];

        Lista := TEmpresaService.ListarEmpresas(Pesquisa);
        try
          Arr := TJSONArray.Create;

          for Empresa in Lista do
            Arr.AddElement(EmpresaToJson(Empresa));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/admin/empresas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdEmpresa: Int64;
      Empresa: TEmpresaModel;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if not TAppClasses.PossuiPerfil(Claims, 'ADMIN') then
        begin
          TAppResponse.Forbidden(Res, 'Sem permissão para acessar este recurso.');
          Exit;
        end;

        IdEmpresa := StrToInt64Def(Req.Params['id'], 0);

        Empresa := TEmpresaService.BuscarEmpresa(IdEmpresa);
        try
          TAppResponse.Ok(Res, EmpresaToJson(Empresa));
        finally
          Empresa.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/admin/empresas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdEmpresa: Int64;
      Body: TJSONObject;
      Empresa: TEmpresaModel;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if not TAppClasses.PossuiPerfil(Claims, 'ADMIN') then
        begin
          TAppResponse.Forbidden(Res, 'Sem permissão para acessar este recurso.');
          Exit;
        end;

        IdEmpresa := StrToInt64Def(Req.Params['id'], 0);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Empresa := TEmpresaModel.Create;
        try
          PreencherEmpresaFromJson(Body, Empresa);

          TEmpresaService.AtualizarEmpresa(IdEmpresa, Empresa);

          TAppResponse.Ok(Res, TJSONObject.Create, 'Empresa atualizada com sucesso.');
        finally
          Empresa.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/admin/empresas/:id/ativar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdEmpresa: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if not TAppClasses.PossuiPerfil(Claims, 'ADMIN') then
        begin
          TAppResponse.Forbidden(Res, 'Sem permissão para acessar este recurso.');
          Exit;
        end;

        IdEmpresa := StrToInt64Def(Req.Params['id'], 0);

        TEmpresaService.AtivarEmpresa(IdEmpresa);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Empresa ativada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/admin/empresas/:id/inativar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdEmpresa: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if not TAppClasses.PossuiPerfil(Claims, 'ADMIN') then
        begin
          TAppResponse.Forbidden(Res, 'Sem permissão para acessar este recurso.');
          Exit;
        end;

        IdEmpresa := StrToInt64Def(Req.Params['id'], 0);

        TEmpresaService.InativarEmpresa(IdEmpresa);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Empresa inativada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/admin/empresas/:id/liberar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdEmpresa: Int64;
      Body: TJSONObject;
      DataValidade: TDate;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if not TAppClasses.PossuiPerfil(Claims, 'ADMIN') then
        begin
          TAppResponse.Forbidden(Res, 'Sem permissão para acessar este recurso.');
          Exit;
        end;

        IdEmpresa := StrToInt64Def(Req.Params['id'], 0);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        DataValidade := TAppClasses.GetJsonDate(Body, 'data_validade');

        TEmpresaService.LiberarEmpresa(IdEmpresa, DataValidade);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Empresa liberada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/admin/empresas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdEmpresa: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if not TAppClasses.PossuiPerfil(Claims, 'ADMIN') then
        begin
          TAppResponse.Forbidden(Res, 'Sem permissão para acessar este recurso.');
          Exit;
        end;

        IdEmpresa := StrToInt64Def(Req.Params['id'], 0);

        TEmpresaService.ExcluirEmpresa(IdEmpresa);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Empresa excluída com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
