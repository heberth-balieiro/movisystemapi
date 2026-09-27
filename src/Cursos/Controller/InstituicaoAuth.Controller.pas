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
  App.Response,
  APP.Errors,
  InstituicaoAuth.DAO,
  InstituicaoAuth.Service;

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
      Permissao: string;
      Slug, Login, Senha: string;
    begin
      try
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
end;

end.
