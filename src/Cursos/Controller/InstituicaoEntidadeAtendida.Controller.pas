unit InstituicaoEntidadeAtendida.Controller;

interface

type
  TInstituicaoEntidadeAtendidaController = class
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
  InstituicaoEntidadeAtendida.Model,
  InstituicaoEntidadeAtendida.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if (AClaims.IdInstituicao <= 0) or
     (AClaims.IdUsuarioInstituicao <= 0) then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto válido da instituição.'
    );
    Exit;
  end;

  Result := True;
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: string = ''
): string;
var
  V: TJSONValue;
begin
  Result := ADefault;
  V := AObj.GetValue(ANome);

  if (V = nil) or (V is TJSONNull) then
    Exit;

  Result := V.Value;
end;

function ItemParaJson(
  const AItem: TInstituicaoEntidadeAtendidaItem
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  Result.AddPair('nome', AItem.Nome);

  if AItem.NomeFantasia.IsEmpty then
    Result.AddPair('nome_fantasia', TJSONNull.Create)
  else
    Result.AddPair('nome_fantasia', AItem.NomeFantasia);

  Result.AddPair('tipo', AItem.Tipo);

  if AItem.Documento.IsEmpty then
    Result.AddPair('documento', TJSONNull.Create)
  else
    Result.AddPair('documento', AItem.Documento);

  Result.AddPair('situacao', AItem.Situacao);

  if AItem.Observacao.IsEmpty then
    Result.AddPair('observacao', TJSONNull.Create)
  else
    Result.AddPair('observacao', AItem.Observacao);

  Result.AddPair(
    'criado_em',
    FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AItem.CriadoEm)
  );

  Result.AddPair(
    'atualizado_em',
    FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AItem.AtualizadoEm)
  );
end;

procedure LerCadastro(
  const ABody: TJSONObject;
  out ADados: TInstituicaoEntidadeAtendidaCadastro
);
begin
  ADados := Default(TInstituicaoEntidadeAtendidaCadastro);
  ADados.Nome := JsonString(ABody, 'nome');
  ADados.NomeFantasia := JsonString(ABody, 'nome_fantasia');
  ADados.Tipo := JsonString(ABody, 'tipo', 'EMPRESA');
  ADados.Documento := JsonString(ABody, 'documento');
  ADados.Situacao := JsonString(ABody, 'situacao', 'ATIVO');
  ADados.Observacao := JsonString(ABody, 'observacao');
end;

class procedure TInstituicaoEntidadeAtendidaController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/entidades-atendidas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TInstituicaoEntidadeAtendidaLista;
      Item: TInstituicaoEntidadeAtendidaItem;
      Dados, Paginacao: TJSONObject;
      Itens: TJSONArray;
      TotalPaginas: Integer;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');

      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Lista := TInstituicaoEntidadeAtendidaService.Listar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Req.Query.Items['busca'],
          Req.Query.Items['tipo'],
          Req.Query.Items['situacao'],
          StrToIntDef(Req.Query.Items['page'], 1),
          StrToIntDef(Req.Query.Items['page_size'], 20)
        );

        try
          Itens := TJSONArray.Create;
          for Item in Lista.Itens do
            Itens.AddElement(ItemParaJson(Item));

          if Lista.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas :=
              (Lista.Total + Lista.PorPagina - 1) div Lista.PorPagina;

          Paginacao := TJSONObject.Create;
          Paginacao.AddPair('pagina', TJSONNumber.Create(Lista.Pagina));
          Paginacao.AddPair('por_pagina', TJSONNumber.Create(Lista.PorPagina));
          Paginacao.AddPair('total', TJSONNumber.Create(Lista.Total));
          Paginacao.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', Itens);
          Dados.AddPair('paginacao', Paginacao);

          TAppResponse.Ok(
            Res,
            Dados,
            'Clientes/entidades carregados com sucesso.'
          );
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/entidades-atendidas/opcoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TInstituicaoEntidadeAtendidaLista;
      Item: TInstituicaoEntidadeAtendidaItem;
      Dados: TJSONObject;
      Itens: TJSONArray;
      Obj: TJSONObject;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');

      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Lista := TInstituicaoEntidadeAtendidaService.ListarOpcoes(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao
        );

        try
          Itens := TJSONArray.Create;

          for Item in Lista.Itens do
          begin
            Obj := TJSONObject.Create;
            Obj.AddPair('id', TJSONNumber.Create(Item.Id));
            Obj.AddPair('nome', Item.Nome);
            Obj.AddPair('nome_fantasia', Item.NomeFantasia);
            Obj.AddPair('tipo', Item.Tipo);
            Itens.AddElement(Obj);
          end;

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', Itens);

          TAppResponse.Ok(
            Res,
            Dados,
            'Opções de clientes/entidades carregadas com sucesso.'
          );
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/entidades-atendidas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TInstituicaoEntidadeAtendidaItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Item := TInstituicaoEntidadeAtendidaService.BuscarPorId(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0)
        );

        try
          TAppResponse.Ok(
            Res,
            ItemParaJson(Item),
            'Cliente/entidade carregado com sucesso.'
          );
        finally
          Item.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/instituicao/entidades-atendidas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoEntidadeAtendidaCadastro;
      Item: TInstituicaoEntidadeAtendidaItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          LerCadastro(Body, Dados);
        finally
          Body.Free;
        end;

        Item := TInstituicaoEntidadeAtendidaService.Cadastrar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Dados
        );

        try
          TAppResponse.Ok(
            Res,
            ItemParaJson(Item),
            'Cliente/entidade cadastrado com sucesso.'
          );
        finally
          Item.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/certifica/instituicao/entidades-atendidas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoEntidadeAtendidaCadastro;
      Item: TInstituicaoEntidadeAtendidaItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          LerCadastro(Body, Dados);
        finally
          Body.Free;
        end;

        Item := TInstituicaoEntidadeAtendidaService.Atualizar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0),
          Dados
        );

        try
          TAppResponse.Ok(
            Res,
            ItemParaJson(Item),
            'Cliente/entidade atualizado com sucesso.'
          );
        finally
          Item.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Patch(
    '/v1/certifica/instituicao/entidades-atendidas/:id/situacao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao: string;
      Item: TInstituicaoEntidadeAtendidaItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Situacao := JsonString(Body, 'situacao');
        finally
          Body.Free;
        end;

        Item := TInstituicaoEntidadeAtendidaService.AlterarSituacao(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0),
          Situacao
        );

        try
          TAppResponse.Ok(
            Res,
            ItemParaJson(Item),
            'Situação do cliente/entidade atualizada com sucesso.'
          );
        finally
          Item.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
