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
      const ALink,
            AHomeLink: string
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

    class function ReenviarConvite(
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
  const ALink,
        AHomeLink: string
): string;
var
  EmojiOla: string;
  EmojiAcesso: string;
  EmojiUsuario: string;
  EmojiSenha: string;
  EmojiLink: string;
  EmojiHome: string;
  EmojiSeguranca: string;
  Ola: string;
  Acesso: string;
  UsuarioLabel: string;
  Instrucao: string;
  LinkLabel: string;
  HomeLabel: string;
  Seguranca: string;
begin
  EmojiOla       := #$D83D#$DC4B;
  EmojiAcesso    := #$2705;
  EmojiUsuario   := #$D83D#$DCE7;
  EmojiSenha     := #$D83D#$DD10;
  EmojiLink      := #$D83D#$DD17;
  EmojiHome      := #$D83C#$DFE0;
  EmojiSeguranca := #$D83D#$DD12;

  Ola :=
    EmojiOla + ' Ol' + #$00E1 + ', ' +
    AParticipante.Nome + '.';

  Acesso :=
    EmojiAcesso +
    ' Seu acesso ao portal de capacita' + #$00E7 + #$00F5 + 'es da ' +
    AParticipante.InstituicaoNome +
    ' foi liberado.';

  UsuarioLabel :=
    EmojiUsuario +
    ' Usu' + #$00E1 + 'rio: ' +
    AParticipante.Email;

  if AUsuarioJaTinhaSenha then
  begin
    Instrucao :=
      EmojiSenha +
      ' Voc' + #$00EA +
      ' j' + #$00E1 +
      ' possui uma conta na plataforma. Utilize sua senha atual para acessar.';

    LinkLabel :=
      EmojiLink +
      ' Acessar o portal:';
  end
  else
  begin
    Instrucao :=
      EmojiSenha +
      ' Para criar sua senha de acesso, utilize o link abaixo. ' +
      'Ele ' + #$00E9 +
      ' pessoal, de uso ' + #$00FA + 'nico e v' + #$00E1 +
      'lido por 24 horas.';

    LinkLabel :=
      EmojiLink +
      ' Criar minha senha:';
  end;

  HomeLabel :=
    EmojiHome +
    ' P' + #$00E1 +
    'gina principal da institui' + #$00E7 + #$00E3 + 'o:';

  Seguranca :=
    EmojiSeguranca +
    ' Por seguran' + #$00E7 +
    'a, n' + #$00E3 +
    'o compartilhe o link de cria' + #$00E7 + #$00E3 +
    'o de senha com outras pessoas.';

  Result :=
    Ola + sLineBreak + sLineBreak +
    Acesso + sLineBreak + sLineBreak +
    UsuarioLabel + sLineBreak + sLineBreak +
    Instrucao + sLineBreak + sLineBreak +
    LinkLabel + sLineBreak +
    ALink + sLineBreak + sLineBreak +
    HomeLabel + sLineBreak +
    AHomeLink + sLineBreak + sLineBreak +
    Seguranca;
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
  HomeLink: string;
  Mensagem: string;
  UsuarioJaTinhaSenha: Boolean;
  PrimeiroAcessoNecessario: Boolean;
  VinculoJaExistia: Boolean;
  VinculoAdministrativo: Boolean;
