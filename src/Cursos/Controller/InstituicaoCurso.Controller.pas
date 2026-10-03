unit InstituicaoCurso.Controller;

interface

type
  TInstituicaoCursoController = class
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
  InstituicaoCurso.Model,
  InstituicaoCurso.Service;

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
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result := Valor.Value;
end;

function JsonInt64(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Int64 = 0
): Int64;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result := StrToInt64Def(
    Valor.Value,
    ADefault
  );
end;

function JsonInteger(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Integer = 0
): Integer;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result := StrToIntDef(
    Valor.Value,
    ADefault
  );
end;

function JsonBoolean(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Boolean = False
): Boolean;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result := SameText(
    Valor.Value,
    'true'
  );
end;

function CursoParaJson(
  const ACurso: TInstituicaoCursoItem
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(ACurso.Id)
  );

  if ACurso.IdCategoria > 0 then
    Result.AddPair(
      'id_categoria',
      TJSONNumber.Create(ACurso.IdCategoria)
    )
  else
    Result.AddPair(
      'id_categoria',
      TJSONNull.Create
    );

  if ACurso.TemEntidadeAtendida then
  begin
    Result.AddPair(
      'id_entidade_atendida',
      TJSONNumber.Create(ACurso.IdEntidadeAtendida)
    );
    Result.AddPair(
      'entidade_atendida_nome',
      ACurso.EntidadeAtendidaNome
    );
  end
  else
  begin
    Result.AddPair('id_entidade_atendida', TJSONNull.Create);
    Result.AddPair('entidade_atendida_nome', TJSONNull.Create);
  end;

  Result.AddPair(
    'codigo_publico',
    ACurso.CodigoPublico
  );

  if not ACurso.CodigoInterno.IsEmpty then
    Result.AddPair('codigo_interno', ACurso.CodigoInterno)
  else
    Result.AddPair('codigo_interno', TJSONNull.Create);

  if not ACurso.Slug.IsEmpty then
    Result.AddPair('slug', ACurso.Slug)
  else
    Result.AddPair('slug', TJSONNull.Create);

  Result.AddPair(
    'nome',
    ACurso.Nome
  );

  if not ACurso.Descricao.IsEmpty then
    Result.AddPair('descricao', ACurso.Descricao)
  else
    Result.AddPair('descricao', TJSONNull.Create);

  if not ACurso.Objetivo.IsEmpty then
    Result.AddPair('objetivo', ACurso.Objetivo)
  else
    Result.AddPair('objetivo', TJSONNull.Create);

  if not ACurso.ConteudoProgramatico.IsEmpty then
    Result.AddPair('conteudo_programatico', ACurso.ConteudoProgramatico)
  else
    Result.AddPair('conteudo_programatico', TJSONNull.Create);

  Result.AddPair(
    'carga_horaria_minutos',
    TJSONNumber.Create(ACurso.CargaHorariaMinutos)
  );

  Result.AddPair(
    'carga_horaria_horas',
    TJSONNumber.Create(ACurso.CargaHorariaMinutos / 60.0)
  );

  Result.AddPair(
    'modalidade',
    ACurso.Modalidade
  );

  if not ACurso.ImagemUrl.IsEmpty then
    Result.AddPair('imagem_url', ACurso.ImagemUrl)
  else
    Result.AddPair('imagem_url', TJSONNull.Create);

  Result.AddPair(
    'permitir_inscricao_publica',
    TJSONBool.Create(ACurso.PermitirInscricaoPublica)
  );

  Result.AddPair(
    'situacao',
    ACurso.Situacao
  );
end;

