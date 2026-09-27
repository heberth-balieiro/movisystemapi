unit InstituicaoUsuario.Controller;

interface

type
  TInstituicaoUsuarioController = class
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
  App.RequestInfo,
  App.Response,
  APP.Errors,
  InstituicaoUsuario.Model,
  InstituicaoUsuario.Service,
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

function JsonIds(
  const AObj: TJSONObject;
  const ANome: string;
  out AEncontrado: Boolean
): TArray<Int64>;
var
  Valor: TJSONValue;
  Arr: TJSONArray;
  I: Integer;
  Id: Int64;
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
      'O campo ' + ANome + ' deve ser uma lista.'
    );

  Arr :=
    Valor as TJSONArray;

  SetLength(
    Result,
    Arr.Count
  );

  for I := 0 to Arr.Count - 1 do
  begin
    Id :=
      StrToInt64Def(
        Arr.Items[I].Value,
        0
      );

    if Id <= 0 then
      TAppErrors.RaiseBadRequest(
        'Identificador inválido em ' + ANome + '.'
      );

    Result[I] := Id;
  end;
end;

function PerfilParaJson(
  const APerfil: TInstituicaoUsuarioPerfilItem
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(APerfil.Id)
  );

  Result.AddPair(
    'nome',
    APerfil.Nome
  );

  Result.AddPair(
    'sistema',
    TJSONBool.Create(APerfil.Sistema)
  );

  Result.AddPair(
    'situacao',
    APerfil.Situacao
  );
end;

function UsuarioParaJson(
  const AUsuario: TInstituicaoUsuarioItem
): TJSONObject;
var
  Perfis: TJSONArray;
  Perfil: TInstituicaoUsuarioPerfilItem;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(AUsuario.Id)
  );

  Result.AddPair(
    'id_usuario',
    TJSONNumber.Create(AUsuario.IdUsuario)
  );

  Result.AddPair(
    'nome',
    AUsuario.Nome
  );

  Result.AddPair(
    'email',
    AUsuario.Email
  );

  Result.AddPair(
    'login',
    AUsuario.Login
  );

  Result.AddPair(
    'situacao',
    AUsuario.Situacao
  );

  Result.AddPair(
    'principal',
    TJSONBool.Create(AUsuario.Principal)
  );

  if AUsuario.TemUltimoAcesso then
    Result.AddPair(
      'ultimo_acesso_em',
      FormatDateTime(
        'yyyy-mm-dd"T"hh:nn:ss.zzz',
        AUsuario.UltimoAcessoEm
      )
    )
  else
    Result.AddPair(
      'ultimo_acesso_em',
      TJSONNull.Create
    );

  Result.AddPair(
    'criado_em',
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AUsuario.CriadoEm
    )
  );

  Result.AddPair(
    'atualizado_em',
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AUsuario.AtualizadoEm
    )
  );

  Perfis := TJSONArray.Create;

  for Perfil in AUsuario.Perfis do
    Perfis.AddElement(
      PerfilParaJson(
        Perfil
      )
    );

  Result.AddPair(
    'perfis',
    Perfis
  );
end;

