unit InstituicaoPerfil.Controller;

interface

type
  TInstituicaoPerfilController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  InstituicaoPerfil.Model,
  InstituicaoPerfil.Service,
  InstituicaoPermissao.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  const APermissao: string;
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

  if AClaims.IdUsuarioInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem vínculo de usuário com a instituição.'
    );
    Exit;
  end;

  TInstituicaoPermissaoService.Exigir(
    AClaims.IdInstituicao,
    AClaims.IdUsuarioInstituicao,
    APermissao
  );

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

function JsonPermissoes(
  const AObj: TJSONObject;
  const ANome: string;
  out AEncontrado: Boolean
): TArray<Int64>;
var
  Valor: TJSONValue;
  Arr: TJSONArray;
  I: Integer;
  IdPermissao: Int64;
begin
  SetLength(Result, 0);
  AEncontrado := False;

  Valor :=
    AObj.GetValue(ANome);

  if Valor = nil then
    Exit;

  AEncontrado := True;

  if not (Valor is TJSONArray) then
    TAppErrors.RaiseBadRequest(
      'O campo permissoes deve ser uma lista.'
    );

  Arr :=
    Valor as TJSONArray;

  SetLength(
    Result,
    Arr.Count
  );

  for I := 0 to Arr.Count - 1 do
  begin
    IdPermissao :=
      StrToInt64Def(
        Arr.Items[I].Value,
        0
      );

    if IdPermissao <= 0 then
      TAppErrors.RaiseBadRequest(
        'Permissão inválida.'
      );

    Result[I] :=
      IdPermissao;
  end;
end;

function PermissaoParaJson(
  const AItem: TInstituicaoPermissaoItem
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(AItem.Id)
  );

  Result.AddPair(
    'codigo',
    AItem.Codigo
  );

  Result.AddPair(
    'modulo',
    AItem.Modulo
  );

  Result.AddPair(
    'descricao',
    AItem.Descricao
  );

  Result.AddPair(
    'situacao',
    AItem.Situacao
  );

  Result.AddPair(
    'selecionada',
    TJSONBool.Create(
      AItem.Selecionada
    )
  );
end;

function PerfilParaJson(
  const AItem: TInstituicaoPerfilItem;
  const AIncluirPermissoes: Boolean
): TJSONObject;
var
  Permissoes: TJSONArray;
  Permissao: TInstituicaoPermissaoItem;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(AItem.Id)
  );

  Result.AddPair(
    'nome',
    AItem.Nome
  );

  Result.AddPair(
    'descricao',
    AItem.Descricao
  );

  Result.AddPair(
    'sistema',
    TJSONBool.Create(AItem.Sistema)
  );

  Result.AddPair(
    'situacao',
    AItem.Situacao
  );

  Result.AddPair(
    'quantidade_permissoes',
    TJSONNumber.Create(
      AItem.QuantidadePermissoes
    )
  );

  Result.AddPair(
    'criado_em',
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AItem.CriadoEm
    )
  );

  Result.AddPair(
    'atualizado_em',
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AItem.AtualizadoEm
    )
  );

  if AIncluirPermissoes then
  begin
    Permissoes :=
      TJSONArray.Create;

    for Permissao in AItem.Permissoes do
      Permissoes.AddElement(
        PermissaoParaJson(
          Permissao
        )
      );

    Result.AddPair(
      'permissoes',
      Permissoes
    );
  end;
end;

