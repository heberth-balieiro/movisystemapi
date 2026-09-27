unit InstituicaoCursoCategoria.Controller;

interface

type
  TInstituicaoCursoCategoriaController = class
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
  InstituicaoCursoCategoria.Model,
  InstituicaoCursoCategoria.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(
    Req,
    Res,
    AClaims
  ) then
    Exit;

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto de instituição.'
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
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor :=
    AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    Valor.Value;
end;

function CategoriaParaJson(
  const ACategoria: TInstituicaoCursoCategoriaItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(
      ACategoria.Id
    )
  );

  Result.AddPair(
    'nome',
    ACategoria.Nome
  );

  Result.AddPair(
    'descricao',
    ACategoria.Descricao
  );

  Result.AddPair(
    'situacao',
    ACategoria.Situacao
  );

  Result.AddPair(
    'criado_em',
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      ACategoria.CriadoEm
    )
  );

  Result.AddPair(
    'atualizado_em',
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      ACategoria.AtualizadoEm
    )
  );
end;

class procedure TInstituicaoCursoCategoriaController.Registry;
begin

  {$REGION 'Listar Categorias'}

  THorse.Get(
    '/v1/certifica/instituicao/curso-categorias',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoCursoCategoriaLista;
      Categoria: TInstituicaoCursoCategoriaItem;

      Dados: TJSONObject;
      Paginacao: TJSONObject;
      Itens: TJSONArray;

      Busca: string;
      Situacao: string;
      Pagina: Integer;
      PorPagina: Integer;
      TotalPaginas: Integer;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Busca :=
          Trim(
            Req.Query.Items['busca']
          );

        Situacao :=
          Trim(
            Req.Query.Items['situacao']
          );

        Pagina :=
          StrToIntDef(
            Req.Query.Items['page'],
            1
          );

        PorPagina :=
          StrToIntDef(
            Req.Query.Items['page_size'],
            20
          );

        Resultado :=
          TInstituicaoCursoCategoriaService.Listar(
            Claims.IdInstituicao,
            Busca,
            Situacao,
            Pagina,
            PorPagina
          );

        try
          Itens :=
            TJSONArray.Create;

          for Categoria in Resultado.Itens do
          begin
            Itens.AddElement(
              CategoriaParaJson(
                Categoria
              )
            );
          end;

          if Resultado.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas :=
              (
                Resultado.Total +
                Resultado.PorPagina -
                1
              ) div Resultado.PorPagina;

          Paginacao :=
            TJSONObject.Create;

          Paginacao.AddPair(
            'pagina',
            TJSONNumber.Create(
              Resultado.Pagina
            )
          );

          Paginacao.AddPair(
            'por_pagina',
            TJSONNumber.Create(
              Resultado.PorPagina
            )
          );

          Paginacao.AddPair(
            'total',
            TJSONNumber.Create(
              Resultado.Total
            )
          );

          Paginacao.AddPair(
            'total_paginas',
            TJSONNumber.Create(
              TotalPaginas
            )
          );

          Dados :=
            TJSONObject.Create;

          Dados.AddPair(
            'itens',
            Itens
          );

          Dados.AddPair(
            'paginacao',
            Paginacao
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Categorias carregadas com sucesso.'
          );

        finally
          Resultado.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}


  {$REGION 'Buscar Categoria'}

  THorse.Get(
    '/v1/certifica/instituicao/curso-categorias/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCategoria: Int64;
      Categoria: TInstituicaoCursoCategoriaItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdCategoria :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Categoria :=
          TInstituicaoCursoCategoriaService.BuscarPorId(
            Claims.IdInstituicao,
            IdCategoria
          );

        try
          TAppResponse.Ok(
            Res,
            CategoriaParaJson(
              Categoria
            ),
            'Categoria carregada com sucesso.'
          );
        finally
          Categoria.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}


  {$REGION 'Cadastrar Categoria'}

  THorse.Post(
    '/v1/certifica/instituicao/curso-categorias',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Cadastro: TInstituicaoCursoCategoriaCadastro;
      Categoria: TInstituicaoCursoCategoriaItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Cadastro :=
            Default(
              TInstituicaoCursoCategoriaCadastro
            );

          Cadastro.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Cadastro.Descricao :=
            JsonString(
              Body,
              'descricao'
            );

        finally
          Body.Free;
        end;

        Categoria :=
          TInstituicaoCursoCategoriaService.Cadastrar(
            Claims.IdInstituicao,
            Cadastro
          );

        try
          TAppResponse.Ok(
            Res,
            CategoriaParaJson(
              Categoria
            ),
            'Categoria cadastrada com sucesso.'
          );

        finally
          Categoria.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}


  {$REGION 'Atualizar Categoria'}

  THorse.Put(
    '/v1/certifica/instituicao/curso-categorias/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCategoria: Int64;

      JsonValue: TJSONValue;
      Body: TJSONObject;

      Alteracao: TInstituicaoCursoCategoriaAlteracao;
      Categoria: TInstituicaoCursoCategoriaItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdCategoria :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Alteracao :=
            Default(
              TInstituicaoCursoCategoriaAlteracao
            );

          Alteracao.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Alteracao.Descricao :=
            JsonString(
              Body,
              'descricao'
            );

        finally
          Body.Free;
        end;

        Categoria :=
          TInstituicaoCursoCategoriaService.Atualizar(
            Claims.IdInstituicao,
            IdCategoria,
            Alteracao
          );

        try
          TAppResponse.Ok(
            Res,
            CategoriaParaJson(
              Categoria
            ),
            'Categoria atualizada com sucesso.'
          );

        finally
          Categoria.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}


  {$REGION 'Alterar Situação'}

  THorse.Patch(
    '/v1/certifica/instituicao/curso-categorias/:id/situacao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCategoria: Int64;

      JsonValue: TJSONValue;
      Body: TJSONObject;

      Situacao: string;
      Categoria: TInstituicaoCursoCategoriaItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdCategoria :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Situacao :=
            JsonString(
              Body,
              'situacao'
            );

        finally
          Body.Free;
        end;

        Categoria :=
          TInstituicaoCursoCategoriaService.AlterarSituacao(
            Claims.IdInstituicao,
            IdCategoria,
            Situacao
          );

        try
          TAppResponse.Ok(
            Res,
            CategoriaParaJson(
              Categoria
            ),
            'Situação da categoria atualizada com sucesso.'
          );

        finally
          Categoria.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}

end;

end.
