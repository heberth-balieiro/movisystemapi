unit PlataformaUsuario.Controller;

interface

type
  TPlataformaUsuarioController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Classes,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaUsuario.Model,
  PlataformaUsuario.Service,
  System.Generics.Collections;

function AutorizarSuperAdmin(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if not TAppToken.PossuiRole(AClaims.Roles, 'SUPER_ADMIN') then
  begin
    TAppResponse.Forbidden(
      Res,
      'Sem permissão para administrar usuários da plataforma.'
    );
    Exit;
  end;

  Result := True;
end;

class procedure TPlataformaUsuarioController.Registry;
begin
  {$REGION 'Novo Usuario'}
  THorse.Post('/v1/certifica/plataforma/usuarios',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      Usuario: TPlataformaUsuarioModel;
      Dados: TJSONObject;
      Nome, Email: string;
      SenhaTemporaria: string;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Nome := Trim(TAppClasses.GetJsonString(Body, 'nome'));

        Email := Trim(TAppClasses.GetJsonString(Body, 'email'));

        Usuario := TPlataformaUsuarioService.Criar(
          Nome,
          Email,
          Claims.UserId,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req),
          SenhaTemporaria
        );

        try
          Dados := TJSONObject.Create;

          Dados.AddPair('id',TJSONNumber.Create(Usuario.Id));

          Dados.AddPair('nome',Usuario.Nome);

          Dados.AddPair('email',Usuario.Email);

          Dados.AddPair('role','SUPER_ADMIN');

          Dados.AddPair('situacao', Usuario.Situacao);

          Dados.AddPair('criado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Usuario.CriadoEm));

          // A senha temporária é devolvida somente na criação.
          Dados.AddPair(
            'senha_temporaria',
            SenhaTemporaria
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
          TAppErrors.HandleException(Res, E);
      end;
    end);
  {$ENDREGION}

  {$REGION 'Alterar senha'}

    THorse.Post('/v1/certifica/plataforma/usuarios/:id/renovar-senha',

  procedure(
    Req: THorseRequest;
    Res: THorseResponse;
    Next: TProc
  )
  var
    Claims: TJWTClaims;
    Dados: TJSONObject;
    IdUsuario: Int64;
    SenhaTemporaria: string;
  begin
    try
      if not AutorizarSuperAdmin(
        Req,
        Res,
        Claims
      ) then
        Exit;

      if not TryStrToInt64(
        Req.Params['id'],
        IdUsuario
      ) then
        TAppErrors.RaiseBadRequest(
          'Código do usuário inválido.'
        );

      SenhaTemporaria :=
        TPlataformaUsuarioService.RenovarSenha(
          IdUsuario,
          Claims.UserId,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req)
        );

      Dados := TJSONObject.Create;

      Dados.AddPair(
        'id',
        TJSONNumber.Create(IdUsuario)
      );

      // A senha é retornada somente nesta operação.
      Dados.AddPair(
        'senha_temporaria',
        SenhaTemporaria
      );

      TAppResponse.Ok(
        Res,
        Dados,
        'Senha renovada com sucesso.'
      );

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

  {$REGION 'Buscar usuario'}

  THorse.Get(
  '/v1/certifica/plataforma/usuarios',

  procedure(
    Req: THorseRequest;
    Res: THorseResponse;
    Next: TProc
  )
  var
    Claims: TJWTClaims;
    Usuarios: TObjectList<TPlataformaUsuarioModel>;
    Usuario: TPlataformaUsuarioModel;
    Dados: TJSONArray;
    Item: TJSONObject;
  begin
    try
      if not AutorizarSuperAdmin(Req, Res, Claims) then
        Exit;

      Usuarios := TPlataformaUsuarioService.Listar;
      try
        Dados := TJSONArray.Create;

        for Usuario in Usuarios do
        begin
          Item := TJSONObject.Create;

          Item.AddPair(
            'id',
            TJSONNumber.Create(Usuario.Id)
          );

          Item.AddPair(
            'nome',
            Usuario.Nome
          );

          Item.AddPair(
            'email',
            Usuario.Email
          );

          Item.AddPair(
            'role',
            'SUPER_ADMIN'
          );

          Item.AddPair(
            'situacao',
            Usuario.Situacao
          );

          if Usuario.TemUltimoLogin then
            Item.AddPair(
              'ultimo_login_em',
              FormatDateTime(
                'yyyy-mm-dd"T"hh:nn:ss',
                Usuario.UltimoLoginEm
              )
            )
          else
            Item.AddPair(
              'ultimo_login_em',
              TJSONNull.Create
            );

          Item.AddPair(
            'criado_em',
            FormatDateTime(
              'yyyy-mm-dd"T"hh:nn:ss',
              Usuario.CriadoEm
            )
          );

          Dados.AddElement(Item);
        end;

        TAppResponse.Ok(
          Res,
          Dados,
          'Usuários carregados com sucesso.'
        );
      finally
        Usuarios.Free;
      end;

    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end
);

  {$ENDREGION}

  {$REGION 'Buscar usuario por id'}

  THorse.Get('/v1/certifica/plataforma/usuarios/:id',

  procedure(
    Req: THorseRequest;
    Res: THorseResponse;
    Next: TProc
  )
  var
    Claims: TJWTClaims;
    Usuario: TPlataformaUsuarioModel;
    Dados: TJSONObject;
    IdUsuario: Int64;
  begin
    try
      if not AutorizarSuperAdmin(Req, Res, Claims) then
        Exit;

      if not TryStrToInt64(Req.Params['id'], IdUsuario) then
        TAppErrors.RaiseBadRequest('Código do usuário inválido.');

      Usuario := TPlataformaUsuarioService.BuscarPorId(IdUsuario);
      try
        Dados := TJSONObject.Create;

        Dados.AddPair(
          'id',
          TJSONNumber.Create(Usuario.Id)
        );

        Dados.AddPair(
          'nome',
          Usuario.Nome
        );

        Dados.AddPair(
          'email',
          Usuario.Email
        );

        Dados.AddPair(
          'role',
          'SUPER_ADMIN'
        );

        Dados.AddPair(
          'situacao',
          Usuario.Situacao
        );

        if Usuario.TemUltimoLogin then
          Dados.AddPair(
            'ultimo_login_em',
            FormatDateTime(
              'yyyy-mm-dd"T"hh:nn:ss',
              Usuario.UltimoLoginEm
            )
          )
        else
          Dados.AddPair(
            'ultimo_login_em',
            TJSONNull.Create
          );

        Dados.AddPair(
          'criado_em',
          FormatDateTime(
            'yyyy-mm-dd"T"hh:nn:ss',
            Usuario.CriadoEm
          )
        );

        TAppResponse.Ok(
          Res,
          Dados,
          'Usuário carregado com sucesso.'
        );
      finally
        Usuario.Free;
      end;

    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end
);

  {$ENDREGION}

  {$REGION 'Alteracao'}

  THorse.Put('/v1/certifica/plataforma/usuarios/:id',

  procedure(
    Req: THorseRequest;
    Res: THorseResponse;
    Next: TProc
  )
  var
    Claims: TJWTClaims;
    Body: TJSONObject;
    Usuario: TPlataformaUsuarioModel;
    Dados: TJSONObject;
    IdUsuario: Int64;
    Nome, Email: string;
  begin
    try
      if not AutorizarSuperAdmin(Req, Res, Claims) then
        Exit;

      if not TryStrToInt64(
        Req.Params['id'],
        IdUsuario
      ) then
        TAppErrors.RaiseBadRequest(
          'Código do usuário inválido.'
        );

      Body := Req.Body<TJSONObject>;

      if Body = nil then
        TAppErrors.RaiseBadRequest(
          'JSON inválido ou não informado.'
        );

      Nome := Trim(
        TAppClasses.GetJsonString(
          Body,
          'nome'
        )
      );

      Email := Trim(
        TAppClasses.GetJsonString(
          Body,
          'email'
        )
      );

      Usuario :=
        TPlataformaUsuarioService.Atualizar(
          IdUsuario,
          Nome,
          Email,
          Claims.UserId,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req)
        );

      try
        Dados := TJSONObject.Create;

        Dados.AddPair(
          'id',
          TJSONNumber.Create(Usuario.Id)
        );

        Dados.AddPair(
          'nome',
          Usuario.Nome
        );

        Dados.AddPair(
          'email',
          Usuario.Email
        );

        Dados.AddPair(
          'role',
          'SUPER_ADMIN'
        );

        Dados.AddPair(
          'situacao',
          Usuario.Situacao
        );

        if Usuario.TemUltimoLogin then
          Dados.AddPair(
            'ultimo_login_em',
            FormatDateTime(
              'yyyy-mm-dd"T"hh:nn:ss',
              Usuario.UltimoLoginEm
            )
          )
        else
          Dados.AddPair(
            'ultimo_login_em',
            TJSONNull.Create
          );

        Dados.AddPair(
          'criado_em',
          FormatDateTime(
            'yyyy-mm-dd"T"hh:nn:ss',
            Usuario.CriadoEm
          )
        );

        TAppResponse.Ok(
          Res,
          Dados,
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

  {$REGION 'Inativa'}

  THorse.Patch('/v1/certifica/plataforma/usuarios/:id/situacao',

  procedure(
    Req: THorseRequest;
    Res: THorseResponse;
    Next: TProc
  )
  var
    Claims: TJWTClaims;
    Body: TJSONObject;
    Usuario: TPlataformaUsuarioModel;
    Dados: TJSONObject;
    IdUsuario: Int64;
    Situacao: string;
  begin
    try
      if not AutorizarSuperAdmin(Req, Res, Claims) then
        Exit;

      if not TryStrToInt64(
        Req.Params['id'],
        IdUsuario
      ) then
        TAppErrors.RaiseBadRequest(
          'Código do usuário inválido.'
        );

      Body := Req.Body<TJSONObject>;

      if Body = nil then
        TAppErrors.RaiseBadRequest(
          'JSON inválido ou não informado.'
        );

      Situacao := Trim(
        TAppClasses.GetJsonString(
          Body,
          'situacao'
        )
      );

      Usuario :=
        TPlataformaUsuarioService.AtualizarSituacao(
          IdUsuario,
          Situacao,
          Claims.UserId,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req)
        );

      try
        Dados := TJSONObject.Create;

        Dados.AddPair(
          'id',
          TJSONNumber.Create(Usuario.Id)
        );

        Dados.AddPair('nome', Usuario.Nome);
        Dados.AddPair('email', Usuario.Email);
        Dados.AddPair('role', 'SUPER_ADMIN');
        Dados.AddPair('situacao', Usuario.Situacao);

        if Usuario.TemUltimoLogin then
          Dados.AddPair(
            'ultimo_login_em',
            FormatDateTime(
              'yyyy-mm-dd"T"hh:nn:ss',
              Usuario.UltimoLoginEm
            )
          )
        else
          Dados.AddPair(
            'ultimo_login_em',
            TJSONNull.Create
          );

        Dados.AddPair(
          'criado_em',
          FormatDateTime(
            'yyyy-mm-dd"T"hh:nn:ss',
            Usuario.CriadoEm
          )
        );

        TAppResponse.Ok(
          Res,
          Dados,
          'Situação do usuário atualizada com sucesso.'
        );

      finally
        Usuario.Free;
      end;

    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end
);

  {$ENDREGION}

end;

end.