class procedure TInstituicaoPerfilController.Registry;
begin

  {$REGION 'Listar Perfis'}

  THorse.Get(
    '/v1/certifica/instituicao/perfis',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoPerfilLista;
      Perfil: TInstituicaoPerfilItem;
      Dados: TJSONObject;
      Paginacao: TJSONObject;
      Itens: TJSONArray;
      Pagina: Integer;
      PorPagina: Integer;
      TotalPaginas: Integer;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'perfil.visualizar',
          Claims
        ) then
          Exit;

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
          TInstituicaoPerfilService.Listar(
            Claims.IdInstituicao,
            Req.Query.Items['busca'],
            Req.Query.Items['situacao'],
            Pagina,
            PorPagina
          );

        try
          Itens := TJSONArray.Create;

          for Perfil in Resultado.Itens do
            Itens.AddElement(
              PerfilParaJson(
                Perfil,
                False
              )
            );

          if Resultado.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas :=
              (
                Resultado.Total +
                Resultado.PorPagina -
                1
              ) div Resultado.PorPagina;

          Paginacao := TJSONObject.Create;

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

          Dados := TJSONObject.Create;

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
            'Perfis carregados com sucesso.'
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


  {$REGION 'Buscar Perfil'}

  THorse.Get(
    '/v1/certifica/instituicao/perfis/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdPerfil: Int64;
      Perfil: TInstituicaoPerfilItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'perfil.visualizar',
          Claims
        ) then
          Exit;

        IdPerfil :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Perfil :=
          TInstituicaoPerfilService.BuscarPorId(
            Claims.IdInstituicao,
            IdPerfil
          );

        try
          TAppResponse.Ok(
            Res,
            PerfilParaJson(
              Perfil,
              True
            ),
            'Perfil carregado com sucesso.'
          );
        finally
          Perfil.Free;
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


  {$REGION 'Listar Permissoes'}

  THorse.Get(
    '/v1/certifica/instituicao/permissoes',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdPerfil: Int64;
      Lista: TObjectList<TInstituicaoPermissaoItem>;
      Permissao: TInstituicaoPermissaoItem;
      Dados: TJSONArray;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'perfil.visualizar',
          Claims
        ) then
          Exit;

        IdPerfil :=
          StrToInt64Def(
            Req.Query.Items['id_perfil'],
            0
          );

        Lista :=
          TInstituicaoPerfilService.ListarPermissoes(
            Claims.IdInstituicao,
            IdPerfil
          );

        try
          Dados := TJSONArray.Create;

          for Permissao in Lista do
            Dados.AddElement(
              PermissaoParaJson(
                Permissao
              )
            );

          TAppResponse.Ok(
            Res,
            Dados,
            'Permissões carregadas com sucesso.'
          );
        finally
          Lista.Free;
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


  {$REGION 'Cadastrar Perfil'}

  THorse.Post(
    '/v1/certifica/instituicao/perfis',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Cadastro: TInstituicaoPerfilCadastro;
      Permissoes: TArray<Int64>;
      PermissoesInformadas: Boolean;
      Perfil: TInstituicaoPerfilItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'perfil.cadastrar',
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
              TInstituicaoPerfilCadastro
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

          Permissoes :=
            JsonPermissoes(
              Body,
              'permissoes',
              PermissoesInformadas
            );

          if not PermissoesInformadas then
            SetLength(
              Permissoes,
              0
            );
        finally
          Body.Free;
        end;

        Perfil :=
          TInstituicaoPerfilService.Cadastrar(
            Claims.IdInstituicao,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            Cadastro,
            Permissoes,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        try
          TAppResponse.Created(
            Res,
            PerfilParaJson(
              Perfil,
              True
            ),
            'Perfil cadastrado com sucesso.'
          );
        finally
          Perfil.Free;
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


  {$REGION 'Atualizar Perfil'}

  THorse.Put(
    '/v1/certifica/instituicao/perfis/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdPerfil: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Alteracao: TInstituicaoPerfilAlteracao;
      Perfil: TInstituicaoPerfilItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'perfil.editar',
          Claims
        ) then
          Exit;

        IdPerfil :=
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
              TInstituicaoPerfilAlteracao
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

        Perfil :=
          TInstituicaoPerfilService.Atualizar(
            Claims.IdInstituicao,
            IdPerfil,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            Alteracao,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        try
          TAppResponse.Ok(
            Res,
            PerfilParaJson(
              Perfil,
              True
            ),
            'Perfil atualizado com sucesso.'
          );
        finally
          Perfil.Free;
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


  {$REGION 'Atualizar Permissoes'}

  THorse.Put(
    '/v1/certifica/instituicao/perfis/:id/permissoes',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdPerfil: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Permissoes: TArray<Int64>;
      PermissoesInformadas: Boolean;
      Perfil: TInstituicaoPerfilItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'perfil.editar',
          Claims
        ) then
          Exit;

        IdPerfil :=
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
          Permissoes :=
            JsonPermissoes(
              Body,
              'permissoes',
              PermissoesInformadas
            );

          if not PermissoesInformadas then
            TAppErrors.RaiseBadRequest(
              'Informe a lista de permissões.'
            );
        finally
          Body.Free;
        end;

        Perfil :=
          TInstituicaoPerfilService.AtualizarPermissoes(
            Claims.IdInstituicao,
            IdPerfil,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            Permissoes,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        try
          TAppResponse.Ok(
            Res,
            PerfilParaJson(
              Perfil,
              True
            ),
            'Permissões atualizadas com sucesso.'
          );
        finally
          Perfil.Free;
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


  {$REGION 'Alterar Situacao'}

  THorse.Patch(
    '/v1/certifica/instituicao/perfis/:id/situacao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdPerfil: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao: string;
      Perfil: TInstituicaoPerfilItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'perfil.inativar',
          Claims
        ) then
          Exit;

        IdPerfil :=
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

        Perfil :=
          TInstituicaoPerfilService.AlterarSituacao(
            Claims.IdInstituicao,
            IdPerfil,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            Situacao,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        try
          TAppResponse.Ok(
            Res,
            PerfilParaJson(
              Perfil,
              True
            ),
            'Situação do perfil atualizada com sucesso.'
          );
        finally
          Perfil.Free;
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