class procedure TInstituicaoUsuarioController.Registry;
begin

  {$REGION 'Listar Usuarios'}

  THorse.Get(
    '/v1/certifica/instituicao/usuarios',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoUsuarioLista;
      Usuario: TInstituicaoUsuarioItem;
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
          'usuario.visualizar',
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
          TInstituicaoUsuarioService.Listar(
            Claims.IdInstituicao,
            Req.Query.Items['busca'],
            Req.Query.Items['situacao'],
            Pagina,
            PorPagina
          );

        try
          Itens := TJSONArray.Create;

          for Usuario in Resultado.Itens do
            Itens.AddElement(
              UsuarioParaJson(
                Usuario
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
            TJSONNumber.Create(Resultado.Pagina)
          );

          Paginacao.AddPair(
            'por_pagina',
            TJSONNumber.Create(Resultado.PorPagina)
          );

          Paginacao.AddPair(
            'total',
            TJSONNumber.Create(Resultado.Total)
          );

          Paginacao.AddPair(
            'total_paginas',
            TJSONNumber.Create(TotalPaginas)
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
            'Usuários carregados com sucesso.'
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


  {$REGION 'Buscar Usuario'}

  THorse.Get(
    '/v1/certifica/instituicao/usuarios/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdUsuarioInstituicao: Int64;
      Usuario: TInstituicaoUsuarioItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'usuario.visualizar',
          Claims
        ) then
          Exit;

        IdUsuarioInstituicao :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Usuario :=
          TInstituicaoUsuarioService.BuscarPorId(
            Claims.IdInstituicao,
            IdUsuarioInstituicao
          );

        try
          TAppResponse.Ok(
            Res,
            UsuarioParaJson(
              Usuario
            ),
            'Usuário carregado com sucesso.'
          );
        finally
          Usuario.Free;
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


  {$REGION 'Cadastrar Usuario'}

  THorse.Post(
    '/v1/certifica/instituicao/usuarios',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Cadastro: TInstituicaoUsuarioCadastro;
      Usuario: TInstituicaoUsuarioItem;
      PerfisInformados: Boolean;
      SenhaTemporaria: string;
      UsuarioJaExistia: Boolean;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'usuario.cadastrar',
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
              TInstituicaoUsuarioCadastro
            );

          Cadastro.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Cadastro.Email :=
            JsonString(
              Body,
              'email'
            );

          Cadastro.Login :=
            JsonString(
              Body,
              'login'
            );

          Cadastro.Perfis :=
            JsonIds(
              Body,
              'perfis',
              PerfisInformados
            );

          if not PerfisInformados then
            TAppErrors.RaiseBadRequest(
              'Informe os perfis do usuário.'
            );
        finally
          Body.Free;
        end;

        Usuario :=
          TInstituicaoUsuarioService.Cadastrar(
            Claims.IdInstituicao,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            Cadastro,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req),
            SenhaTemporaria,
            UsuarioJaExistia
          );

        try
          Dados :=
            UsuarioParaJson(
              Usuario
            );

          Dados.AddPair(
            'usuario_existente',
            TJSONBool.Create(
              UsuarioJaExistia
            )
          );

          if SenhaTemporaria <> '' then
            Dados.AddPair(
              'senha_temporaria',
              SenhaTemporaria
            )
          else
            Dados.AddPair(
              'senha_temporaria',
              TJSONNull.Create
            );

          TAppResponse.Created(
            Res,
            Dados,
            'Usuário cadastrado com sucesso.'
          );
        finally
          Usuario.Free;
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


  {$REGION 'Atualizar Vinculo'}

  THorse.Put(
    '/v1/certifica/instituicao/usuarios/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdUsuarioInstituicao: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Alteracao: TInstituicaoUsuarioAlteracao;
      Usuario: TInstituicaoUsuarioItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'usuario.editar',
          Claims
        ) then
          Exit;

        IdUsuarioInstituicao :=
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
              TInstituicaoUsuarioAlteracao
            );

          Alteracao.Login :=
            JsonString(
              Body,
              'login'
            );
        finally
          Body.Free;
        end;

        Usuario :=
          TInstituicaoUsuarioService.Atualizar(
            Claims.IdInstituicao,
            IdUsuarioInstituicao,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            Alteracao,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        try
          TAppResponse.Ok(
            Res,
            UsuarioParaJson(
              Usuario
            ),
            'Usuário atualizado com sucesso.'
          );
        finally
          Usuario.Free;
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


  {$REGION 'Atualizar Perfis'}

  THorse.Put(
    '/v1/certifica/instituicao/usuarios/:id/perfis',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdUsuarioInstituicao: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Perfis: TArray<Int64>;
      PerfisInformados: Boolean;
      Usuario: TInstituicaoUsuarioItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'usuario.editar',
          Claims
        ) then
          Exit;

        IdUsuarioInstituicao :=
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
          Perfis :=
            JsonIds(
              Body,
              'perfis',
              PerfisInformados
            );

          if not PerfisInformados then
            TAppErrors.RaiseBadRequest(
              'Informe os perfis do usuário.'
            );
        finally
          Body.Free;
        end;

        Usuario :=
          TInstituicaoUsuarioService.AtualizarPerfis(
            Claims.IdInstituicao,
            IdUsuarioInstituicao,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            Perfis,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        try
          TAppResponse.Ok(
            Res,
            UsuarioParaJson(
              Usuario
            ),
            'Perfis do usuário atualizados com sucesso.'
          );
        finally
          Usuario.Free;
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
    '/v1/certifica/instituicao/usuarios/:id/situacao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdUsuarioInstituicao: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao: string;
      Usuario: TInstituicaoUsuarioItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'usuario.inativar',
          Claims
        ) then
          Exit;

        IdUsuarioInstituicao :=
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

        Usuario :=
          TInstituicaoUsuarioService.AlterarSituacao(
            Claims.IdInstituicao,
            IdUsuarioInstituicao,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            Situacao,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        try
          TAppResponse.Ok(
            Res,
            UsuarioParaJson(
              Usuario
            ),
            'Situação do usuário atualizada com sucesso.'
          );
        finally
          Usuario.Free;
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
