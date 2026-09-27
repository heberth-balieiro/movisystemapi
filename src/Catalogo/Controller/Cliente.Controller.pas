unit Cliente.Controller;

interface

type
  TClienteController = class
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
  APP.Classes,
  App.Token,
  Cliente.Model,
  Cliente.Service,
  Assinatura.Service;


function JsonToCliente(const AJson: TJSONObject): TClienteModel;
begin
  Result := TClienteModel.Create;

  Result.TipoPessoa       := TAppClasses.GetJsonString(AJson, 'tipo_pessoa', 'JURIDICA');
  Result.NomeRazao        := TAppClasses.GetJsonString(AJson, 'nome_razao');
  Result.NomeFantasia     := TAppClasses.GetJsonString(AJson, 'nome_fantasia');
  Result.CpfCnpj          := TAppClasses.GetJsonString(AJson, 'cpf_cnpj');
  Result.RgIe             := TAppClasses.GetJsonString(AJson, 'rg_ie');

  Result.Telefone         := TAppClasses.GetJsonString(AJson, 'telefone');
  Result.Whatsapp         := TAppClasses.GetJsonString(AJson, 'whatsapp');
  Result.Email            := TAppClasses.GetJsonString(AJson, 'email');

  Result.Cep              := TAppClasses.GetJsonString(AJson, 'cep');
  Result.Endereco         := TAppClasses.GetJsonString(AJson, 'endereco');
  Result.Numero           := TAppClasses.GetJsonString(AJson, 'numero');
  Result.Complemento      := TAppClasses.GetJsonString(AJson, 'complemento');
  Result.Bairro           := TAppClasses.GetJsonString(AJson, 'bairro');
  Result.Cidade           := TAppClasses.GetJsonString(AJson, 'cidade');
  Result.Uf               := TAppClasses.GetJsonString(AJson, 'uf');

  Result.ResponsavelNome  := TAppClasses.GetJsonString(AJson, 'responsavel_nome');
  Result.ResponsavelCpf   := TAppClasses.GetJsonString(AJson, 'responsavel_cpf');
  Result.ResponsavelTelefone := TAppClasses.GetJsonString(AJson, 'responsavel_telefone');

  Result.AcessoPortal     := TAppClasses.GetJsonString(AJson, 'acesso_portal', 'N');
  Result.Ecommerce        := TAppClasses.GetJsonString(AJson, 'ecommerce', 'S');
  Result.Consignado       := TAppClasses.GetJsonString(AJson, 'consignado', 'N');

  Result.LimiteConsignado := TAppClasses.GetJsonCurrency(AJson, 'limite_consignado', 0);
  Result.DiaFechamento    := TAppClasses.GetJsonInt(AJson, 'dia_fechamento', 0);
  Result.PrazoPagamentoDias := TAppClasses.GetJsonInt(AJson, 'prazo_pagamento_dias', 0);

  Result.Status           := TAppClasses.GetJsonString(AJson, 'status', 'ATIVO');
  Result.Observacao       := TAppClasses.GetJsonString(AJson, 'observacao');

  Result.CriarAcessoPortal  := TAppClasses.GetJsonString(AJson, 'criar_acesso_portal', 'N');
  Result.SenhaPortal        := TAppClasses.GetJsonString(AJson, 'senha_portal');

end;

