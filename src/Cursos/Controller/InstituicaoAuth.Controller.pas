unit InstituicaoAuth.Controller;

interface

type
  TInstituicaoAuthController = class
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
  App.Response,
  APP.Errors,
  App.RateLimit,
  InstituicaoAuth.DAO,
  InstituicaoAuth.Service,
  InstituicaoPermissao.Service,
  PlataformaModulo.Service;

class procedure TInstituicaoAuthController.Registry;
begin
  THorse.Post(
    '/v1/certifica/instituicao/:slug/auth/login',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Body: TJSONObject;
      Resultado: TInstituicaoLoginResult;
      Dados: TJSONObject;
      UsuarioJson: TJSONObject;
      InstituicaoJson: TJSONObject;
      TemaJson: TJSONObject;
      Permissoes: TJSONArray;
      Modulos: TJSONArray;
      Permissao,
      CodigoModulo: string;
      Slug, Login, Senha: string;
    begin
      try
        Res.RawWebResponse.SetCustomHeader('Cache-Control', 'no-store');

        if not TAppRateLimit.EnforceIP(Req, Res, 'instituicao-auth-login', 15, 300) then
          Exit;

        if Length(Req.Body) > 4096 then
          TAppErrors.RaiseBadRequest('Requisição inválida.');

        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest(
            'JSON inválido ou não informado.'
          );

        Slug := LowerCase(
          Trim(Req.Params['slug'])
        );

        Login := Trim(
          TAppClasses.GetJsonString(
            Body,
            'login'
          )
        );

        Senha :=
          TAppClasses.GetJsonString(
            Body,
            'senha'
          );

        if not TAppRateLimit.EnforceIdentity(
          Req, Res, 'instituicao-auth-identidade', Slug + '|' + Login, 8, 600
        ) then
          Exit;

        Resultado :=
          TInstituicaoAuthService.Login(
            Slug,
            Login,
            Senha
          );

        UsuarioJson := TJSONObject.Create;

        UsuarioJson.AddPair(
          'id',
          TJSONNumber.Create(
            Resultado.Dados.IdUsuario
          )
        );

        UsuarioJson.AddPair(
          'id_usuario_instituicao',
          TJSONNumber.Create(
            Resultado.Dados.IdUsuarioInstituicao
          )
        );

        UsuarioJson.AddPair(
          'nome',
          Resultado.Dados.Nome
        );

        UsuarioJson.AddPair(
          'email',
          Resultado.Dados.Email
        );

        if Resultado.Dados.Principal then
          UsuarioJson.AddPair(
            'role',
            'ADMIN_INSTITUICAO'
          )
        else
          UsuarioJson.AddPair(
            'role',
            'USUARIO_INSTITUICAO'
          );

        Permissoes := TJSONArray.Create;

        for Permissao in Resultado.Permissoes do
          Permissoes.Add(
            Permissao
          );

        UsuarioJson.AddPair(
          'permissions',
          Permissoes
        );

        TemaJson := TJSONObject.Create;

        TemaJson.AddPair(
          'logo_url',
          Resultado.Dados.LogoUrl
        );

        TemaJson.AddPair(
          'cor_primaria',
          Resultado.Dados.CorPrimaria
        );

        TemaJson.AddPair(
          'cor_secundaria',
          Resultado.Dados.CorSecundaria
        );

        TemaJson.AddPair(
          'cor_destaque',
          Resultado.Dados.CorDestaque
        );

        TemaJson.AddPair(
          'cor_fundo',
          Resultado.Dados.CorFundo
        );

        TemaJson.AddPair(
          'cor_texto',
          Resultado.Dados.CorTexto
        );

        InstituicaoJson := TJSONObject.Create;

        InstituicaoJson.AddPair(
          'id',
          TJSONNumber.Create(
            Resultado.Dados.IdInstituicao
          )
        );

        InstituicaoJson.AddPair(
          'slug',
          Resultado.Dados.InstituicaoSlug
        );

        InstituicaoJson.AddPair(
          'nome',
          Resultado.Dados.InstituicaoNome
        );

        InstituicaoJson.AddPair(
          'situacao',
          Resultado.Dados.InstituicaoSituacao
        );

        InstituicaoJson.AddPair(
          'tema',
          TemaJson
        );

        Modulos := TJSONArray.Create;

        for CodigoModulo in Resultado.Modulos do
          Modulos.Add(
            CodigoModulo
          );

        InstituicaoJson.AddPair(
          'modulos',
          Modulos
        );

        Dados := TJSONObject.Create;

        Dados.AddPair(
          'token',
          Resultado.Token
        );

        Dados.AddPair(
          'usuario',
          UsuarioJson
        );

        Dados.AddPair(
          'instituicao',
          InstituicaoJson
        );

        TAppResponse.Ok(
          Res,
          Dados,
          'Login realizado com sucesso.'
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
  THorse.Get(
    '/v1/certifica/instituicao/auth/contexto',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      ListaPermissoes: TArray<string>;
      ListaModulos: TList<string>;
      Permissoes: TJSONArray;
      Modulos: TJSONArray;
      Permissao,
      CodigoModulo: string;
      Dados: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if (Claims.IdInstituicao <= 0) or
           (Claims.IdUsuarioInstituicao <= 0) then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem contexto de instituição.'
          );
          Exit;
        end;

        ListaPermissoes :=
          TInstituicaoPermissaoService.ListarDoUsuario(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao
          );

        ListaModulos :=
          TPlataformaModuloService.ListarInstituicao(
            Claims.IdInstituicao
          );
        try
          Permissoes := TJSONArray.Create;
          for Permissao in ListaPermissoes do
            Permissoes.Add(Permissao);

          Modulos := TJSONArray.Create;
          for CodigoModulo in ListaModulos do
            Modulos.Add(CodigoModulo);

          Dados := TJSONObject.Create;
          Dados.AddPair('permissoes', Permissoes);
          Dados.AddPair('modulos', Modulos);

          TAppResponse.Ok(
            Res,
            Dados,
            'Contexto de acesso atualizado com sucesso.'
          );
        finally
          ListaModulos.Free;
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

  THorse.Get(
    '/v1/certifica/instituicao/auth/permissoes',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Lista: TArray<string>;
      Permissoes: TJSONArray;
      Permissao: string;
    begin
      try
        if not TAppToken.ValidarToken(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if (Claims.IdInstituicao <= 0) or
           (Claims.IdUsuarioInstituicao <= 0) then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem contexto de instituição.'
          );
          Exit;
        end;

        Lista :=
          TInstituicaoPermissaoService.ListarDoUsuario(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao
          );

        Permissoes :=
          TJSONArray.Create;

        for Permissao in Lista do
          Permissoes.Add(
            Permissao
          );

        TAppResponse.Ok(
          Res,
          Permissoes,
          'Permissões atualizadas com sucesso.'
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

end;

end.