class procedure TInstituicaoCursoController.Registry;
begin
  {$REGION 'Listar Cursos'}

  THorse.Get(
    '/v1/certifica/instituicao/cursos',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoCursoLista;
      Item: TInstituicaoCursoItem;
      Dados: TJSONObject;
      ItemJson: TJSONObject;
      PaginacaoJson: TJSONObject;
      ItensJson: TJSONArray;
      Busca: string;
      Situacao: string;
      Modalidade: string;
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

        Busca := Trim(Req.Query.Items['busca']);
        Situacao := Trim(Req.Query.Items['situacao']);
        Modalidade := Trim(Req.Query.Items['modalidade']);
        Pagina := StrToIntDef(Req.Query.Items['page'], 1);
        PorPagina := StrToIntDef(Req.Query.Items['page_size'], 20);

        Resultado := TInstituicaoCursoService.Listar(
          Claims.IdInstituicao,
          Busca,
          Situacao,
          Modalidade,
          Pagina,
          PorPagina
        );

        try
          ItensJson := TJSONArray.Create;

          for Item in Resultado.Itens do
          begin
            ItemJson := TJSONObject.Create;

            ItemJson.AddPair(
              'id',
              TJSONNumber.Create(Item.Id)
            );

            if Item.IdCategoria > 0 then
              ItemJson.AddPair(
                'id_categoria',
                TJSONNumber.Create(Item.IdCategoria)
              )
            else
              ItemJson.AddPair(
                'id_categoria',
                TJSONNull.Create
              );

            if Item.TemEntidadeAtendida then
            begin
              ItemJson.AddPair('id_entidade_atendida', TJSONNumber.Create(Item.IdEntidadeAtendida));
              ItemJson.AddPair('entidade_atendida_nome', Item.EntidadeAtendidaNome);
            end
            else
            begin
              ItemJson.AddPair('id_entidade_atendida', TJSONNull.Create);
              ItemJson.AddPair('entidade_atendida_nome', TJSONNull.Create);
            end;

            ItemJson.AddPair('codigo_publico', Item.CodigoPublico);
            ItemJson.AddPair('codigo_interno', Item.CodigoInterno);
            ItemJson.AddPair('slug', Item.Slug);
            ItemJson.AddPair('nome', Item.Nome);

            ItemJson.AddPair(
              'carga_horaria_minutos',
              TJSONNumber.Create(Item.CargaHorariaMinutos)
            );

            ItemJson.AddPair(
              'carga_horaria_horas',
              TJSONNumber.Create(Item.CargaHorariaMinutos / 60.0)
            );

            ItemJson.AddPair('modalidade', Item.Modalidade);

            ItemJson.AddPair(
              'permitir_inscricao_publica',
              TJSONBool.Create(Item.PermitirInscricaoPublica)
            );

            ItemJson.AddPair('situacao', Item.Situacao);
            ItensJson.AddElement(ItemJson);
          end;

          if Resultado.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas :=
              (Resultado.Total + Resultado.PorPagina - 1) div
              Resultado.PorPagina;

          PaginacaoJson := TJSONObject.Create;
          PaginacaoJson.AddPair('pagina', TJSONNumber.Create(Resultado.Pagina));
          PaginacaoJson.AddPair('por_pagina', TJSONNumber.Create(Resultado.PorPagina));
          PaginacaoJson.AddPair('total', TJSONNumber.Create(Resultado.Total));
          PaginacaoJson.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', ItensJson);
          Dados.AddPair('paginacao', PaginacaoJson);

          TAppResponse.Ok(
            Res,
            Dados,
            'Cursos carregados com sucesso.'
          );
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  {$ENDREGION}

  {$REGION 'Buscar Curso'}

  THorse.Get(
    '/v1/certifica/instituicao/cursos/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCurso: Int64;
      Curso: TInstituicaoCursoItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdCurso := StrToInt64Def(
          Req.Params.Items['id'],
          0
        );

        Curso := TInstituicaoCursoService.BuscarPorId(
          Claims.IdInstituicao,
          IdCurso
        );

        try
          TAppResponse.Ok(
            Res,
            CursoParaJson(Curso),
            'Curso carregado com sucesso.'
          );
        finally
          Curso.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  {$ENDREGION}

  {$REGION 'Cadastrar Curso'}

  THorse.Post(
    '/v1/certifica/instituicao/cursos',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Cadastro: TInstituicaoCursoCadastro;
      Curso: TInstituicaoCursoItem;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        JsonValue := TJSONObject.ParseJSONValue(
          Req.Body
        );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body := JsonValue as TJSONObject;

        try
          Cadastro := Default(TInstituicaoCursoCadastro);

          Cadastro.IdCategoria := JsonInt64(
            Body,
            'id_categoria'
          );

          Cadastro.IdEntidadeAtendida := JsonInt64(
            Body,
            'id_entidade_atendida'
          );

          Cadastro.CodigoInterno := JsonString(
            Body,
            'codigo_interno'
          );

          Cadastro.Slug := JsonString(
            Body,
            'slug'
          );

          Cadastro.Nome := JsonString(
            Body,
            'nome'
          );

          Cadastro.Descricao := JsonString(
            Body,
            'descricao'
          );

          Cadastro.Objetivo := JsonString(
            Body,
            'objetivo'
          );

          Cadastro.ConteudoProgramatico := JsonString(
            Body,
            'conteudo_programatico'
          );

          Cadastro.CargaHorariaMinutos := JsonInteger(
            Body,
            'carga_horaria_minutos'
          );

          Cadastro.Modalidade := JsonString(
            Body,
            'modalidade'
          );

          Cadastro.ImagemUrl := JsonString(
            Body,
            'imagem_url'
          );

          Cadastro.PermitirInscricaoPublica := JsonBoolean(
            Body,
            'permitir_inscricao_publica',
            False
          );

          Cadastro.Situacao := JsonString(
            Body,
            'situacao',
            'RASCUNHO'
          );
        finally
          Body.Free;
        end;

        Curso := TInstituicaoCursoService.Cadastrar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Cadastro
        );

        try
          Dados := CursoParaJson(Curso);

          TAppResponse.Ok(
            Res,
            Dados,
            'Curso cadastrado com sucesso.'
          );
        finally
          Curso.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  {$ENDREGION}

  {$REGION 'Atualizar Curso'}

  THorse.Put(
    '/v1/certifica/instituicao/cursos/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCurso: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Alteracao: TInstituicaoCursoAlteracao;
      Curso: TInstituicaoCursoItem;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        IdCurso := StrToInt64Def(
          Req.Params.Items['id'],
          0
        );

        if IdCurso <= 0 then
          TAppErrors.RaiseBadRequest(
            'Curso inválido.'
          );

        JsonValue := TJSONObject.ParseJSONValue(
          Req.Body
        );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body := JsonValue as TJSONObject;

        try
          Alteracao := Default(
            TInstituicaoCursoAlteracao
          );

          Alteracao.IdCategoria := JsonInt64(
            Body,
            'id_categoria'
          );

          Alteracao.IdEntidadeAtendida := JsonInt64(
            Body,
            'id_entidade_atendida'
          );

          Alteracao.CodigoInterno := JsonString(
            Body,
            'codigo_interno'
          );

          Alteracao.Slug := JsonString(
            Body,
            'slug'
          );

          Alteracao.Nome := JsonString(
            Body,
            'nome'
          );

          Alteracao.Descricao := JsonString(
            Body,
            'descricao'
          );

          Alteracao.Objetivo := JsonString(
            Body,
            'objetivo'
          );

          Alteracao.ConteudoProgramatico := JsonString(
            Body,
            'conteudo_programatico'
          );

          Alteracao.CargaHorariaMinutos := JsonInteger(
            Body,
            'carga_horaria_minutos'
          );

          Alteracao.Modalidade := JsonString(
            Body,
            'modalidade'
          );

          Alteracao.ImagemUrl := JsonString(
            Body,
            'imagem_url'
          );

          Alteracao.PermitirInscricaoPublica := JsonBoolean(
            Body,
            'permitir_inscricao_publica',
            False
          );

          Alteracao.Situacao := JsonString(
            Body,
            'situacao'
          );
        finally
          Body.Free;
        end;

        Curso := TInstituicaoCursoService.Atualizar(
          Claims.IdInstituicao,
          IdCurso,
          Alteracao
        );

        try
          Dados := CursoParaJson(
            Curso
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Curso atualizado com sucesso.'
          );
        finally
          Curso.Free;
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

  {$REGION 'Alterar Situação do Curso'}

THorse.Patch(
  '/v1/certifica/instituicao/cursos/:id/situacao',

  procedure(
    Req: THorseRequest;
    Res: THorseResponse;
    Next: TProc
  )
  var
    Claims: TJWTClaims;
    IdCurso: Int64;

    JsonValue: TJSONValue;
    Body: TJSONObject;

    Situacao: string;
    Curso: TInstituicaoCursoItem;
  begin
    try
      if not AutorizarInstituicao(
        Req,
        Res,
        Claims
      ) then
        Exit;

      IdCurso :=
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

      Curso :=
        TInstituicaoCursoService.AlterarSituacao(
          Claims.IdInstituicao,
          IdCurso,
          Situacao
        );

      try
        TAppResponse.Ok(
          Res,
          CursoParaJson(
            Curso
          ),
          'Situação do curso atualizada com sucesso.'
        );

      finally
        Curso.Free;
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