function ClienteToJson(const ACliente: TClienteModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_cliente', TJSONNumber.Create(ACliente.IdCliente));
  Result.AddPair('id_empresa', TJSONNumber.Create(ACliente.IdEmpresa));

  Result.AddPair('tipo_pessoa', ACliente.TipoPessoa);
  Result.AddPair('nome_razao', ACliente.NomeRazao);
  Result.AddPair('nome_fantasia', ACliente.NomeFantasia);
  Result.AddPair('cpf_cnpj', ACliente.CpfCnpj);
  Result.AddPair('rg_ie', ACliente.RgIe);

  Result.AddPair('telefone', ACliente.Telefone);
  Result.AddPair('whatsapp', ACliente.Whatsapp);
  Result.AddPair('email', ACliente.Email);

  Result.AddPair('cep', ACliente.Cep);
  Result.AddPair('endereco', ACliente.Endereco);
  Result.AddPair('numero', ACliente.Numero);
  Result.AddPair('complemento', ACliente.Complemento);
  Result.AddPair('bairro', ACliente.Bairro);
  Result.AddPair('cidade', ACliente.Cidade);
  Result.AddPair('uf', ACliente.Uf);

  Result.AddPair('responsavel_nome', ACliente.ResponsavelNome);
  Result.AddPair('responsavel_cpf', ACliente.ResponsavelCpf);
  Result.AddPair('responsavel_telefone', ACliente.ResponsavelTelefone);

  Result.AddPair('acesso_portal', ACliente.AcessoPortal);
  Result.AddPair('ecommerce', ACliente.Ecommerce);
  Result.AddPair('consignado', ACliente.Consignado);

  Result.AddPair('limite_consignado', TJSONNumber.Create(ACliente.LimiteConsignado));
  Result.AddPair('dia_fechamento', TJSONNumber.Create(ACliente.DiaFechamento));
  Result.AddPair('prazo_pagamento_dias', TJSONNumber.Create(ACliente.PrazoPagamentoDias));

  Result.AddPair('status', ACliente.Status);
  Result.AddPair('observacao', ACliente.Observacao);

  if ACliente.DataCadastro > 0 then
    Result.AddPair('data_cadastro', FormatDateTime('yyyy-mm-dd hh:nn:ss', ACliente.DataCadastro))
  else
    Result.AddPair('data_cadastro', TJSONNull.Create);

  if ACliente.DataAlteracao > 0 then
    Result.AddPair('data_alteracao', FormatDateTime('yyyy-mm-dd hh:nn:ss', ACliente.DataAlteracao))
  else
    Result.AddPair('data_alteracao', TJSONNull.Create);

  Result.AddPair('criar_acesso_portal', ACliente.CriarAcessoPortal);

end;

class procedure TClienteController.Registry;
begin
  THorse.Get('/v1/clientes',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TClienteModel>;
      Cliente: TClienteModel;
      Arr: TJSONArray;
      Pesquisa: string;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Pesquisa := Req.Query.Items['pesquisa'];

        Lista := TClienteService.ListarClientes(Claims.IdEmpresa, Pesquisa);
        try
          Arr := TJSONArray.Create;

          for Cliente in Lista do
            Arr.AddElement(ClienteToJson(Cliente));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/clientes/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Cliente: TClienteModel;
      IdCliente: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdCliente := StrToInt64Def(Req.Params['id'], 0);

        Cliente := TClienteService.BuscarCliente(Claims.IdEmpresa, IdCliente);
        try
          TAppResponse.Ok(Res, ClienteToJson(Cliente));
        finally
          Cliente.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/v1/clientes',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Cliente: TClienteModel;
      IdCliente: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Json := Req.Body<TJSONObject>;
        Cliente := JsonToCliente(Json);
        try
          IdCliente := TClienteService.CriarCliente(Claims.IdEmpresa, Cliente);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_cliente', TJSONNumber.Create(IdCliente));

          TAppResponse.Created(Res, Retorno, 'Cliente cadastrado com sucesso.');
        finally
          Cliente.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/clientes/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Cliente: TClienteModel;
      IdCliente: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdCliente := StrToInt64Def(Req.Params['id'], 0);

        Json := Req.Body<TJSONObject>;
        Cliente := JsonToCliente(Json);
        try
          TClienteService.AtualizarCliente(Claims.IdEmpresa, IdCliente, Cliente);
          TAppResponse.Ok(Res, TJSONObject.Create, 'Cliente atualizado com sucesso.');
        finally
          Cliente.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/clientes/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdCliente: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdCliente := StrToInt64Def(Req.Params['id'], 0);

        TClienteService.InativarCliente(Claims.IdEmpresa, IdCliente);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Cliente inativado com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/clientes/:id/ativar',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdCliente: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdCliente := StrToInt64Def(Req.Params['id'], 0);

        TClienteService.AtivarCliente(Claims.IdEmpresa, IdCliente);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Cliente ativado com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/clientes/:id/bloquear',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdCliente: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdCliente := StrToInt64Def(Req.Params['id'], 0);

        TClienteService.BloquearCliente(Claims.IdEmpresa, IdCliente);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Cliente bloqueado com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