begin
  Result := nil;
  Token := '';
  Link := '';
  HomeLink := '';
  UsuarioJaTinhaSenha := False;
  PrimeiroAcessoNecessario := False;
  VinculoJaExistia := False;
  VinculoAdministrativo := False;

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

      VinculoJaExistia :=
        IdUsuarioInstituicao > 0;

      if VinculoJaExistia then
        VinculoAdministrativo :=
          TInstituicaoParticipanteAcessoDAO.UsuarioInstituicaoEhAdministrativo(
            Conn,
            AIdInstituicao,
            IdUsuarioInstituicao
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
        (not UsuarioJaTinhaSenha) or
        (VinculoJaExistia and not VinculoAdministrativo);

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

    HomeLink :=
      Config.Web.PublicURL +
      '/' +
      Participante.InstituicaoSlug;

    Mensagem :=
      MontarMensagemAcesso(
        Participante,
        not PrimeiroAcessoNecessario,
        Link,
        HomeLink
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
          'Acesso liberado e convite para cria' + #$00E7 + #$00E3 +
          'o da senha enviado pelo WhatsApp.'
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

class function TInstituicaoParticipanteAcessoService.ReenviarConvite(
  const AIdInstituicao,
        AIdParticipante: Int64
): TParticipanteAcessoInfo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Participante: TParticipanteBaseAcesso;
  Usuario: TUsuarioGlobalAcesso;
  Token: string;
  Link: string;
  HomeLink: string;
  Mensagem: string;
  PrimeiroAcessoNecessario: Boolean;
begin
  Result := nil;
  Token := '';
  Link := '';
  HomeLink := '';

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Institui' + #$00E7 + #$00E3 + 'o n' + #$00E3 + 'o identificada.'
    );

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest(
      'Participante inv' + #$00E1 + 'lido.'
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
        'Participante n' + #$00E3 + 'o encontrado.'
      );

    if not Participante.TemUsuarioInstituicao then
      TAppErrors.RaiseBadRequest(
        'O acesso do participante ainda n' + #$00E3 + 'o foi liberado.'
      );

    if Trim(Participante.Telefone).IsEmpty then
      TAppErrors.RaiseBadRequest(
        'Informe um telefone no cadastro do participante antes de reenviar o convite.'
      );

    Usuario :=
      TInstituicaoParticipanteAcessoDAO.BuscarUsuarioVinculado(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    if not Usuario.Encontrado then
      TAppErrors.RaiseBadRequest(
        'Usu' + #$00E1 + 'rio vinculado ao participante n' + #$00E3 + 'o encontrado.'
      );

    if not SameText(
      Usuario.Situacao,
      'ATIVO'
    ) then
      TAppErrors.RaiseBadRequest(
        'O usu' + #$00E1 + 'rio vinculado n' + #$00E3 + 'o est' + #$00E1 + ' ativo.'
      );

    PrimeiroAcessoNecessario :=
      (not Usuario.TemSenhaDefinida) or
      TInstituicaoParticipanteAcessoDAO.UsuarioPossuiTokenSenhaPendente(
        Conn,
        Usuario.IdUsuario
      );

    if PrimeiroAcessoNecessario then
    begin
      Token :=
        GerarTokenSeguro;

      Conn.StartTransaction;
      try
        TInstituicaoParticipanteAcessoDAO.RevogarTokensSenha(
          Conn,
          Usuario.IdUsuario
        );

        TInstituicaoParticipanteAcessoDAO.CriarTokenSenha(
          Conn,
          Usuario.IdUsuario,
          Token,
          24
        );

        Conn.Commit;
      except
        if Conn.InTransaction then
          Conn.Rollback;
        raise;
      end;

      Link :=
        Config.Web.PublicURL +
        '/' +
        Participante.InstituicaoSlug +
        '/primeiro-acesso#token=' +
        Token;
    end
    else
      Link :=
        Config.Web.PublicURL +
        '/' +
        Participante.InstituicaoSlug +
        '/login';

    HomeLink :=
      Config.Web.PublicURL +
      '/' +
      Participante.InstituicaoSlug;

    Mensagem :=
      MontarMensagemAcesso(
        Participante,
        not PrimeiroAcessoNecessario,
        Link,
        HomeLink
      );

    TInstituicaoWhatsAppService.EnviarMensagemSistema(
      AIdInstituicao,
      Participante.Telefone,
      Mensagem
    );

    Result :=
      TInstituicaoParticipanteAcessoDAO.BuscarInfo(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'N' + #$00E3 + 'o foi poss' + #$00ED + 'vel carregar o acesso do participante.'
      );

    Result.PrimeiroAcessoNecessario :=
      PrimeiroAcessoNecessario;
    Result.ConviteWhatsAppEnviado := True;

    if PrimeiroAcessoNecessario then
      Result.ConviteMensagem :=
        'Novo convite para cria' + #$00E7 + #$00E3 +
        'o da senha enviado pelo WhatsApp.'
    else
      Result.ConviteMensagem :=
        'Dados de acesso reenviados pelo WhatsApp.';
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
