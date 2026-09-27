unit InstituicaoParticipanteAcesso.Service;

interface

uses
  InstituicaoParticipanteAcesso.Model;

type
  TInstituicaoParticipanteAcessoService = class
  public
    class function Consultar(
      const AIdInstituicao,
            AIdParticipante: Int64
    ): TParticipanteAcessoInfo; static;

    class function Liberar(
      const AIdInstituicao,
            AIdParticipante: Int64;
      const ASenhaInicial: string
    ): TParticipanteAcessoInfo; static;

    class function Revogar(
      const AIdInstituicao,
            AIdParticipante: Int64
    ): TParticipanteAcessoInfo; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Auth.Passwords,
  Database.Connection,
  InstituicaoParticipanteAcesso.DAO;

class function TInstituicaoParticipanteAcessoService.Consultar(
  const AIdInstituicao,
        AIdParticipante: Int64
): TParticipanteAcessoInfo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest('Participante inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoParticipanteAcessoDAO.BuscarInfo(
      Conn,
      AIdInstituicao,
      AIdParticipante
    );

    if Result = nil then
      TAppErrors.RaiseBadRequest('Participante não encontrado.');
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoService.Liberar(
  const AIdInstituicao,
        AIdParticipante: Int64;
  const ASenhaInicial: string
): TParticipanteAcessoInfo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Participante: TParticipanteBaseAcesso;
  Usuario: TUsuarioGlobalAcesso;
  EmailNormalizado: string;
  IdUsuario: Int64;
  IdUsuarioInstituicao: Int64;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest('Participante inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Participante := TInstituicaoParticipanteAcessoDAO.BuscarParticipante(
      Conn,
      AIdInstituicao,
      AIdParticipante
    );

    if not Participante.Encontrado then
      TAppErrors.RaiseBadRequest('Participante não encontrado.');

    if not SameText(Participante.Situacao, 'ATIVO') then
      TAppErrors.RaiseBadRequest('Somente participante ativo pode receber acesso ao portal.');

    if Trim(Participante.Email).IsEmpty then
      TAppErrors.RaiseBadRequest('Informe um e-mail no cadastro do participante antes de liberar o acesso.');

    if Participante.TemUsuarioInstituicao then
      Exit(TInstituicaoParticipanteAcessoDAO.BuscarInfo(
        Conn,
        AIdInstituicao,
        AIdParticipante
      ));

    EmailNormalizado := LowerCase(Trim(Participante.Email));

    Conn.StartTransaction;
    try
      Usuario := TInstituicaoParticipanteAcessoDAO.BuscarUsuarioPorEmail(
        Conn,
        EmailNormalizado
      );

      if Usuario.Encontrado then
      begin
        if not SameText(Usuario.Situacao, 'ATIVO') then
          TAppErrors.RaiseBadRequest(
            'Já existe uma conta global para este e-mail, porém ela não está ativa.'
          );

        IdUsuario := Usuario.IdUsuario;
      end
      else
      begin
        if Length(ASenhaInicial) < 8 then
          TAppErrors.RaiseBadRequest(
            'Para uma nova conta informe senha_inicial com pelo menos 8 caracteres.'
          );

        IdUsuario := TInstituicaoParticipanteAcessoDAO.CriarUsuario(
          Conn,
          Participante.Nome,
          Trim(Participante.Email),
          EmailNormalizado,
          HashSenha(ASenhaInicial)
        );
      end;

      IdUsuarioInstituicao :=
        TInstituicaoParticipanteAcessoDAO.BuscarUsuarioInstituicao(
          Conn,
          AIdInstituicao,
          IdUsuario
        );

      if IdUsuarioInstituicao <= 0 then
        IdUsuarioInstituicao :=
          TInstituicaoParticipanteAcessoDAO.CriarUsuarioInstituicao(
            Conn,
            AIdInstituicao,
            IdUsuario,
            Participante.IdUnidadeOrganizacional,
            Participante.TemUnidadeOrganizacional
          );

      if TInstituicaoParticipanteAcessoDAO.UsuarioInstituicaoJaLigadoOutroParticipante(
        Conn,
        AIdInstituicao,
        IdUsuarioInstituicao,
        AIdParticipante
      ) then
        TAppErrors.RaiseBadRequest(
          'Esta conta já está vinculada a outro participante da instituição.'
        );

      TInstituicaoParticipanteAcessoDAO.VincularParticipante(
        Conn,
        AIdInstituicao,
        AIdParticipante,
        IdUsuarioInstituicao
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Result := TInstituicaoParticipanteAcessoDAO.BuscarInfo(
      Conn,
      AIdInstituicao,
      AIdParticipante
    );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoService.Revogar(
  const AIdInstituicao,
        AIdParticipante: Int64
): TParticipanteAcessoInfo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Participante: TParticipanteBaseAcesso;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest('Participante inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Participante := TInstituicaoParticipanteAcessoDAO.BuscarParticipante(
      Conn,
      AIdInstituicao,
      AIdParticipante
    );

    if not Participante.Encontrado then
      TAppErrors.RaiseBadRequest('Participante não encontrado.');

    if Participante.TemUsuarioInstituicao then
      TInstituicaoParticipanteAcessoDAO.RevogarVinculo(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    Result := TInstituicaoParticipanteAcessoDAO.BuscarInfo(
      Conn,
      AIdInstituicao,
      AIdParticipante
    );
  finally
    Conn.Free;
  end;
end;

end.
