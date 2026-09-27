unit InstituicaoParticipanteAcesso.Service;

interface

uses
  InstituicaoParticipanteAcesso.Model,
  InstituicaoParticipanteAcesso.DAO;

type
  TInstituicaoParticipanteAcessoService = class
  private
    class function GerarTokenSeguro: string; static;

    class function MontarMensagemAcesso(
      const AParticipante: TParticipanteBaseAcesso;
      const AUsuarioJaTinhaSenha: Boolean;
      const ALink: string
    ): string; static;

  public
    class function Consultar(
      const AIdInstituicao,
            AIdParticipante: Int64
    ): TParticipanteAcessoInfo; static;

    class function Liberar(
      const AIdInstituicao,
            AIdParticipante: Int64
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
  InstituicaoWhatsApp.Service;

class function TInstituicaoParticipanteAcessoService.GerarTokenSeguro: string;
var
  G1: TGUID;
  G2: TGUID;

  function LimparGuid(
    const AGuid: TGUID
  ): string;
  begin
    Result :=
      LowerCase(
        StringReplace(
          StringReplace(
            StringReplace(
              GUIDToString(AGuid),
              '{',
              '',
              [rfReplaceAll]
            ),
            '}',
            '',
            [rfReplaceAll]
          ),
          '-',
          '',
          [rfReplaceAll]
        )
      );
  end;

begin
  CreateGUID(G1);
  CreateGUID(G2);

  Result :=
    LimparGuid(G1) +
    LimparGuid(G2);
end;

class function TInstituicaoParticipanteAcessoService.MontarMensagemAcesso(
  const AParticipante: TParticipanteBaseAcesso;
  const AUsuarioJaTinhaSenha: Boolean;
  const ALink: string
): string;
begin
  Result :=
    'Olá, ' +
    AParticipante.Nome +
    '.' + sLineBreak + sLineBreak +
    'Seu acesso ao portal de capacitações da ' +
    AParticipante.InstituicaoNome +
    ' foi liberado.' + sLineBreak + sLineBreak +
    'Usuário: ' +
    AParticipante.Email +
    sLineBreak;

  if AUsuarioJaTinhaSenha then
    Result :=
      Result +
      'Você já possui uma conta na plataforma. Utilize sua senha atual para acessar:' +
      sLineBreak +
      ALink
  else
    Result :=
      Result +
      'Para criar sua senha de acesso, utilize o link abaixo. ' +
      'O link é pessoal, de uso único e válido por 24 horas:' +
      sLineBreak +
      ALink;

  Result :=
    Result +
    sLineBreak + sLineBreak +
    'Por segurança, não compartilhe este link com outras pessoas.';
end;

class function TInstituicaoParticipanteAcessoService.Consultar(
  const AIdInstituicao,
        AIdParticipante: Int64
): TParticipanteAcessoInfo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest(
      'Participante inválido.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Result :=
      TInstituicaoParticipanteAcessoDAO.BuscarInfo(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Participante não encontrado.'
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoService.Liberar(
  const AIdInstituicao,
        AIdParticipante: Int64
): TParticipanteAcessoInfo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Participante: TParticipanteBaseAcesso;
  Usuario: TUsuarioGlobalAcesso;
  EmailNormalizado: string;
  IdUsuario: Int64;
  IdUsuarioInstituicao: Int64;
  Token: string;
  Link: string;
  Mensagem: string;
  UsuarioJaTinhaSenha: Boolean;
  PrimeiroAcessoNecessario: Boolean;
begin
  Result := nil;
  Token := '';
  Link := '';
  UsuarioJaTinhaSenha := False;
  PrimeiroAcessoNecessario := False;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest(
      'Participante inválido.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Participante :=
      TInstituicaoParticipanteAcessoDAO.BuscarParticipante(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    if not Participante.Encontrado then
      TAppErrors.RaiseBadRequest(
        'Participante não encontrado.'
      );

    if not SameText(
      Participante.Situacao,
      'ATIVO'
    ) then
      TAppErrors.RaiseBadRequest(
        'Somente participante ativo pode receber acesso ao portal.'
      );

    if Trim(Participante.Email).IsEmpty then
      TAppErrors.RaiseBadRequest(
        'Informe um e-mail no cadastro do participante antes de liberar o acesso.'
      );

    if Participante.TemUsuarioInstituicao then
      Exit(
        TInstituicaoParticipanteAcessoDAO.BuscarInfo(
          Conn,
          AIdInstituicao,
          AIdParticipante
        )
      );

    EmailNormalizado :=
      LowerCase(
        Trim(Participante.Email)
      );

    Conn.StartTransaction;
    try
      Usuario :=
        TInstituicaoParticipanteAcessoDAO.BuscarUsuarioPorEmail(
          Conn,
          EmailNormalizado
        );

      if Usuario.Encontrado then
      begin
        if not SameText(
          Usuario.Situacao,
          'ATIVO'
        ) then
          TAppErrors.RaiseBadRequest(
            'Já existe uma conta global para este e-mail, porém ela não está ativa.'
          );

        IdUsuario :=
          Usuario.IdUsuario;

        UsuarioJaTinhaSenha :=
          Usuario.TemSenhaDefinida;
      end
      else
      begin
        Token :=
          GerarTokenSeguro;

        IdUsuario :=
          TInstituicaoParticipanteAcessoDAO.CriarUsuario(
            Conn,
            Participante.Nome,
            Trim(Participante.Email),
            EmailNormalizado,
            HashSenha(
              GerarTokenSeguro
            )
          );

        UsuarioJaTinhaSenha := False;
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

      PrimeiroAcessoNecessario :=
        not UsuarioJaTinhaSenha;

      if PrimeiroAcessoNecessario then
      begin
        if Token.IsEmpty then
          Token :=
            GerarTokenSeguro;

        TInstituicaoParticipanteAcessoDAO.RevogarTokensSenha(
          Conn,
          IdUsuario
        );

        TInstituicaoParticipanteAcessoDAO.CriarTokenSenha(
          Conn,
          IdUsuario,
          Token,
          24
        );
      end;

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Result :=
      TInstituicaoParticipanteAcessoDAO.BuscarInfo(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Não foi possível carregar o acesso liberado.'
      );

    Result.PrimeiroAcessoNecessario :=
      PrimeiroAcessoNecessario;

    if PrimeiroAcessoNecessario then
      Link :=
        Config.Web.PublicURL +
        '/' +
        Participante.InstituicaoSlug +
        '/primeiro-acesso#token=' +
        Token
    else
      Link :=
        Config.Web.PublicURL +
        '/' +
        Participante.InstituicaoSlug +
        '/login';

    Mensagem :=
      MontarMensagemAcesso(
        Participante,
        UsuarioJaTinhaSenha,
        Link
      );

    if Trim(Participante.Telefone).IsEmpty then
    begin
      Result.ConviteWhatsAppEnviado := False;
      Result.ConviteMensagem :=
        'Acesso liberado, mas a mensagem não foi enviada porque o participante não possui telefone cadastrado.';
      Exit;
    end;

    try
      TInstituicaoWhatsAppService.EnviarMensagemSistema(
        AIdInstituicao,
        Participante.Telefone,
        Mensagem
      );

      Result.ConviteWhatsAppEnviado := True;

      if PrimeiroAcessoNecessario then
        Result.ConviteMensagem :=
          'Acesso liberado e convite para criação da senha enviado pelo WhatsApp.'
      else
        Result.ConviteMensagem :=
          'Acesso liberado e dados de acesso enviados pelo WhatsApp.';
    except
      on E: Exception do
      begin
        Result.ConviteWhatsAppEnviado := False;
        Result.ConviteMensagem :=
          'Acesso liberado, porém não foi possível enviar a mensagem pelo WhatsApp: ' +
          E.Message;
      end;
    end;
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
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest(
      'Participante inválido.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Participante :=
      TInstituicaoParticipanteAcessoDAO.BuscarParticipante(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    if not Participante.Encontrado then
      TAppErrors.RaiseBadRequest(
        'Participante não encontrado.'
      );

    if Participante.TemUsuarioInstituicao then
      TInstituicaoParticipanteAcessoDAO.RevogarVinculo(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    Result :=
      TInstituicaoParticipanteAcessoDAO.BuscarInfo(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );
  finally
    Conn.Free;
  end;
end;

end.
