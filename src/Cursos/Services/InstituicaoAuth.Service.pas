unit InstituicaoAuth.Service;

interface

uses
  InstituicaoAuth.DAO;

type
  TInstituicaoLoginResult = record
    Token: string;
    Dados: TInstituicaoLoginDados;
    Permissoes: TArray<string>;
    Modulos: TArray<string>;
  end;

  TInstituicaoAuthService = class
  public
    class function Login(
      const ASlug, ALogin, ASenha: string
    ): TInstituicaoLoginResult; static;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Uni,
  App.Config,
  App.JWT,
  APP.Errors,
  Auth.Passwords,
  Database.Connection,
  InstituicaoPermissao.DAO,
  PlataformaModulo.DAO;

class function TInstituicaoAuthService.Login(
  const ASlug, ALogin, ASenha: string
): TInstituicaoLoginResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoLoginDados;
  Roles: TArray<string>;
  ModulosLista: TList<string>;
begin
  Result := Default(TInstituicaoLoginResult);

  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Instituição não informada.'
    );

  if Trim(ALogin).IsEmpty or Trim(ASenha).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe usuário e senha.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );

  try
    if not TInstituicaoAuthDAO.BuscarLogin(
      Conn,
      ASlug,
      ALogin,
      Dados
    ) then
      TAppErrors.RaiseUnauthorized(
        'Usu' + #$00E1 + 'rio ou senha inv' + #$00E1 + 'lidos.'
      );

    if not SameText(Dados.UsuarioSituacao, 'ATIVO') then
      TAppErrors.RaiseUnauthorized(
        'Usu' + #$00E1 + 'rio ou senha inv' + #$00E1 + 'lidos.'
      );

    if not SameText(Dados.VinculoSituacao, 'ATIVO') then
      TAppErrors.RaiseUnauthorized(
        'Usu' + #$00E1 + 'rio ou senha inv' + #$00E1 + 'lidos.'
      );

    // Durante implantação o administrador precisa conseguir acessar.
    if not (
      SameText(Dados.InstituicaoSituacao, 'ATIVA') or
      SameText(Dados.InstituicaoSituacao, 'IMPLANTACAO')
    ) then
      TAppErrors.RaiseUnauthorized(
        'Acesso à instituição indisponível.'
      );

    if not VerifySenha(ASenha, Dados.SenhaHash) then
      TAppErrors.RaiseUnauthorized('Usu' + #$00E1 + 'rio ou senha inv' + #$00E1 + 'lidos.');

    if not TPlataformaModuloDAO.InstituicaoPossuiModulo(
      Conn,
      Dados.IdInstituicao,
      'CERTIFICA'
    ) then
      TAppErrors.RaiseForbidden(
        'O módulo MoviSystem Certifica não está liberado para esta instituição.'
      );

    if Dados.Principal then
      Roles := ['ADMIN_INSTITUICAO']
    else
      Roles := ['USUARIO_INSTITUICAO'];

    Result.Token :=
      TAppJWT.GerarTokenInstituicao(
        Config.JWT,
        Dados.IdUsuario,
        Dados.IdInstituicao,
        Roles,
        Dados.IdUsuarioInstituicao);

    Result.Dados := Dados;

    Result.Permissoes :=
      TInstituicaoPermissaoDAO.ListarPermissoesUsuario(
        Conn,
        Dados.IdInstituicao,
        Dados.IdUsuarioInstituicao
      );

    ModulosLista :=
      TPlataformaModuloDAO.ListarCodigosInstituicao(
        Conn,
        Dados.IdInstituicao
      );
    try
      Result.Modulos :=
        ModulosLista.ToArray;
    finally
      ModulosLista.Free;
    end;

    TInstituicaoAuthDAO.RegistrarLogin(
      Conn,
      Dados.IdUsuario,
      Dados.IdUsuarioInstituicao);
  finally
    Conn.Free;
  end;
end;

end.
