unit EleicaoAPIPublic.Service;

interface

uses
  System.JSON, WhatsApp.Service,
  EleicaoAuditoriaAPI.Service,
  EleicaoRateLimitAPI.Service,
  WhatsAppConfigAPI.Dao,
  WhatsAppConfigAPI.Service;

type
  TLoginResult = record
    Token: string;
    identificado: String;
    nome:string;
end;

  TSolicitarCodigoResult = record
    Enviado: string;
    Destino: string;
    ExpiraEmSegundos: Integer;
    ReenviarEmSegundos: Integer;
  end;
  TValidarCodigoResult = record
    Confirmado: string;
    TokenVotacao: string;
  end;


type
  TEleicaoAPIPublicService = class
  private
    class function NormalizarSlug(const ASlug: string): string; static;

    {$REGION 'Confirmacao 2 etapas'}
      class function GerarCodigoConfirmacao: string; static;
      class function GerarHashCodigo(const ACodigo: string): string; static;
      class function MascararWhatsapp(const AWhatsapp: string): string; static;
      class function SomenteNumeros(const AValor: string): string; static;
    {$ENDREGION}

    {$REGION 'Whatsapp'}

    {$ENDREGION}

  public
    class function BuscarEleicaoPorSlug(const ASlug: string): TJSONObject; static;
    class function Login(const Slug, ACPF: string; const AMatricula: string; const AIP, AUserAgent:string): TLoginResult;

    {$REGION 'Confirmacao 2 etapas'}
      class function SolicitarCodigoConfirmacao(const ASlug: string;const AIdUsuario: Integer;
                                    const AIdEmpresa: Integer; const AIP, AUserAgent: string): TSolicitarCodigoResult; static;
      class function ValidarCodigoConfirmacao(const ASlug: string;const AIdUsuario: Integer;
                                    const AIdEmpresa: Integer; const ACodigo: string;
                                    const AIP, AUserAgent: string
                                    ): TValidarCodigoResult; static;
    {$ENDREGION}

    class function BuscarCedulaVotacao(const ASlug: string;const AIdUsuario: Integer;const AIdEmpresa: Integer): TJSONObject; static;
  end;

Var
  MsgWhatsApp: string;
  WhatsConfig: TWhatsAppConfigDados;
implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Hash,
  Uni,
  App.Config,
  Auth.Passwords,
  APP.Errors,
  Database.Connection,
  EleicaoAPIPublic,
  EleicaoLoginAPI.Dao,
  EleicaoHorarioAPI.Service,
  EleicaoVotacaoAPI.Dao,
  App.JWT;

{ TEleicaoAPIPublicService }

{$REGION 'Funcoes'}

class function TEleicaoAPIPublicService.SomenteNumeros(const AValor: string): string;
var
  C: Char;
begin
  Result := '';

  for C in AValor do
  begin
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
  end;
end;

{$ENDREGION}

class function TEleicaoAPIPublicService.BuscarEleicaoPorSlug(const ASlug: string): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
begin
  Result := nil;

  Slug := NormalizarSlug(ASlug);

  if Slug.Trim.IsEmpty then
    TAppErrors.RaiseBadRequest('Slug não informado.');

  Config  := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn    := TDatabaseConnection.NewConnection(Config.Database);

  try
    Result    := TEleicaoAPIPublicDao.BuscarEleicaoPorSlug(Conn, Slug);

    if Result = nil then
      TAppErrors.RaiseNotFound('Empresa não encontrado ou indisponível.');
  finally
    Conn.Free;
  end;
end;

class function TEleicaoAPIPublicService.NormalizarSlug(const ASlug: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(ASlug));

  S := StringReplace(S, ' ', '-', [rfReplaceAll]);
  S := StringReplace(S, '_', '-', [rfReplaceAll]);
  S := StringReplace(S, '.', '-', [rfReplaceAll]);
  S := StringReplace(S, '/', '-', [rfReplaceAll]);
  S := StringReplace(S, '\', '-', [rfReplaceAll]);

  while Pos('--', S) > 0 do
    S := StringReplace(S, '--', '-', [rfReplaceAll]);

  if S.StartsWith('-') then
    Delete(S, 1, 1);

  if S.EndsWith('-') then
    Delete(S, Length(S), 1);

  Result := S;
end;

//class function TEleicaoAPIPublicService.Login(const Slug, ACPF, AMatricula: string; const AIP, AUserAgent:string): TLoginResult;
//var
//  Config      : TAppApiConfig;
//  Conn        : TUniConnection;
//  IDEmpresa   : Integer;
//  Matricula   : Integer;
//  AIDEleicao  : integer;
//  UsuarioLogin: TEleicaoUsuarioLoginDTO;
//  SlugNormalizado: string;
//  Roles: TArray<string>;
//begin
//  Result.Token        := '';
//  Result.Identificado := '';
//  Result.Nome         := '';
//  SlugNormalizado     := NormalizarSlug(Slug);
//
//  if SlugNormalizado.IsEmpty then
//  TAppErrors.RaiseBadRequest('Não foi possível validar os dados informados.');
//
//  if Trim(ACPF).IsEmpty then
//    TAppErrors.RaiseBadRequest('Informe o CPF.');
//
//  if Trim(AMatricula).IsEmpty then
//    TAppErrors.RaiseBadRequest('Informe sua matrícula.');
//
//  if not TryStrToInt(Trim(AMatricula), Matricula) then
//    TAppErrors.RaiseBadRequest('Não foi possível validar os dados informados.');
//
//  Config  := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
//  Conn    := TDatabaseConnection.NewConnection(Config.Database);
//
//  try
//    // Identifica a empresa através do slug publicado
//    IDEmpresa       := TEleicaoLoginAPIDao.BuscarSlugID(Conn, SlugNormalizado, AIDEleicao);
//
//    if IDEmpresa <= 0 then
//      TAppErrors.RaiseBadRequest('Não foi possível validar os dados informados.');
//
//    if AIDEleicao <=0 then
//      TAppErrors.RaiseBadRequest('Não foi possível validar os dados informados.');
//
//    //Validar periodo da votacao
//    TEleicaoHorarioAPIService.ValidarPeriodoVotacao(Conn, SlugNormalizado,IDEmpresa);
//
//    //validar tentativa
//    TEleicaoRateLimitAPIService.VerificarLogin(
//                                IDEmpresa,
//                                AIDEleicao,
//                                SlugNormalizado,
//                                ACPF,
//                                AMatricula
//                              );
//
//
//    // Valida CPF + matrícula + pessoa ativa + usuário ativo
//    if not TEleicaoLoginAPIDao.BuscarUsuarioAtivo(Conn,IDEmpresa,Trim(ACPF),Matricula, UsuarioLogin) then
//    begin
//      //auditoria
//      TEleicaoAuditoriaAPIService.RegistrarEvento(
//                Conn, IDEmpresa, AIDEleicao, 0,
//                AUDITORIA_LOGIN_FALHA, AUDITORIA_ORIGEM_ELEITOR, False, 'Falha na identificação do eleitor.',AIP, AUserAgent);
//
//      TAppErrors.RaiseUnauthorized('Não foi possível validar os dados informados.');
//    end;
//
//    SetLength(Roles, 1);
//    Roles[0] := 'ELEITOR_IDENTIFICADO';
//
//    Result.Identificado := 'S';
//    Result.Nome         := UsuarioLogin.Nome;
//
//    // Validar se ja votou
//    if TEleicaoVotacaoAPIDao.EleitorJaVotou(Conn, AIDEleicao, UsuarioLogin.IdUsuario) then
//    begin
//      // Auditoria login
//      TEleicaoAuditoriaAPIService.RegistrarEvento(
//        Conn, IDEmpresa, AIDEleicao, UsuarioLogin.IdUsuario,
//        AUDITORIA_LOGIN_SUCESSO, AUDITORIA_ORIGEM_ELEITOR, True,
//        'Eleitor identificado com sucesso.',AIP, AUserAgent);
//
//      TAppErrors.RaiseBadRequest('Seu voto já foi registrado nesta eleição.');
//    end;
//
//    Result.Token := TAppJWT.GerarToken(
//                    Config.JWT,
//                    UsuarioLogin.IdUsuario,
//                    UsuarioLogin.IdEmpresa,
//                    Roles,
//                    SlugNormalizado,
//                    Config.JWT.TtlIdentificacaoMinutos);
//
//
//
//  finally
//    Conn.Free;
//  end;
//end;

class function TEleicaoAPIPublicService.Login(const Slug, ACPF, AMatricula: string; const AIP, AUserAgent: string): TLoginResult;
var
  Config         : TAppApiConfig;
  Conn           : TUniConnection;
  IDEmpresa      : Integer;
  Matricula      : Integer;
  AIDEleicao     : Integer;
  UsuarioLogin   : TEleicaoUsuarioLoginDTO;
  SlugNormalizado: string;
  Roles          : TArray<string>;
begin
  Result.Token        := '';
  Result.Identificado := '';
  Result.Nome         := '';

  SlugNormalizado := NormalizarSlug(Slug);

  if SlugNormalizado.IsEmpty then
    TAppErrors.RaiseBadRequest('Não foi possível validar os dados informados.');

  if Trim(ACPF).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o CPF.');

  if Trim(AMatricula).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe sua matrícula.');

  if not TryStrToInt(Trim(AMatricula), Matricula) then
    TAppErrors.RaiseBadRequest('Não foi possível validar os dados informados.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    // Identifica empresa e eleição através do slug publicado
    IDEmpresa := TEleicaoLoginAPIDao.BuscarSlugID(Conn, SlugNormalizado, AIDEleicao);

    if (IDEmpresa <= 0) or (AIDEleicao <= 0) then
      TAppErrors.RaiseBadRequest('Não foi possível validar os dados informados.');

    // Valida período da votação
    TEleicaoHorarioAPIService.ValidarPeriodoVotacao(Conn, SlugNormalizado, IDEmpresa);

    // Verifica se esta identificação está bloqueada por excesso de tentativas
    TEleicaoRateLimitAPIService.VerificarLogin(
      IDEmpresa,
      AIDEleicao,
      SlugNormalizado,
      ACPF,
      AMatricula
    );

    // Valida CPF + matrícula + pessoa ativa + usuário ativo
    if not TEleicaoLoginAPIDao.BuscarUsuarioAtivo(Conn, IDEmpresa, Trim(ACPF), Matricula, UsuarioLogin) then
    begin
      TEleicaoRateLimitAPIService.RegistrarFalhaLogin(
        IDEmpresa,
        AIDEleicao,
        SlugNormalizado,
        ACPF,
        AMatricula
      );

      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn, IDEmpresa, AIDEleicao, 0,
        AUDITORIA_LOGIN_FALHA, AUDITORIA_ORIGEM_ELEITOR, False,
        'Falha na identificação do eleitor.', AIP, AUserAgent
      );

      TAppErrors.RaiseUnauthorized('Não foi possível validar os dados informados.');
    end;

    // CPF + matrícula corretos: limpa tentativas anteriores
    TEleicaoRateLimitAPIService.RegistrarSucessoLogin(
      IDEmpresa,
      AIDEleicao,
      SlugNormalizado,
      ACPF,
      AMatricula
    );

    // A identificação foi realizada corretamente
    TEleicaoAuditoriaAPIService.RegistrarEvento(
      Conn, IDEmpresa, AIDEleicao, UsuarioLogin.IdUsuario,
      AUDITORIA_LOGIN_SUCESSO, AUDITORIA_ORIGEM_ELEITOR, True,
      'Eleitor identificado com sucesso.', AIP, AUserAgent
    );

    // Mesmo com identificação válida, não permite novo fluxo se já votou
    if TEleicaoVotacaoAPIDao.EleitorJaVotou(Conn, AIDEleicao, UsuarioLogin.IdUsuario) then
      TAppErrors.RaiseBadRequest('Seu voto já foi registrado nesta eleição.');

    SetLength(Roles, 1);
    Roles[0] := 'ELEITOR_IDENTIFICADO';

    Result.Identificado := 'S';
    Result.Nome := UsuarioLogin.Nome;

    Result.Token := TAppJWT.GerarToken(
      Config.JWT,
      UsuarioLogin.IdUsuario,
      UsuarioLogin.IdEmpresa,
      Roles,
      SlugNormalizado,
      Config.JWT.TtlIdentificacaoMinutos
    );

  finally
    Conn.Free;
  end;
end;

{$REGION 'Confirmacao 2 etapas'}

class function TEleicaoAPIPublicService.GerarCodigoConfirmacao: string;
var
  Guid: TGUID;
  Hash: string;
  Numero: Integer;
begin
  CreateGUID(Guid);

  Hash := THashSHA2.GetHashString(
    GUIDToString(Guid),
    SHA256
  );

  Numero := StrToInt(
    '$' + Copy(Hash, 1, 7)
  );

  Numero := 100000 + (Numero mod 900000);

  Result := Format('%.6d', [Numero]);
end;

class function TEleicaoAPIPublicService.GerarHashCodigo(const ACodigo: string): string;
begin
  Result := THashSHA2.GetHashString(Trim(ACodigo),SHA256);
end;

class function TEleicaoAPIPublicService.MascararWhatsapp(const AWhatsapp: string): string;
var
  Numero: string;
begin
  Numero := SomenteNumeros(AWhatsapp);

  if Length(Numero) < 4 then
  begin
    Result := 'WhatsApp cadastrado';
    Exit;
  end;

  Result :=
    '(**) *****-' +
    Copy(
      Numero,
      Length(Numero) - 3,
      4
    );
end;

class function TEleicaoAPIPublicService.SolicitarCodigoConfirmacao(const ASlug: string;
  const AIdUsuario: Integer; const AIdEmpresa: Integer; const AIP, AUserAgent: string): TSolicitarCodigoResult;
const
  TEMPO_EXPIRACAO_SEGUNDOS = 60; // 1 minuto
  TEMPO_REENVIO_SEGUNDOS   = 60;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;

  Slug: string;
  Codigo: string;
  CodigoHash: string;

  Contexto: TEleicaoConfirmacaoContexto;
  Confirmacao: TEleicaoConfirmacao;

  SegundosDesdeEnvio: Integer;
  SegundosExpiracao: Integer;
  SegundosReenvio: Integer;

begin
  Result.Enviado             := '';
  Result.Destino             := '';
  Result.ExpiraEmSegundos    := 0;
  Result.ReenviarEmSegundos  := 0;

  Slug := NormalizarSlug(ASlug);

  if Slug.IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if AIdUsuario <= 0 then
    TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try

    TEleicaoHorarioAPIService.ValidarPeriodoVotacao(Conn, Slug, AIdEmpresa);

    //
    // 1. Validar todo o contexto:
    //
    // slug
    // empresa
    // eleição ABERTA
    // usuário ativo
    // pessoa ativa
    //
    if not TEleicaoAPIPublicDao.BuscarContextoConfirmacao(Conn, Slug, AIdEmpresa, AIdUsuario, Contexto) then
      TAppErrors.RaiseUnauthorized('Não foi possível iniciar a confirmação.');

    // 2. Precisa possuir WhatsApp
    //
    if SomenteNumeros(Contexto.Whatsapp).IsEmpty then
      TAppErrors.RaiseBadRequest('Não foi possível enviar o código de confirmação.');

    // 3. Verificar se já existe confirmação
    if TEleicaoAPIPublicDao.BuscarConfirmacao(Conn, Contexto.IdEleicao, Contexto.IdUsuario, Confirmacao) then
    begin
      // Já confirmou anteriormente.
      //
      if SameText(Trim(Confirmacao.Confirmado),'S') then
        TAppErrors.RaiseBadRequest('A confirmação já foi realizada.');

      // Se já houve envio recente, NÃO gerar outro.

      if Confirmacao.EnviadoEm > 0 then
      begin
        SegundosDesdeEnvio := SecondsBetween(Now, Confirmacao.EnviadoEm);

        if SegundosDesdeEnvio < TEMPO_REENVIO_SEGUNDOS then
        begin
          SegundosReenvio :=
            TEMPO_REENVIO_SEGUNDOS -
            SegundosDesdeEnvio;

          SegundosExpiracao := 0;

          if Confirmacao.ExpiraEm > Now then
            SegundosExpiracao :=
              SecondsBetween(
                Now,
                Confirmacao.ExpiraEm
              );

          Result.Enviado :=
            'S';

          Result.Destino :=
            MascararWhatsapp(
              Contexto.Whatsapp
            );

          Result.ExpiraEmSegundos :=
            SegundosExpiracao;

          Result.ReenviarEmSegundos :=
            SegundosReenvio;

          Exit;
        end;
      end;
    end;

    // verificar envio
    TEleicaoRateLimitAPIService.VerificarEnvioCodigo(Contexto.IdEmpresa, Contexto.IdEleicao, Contexto.IdUsuario, Slug);

    // 4. Gerar novo código
    Codigo      := GerarCodigoConfirmacao;
    CodigoHash  := GerarHashCodigo(Codigo);
    Writeln('CODIGO ELEICAO TESTE: ' + Codigo);

    // 5. Salvar código antes do envio.
    TEleicaoAPIPublicDao.SalvarCodigoConfirmacao(Conn, Contexto.IdEmpresa, Contexto.IdEleicao, Contexto.IdUsuario, CodigoHash);

    //
    // =====================================================
    // 6. AQUI ENTRARÁ SUA API WHATSAPP
    // =====================================================

    WhatsConfig     := TWhatsAppConfigAPIService.BuscarConfiguracao(Contexto.IdEmpresa);

    if not TWhatsAppService.EnviarCodigoConfirmacao(
                    WhatsConfig.URL,
                    WhatsConfig.Instancia,
                    WhatsConfig.Token,
                    Contexto.Whatsapp,
                    Contexto.Nome,
                    Codigo,
                    MsgWhatsApp
                  ) then
                    TAppErrors.RaiseBadRequest('Não foi possível enviar o código de confirmação. ' + MsgWhatsApp);

    // Somente considera enviado depois que o WhatsApp respondeu sucesso.
    TEleicaoAPIPublicDao.RegistrarEnvioCodigo(
      Conn,
      Contexto.IdEleicao,
      Contexto.IdUsuario
    );

    //registro de tentativa
    TEleicaoRateLimitAPIService.RegistrarEnvioCodigo(
                        Contexto.IdEmpresa,
                        Contexto.IdEleicao,
                        Contexto.IdUsuario,
                        Slug
                      );

    //Auditoria
    TEleicaoAuditoriaAPIService.RegistrarEvento(
      Conn, Contexto.IdEmpresa, Contexto.IdEleicao, Contexto.IdUsuario,
      AUDITORIA_CODIGO_ENVIADO, AUDITORIA_ORIGEM_ELEITOR, True,
      'Código de confirmação enviado.',AIP, AUserAgent);

    Result.Enviado            := 'S';
    Result.Destino            := MascararWhatsapp(Contexto.Whatsapp);
    Result.ExpiraEmSegundos   := TEMPO_EXPIRACAO_SEGUNDOS;
    Result.ReenviarEmSegundos := TEMPO_REENVIO_SEGUNDOS;


    //
    // O retorno também deve acontecer somente após
    // confirmação de sucesso da API WhatsApp.
    //

  finally
    Conn.Free;
  end;
end;

class function TEleicaoAPIPublicService.ValidarCodigoConfirmacao(const ASlug: string;
  const AIdUsuario: Integer; const AIdEmpresa: Integer; const ACodigo: string; const AIP, AUserAgent: string): TValidarCodigoResult;
const
  MAX_TENTATIVAS = 5;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;

  Slug: string;
  Codigo: string;
  CodigoHash: string;

  Contexto: TEleicaoConfirmacaoContexto;
  Confirmacao: TEleicaoConfirmacao;

  Roles: TArray<string>;
begin
  Result.Confirmado  := '';
  Result.TokenVotacao := '';

  Slug :=
    NormalizarSlug(ASlug);

  Codigo :=
    SomenteNumeros(ACodigo);

  if Slug.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Eleição não informada.'
    );

  if AIdUsuario <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Identificação inválida ou expirada.'
    );

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Identificação inválida ou expirada.'
    );

  if Length(Codigo) <> 6 then
    TAppErrors.RaiseBadRequest(
      'Código inválido ou expirado.'
    );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    TEleicaoHorarioAPIService.ValidarPeriodoVotacao(Conn, Slug, AIdEmpresa);

    //
    // 1. Validar contexto novamente
    //
    if not TEleicaoAPIPublicDao.BuscarContextoConfirmacao(
      Conn,
      Slug,
      AIdEmpresa,
      AIdUsuario,
      Contexto
    ) then
      TAppErrors.RaiseUnauthorized(
        'Código inválido ou expirado.'
      );

    //tentativa
    TEleicaoRateLimitAPIService.VerificarValidacaoCodigo(
                        Contexto.IdEmpresa,
                        Contexto.IdEleicao,
                        Contexto.IdUsuario,
                        Slug
                      );

    //
    // 2. Buscar confirmação
    //
    if not TEleicaoAPIPublicDao.BuscarConfirmacao(Conn, Contexto.IdEleicao, Contexto.IdUsuario, Confirmacao) then
      TAppErrors.RaiseBadRequest('Código inválido ou expirado.');

    //
    // 3. Já utilizado
    //
    if SameText(Trim(Confirmacao.Confirmado),'S') then
      TAppErrors.RaiseBadRequest(
        'Código inválido ou expirado.'
      );

    //
    // 4. Código nunca foi enviado
    //
    if Confirmacao.EnviadoEm <= 0 then
      TAppErrors.RaiseBadRequest('Código inválido ou expirado.');

    //
    // 5. Expirado
    //
    if Confirmacao.ExpiraEm <= Now then
      TAppErrors.RaiseBadRequest('Código inválido ou expirado.');

    //
    // 6. Tentativas excedidas
    //
    if Confirmacao.Tentativas >= MAX_TENTATIVAS then
      TAppErrors.RaiseBadRequest(
        'Código inválido ou expirado.'
      );

    //
    // 7. Comparar hash
    //
    CodigoHash :=
      GerarHashCodigo(Codigo);

    if not SameText(
      CodigoHash,
      Confirmacao.CodigoHash
    ) then
    begin

      TEleicaoAPIPublicDao.IncrementarTentativa(
        Conn,
        Confirmacao.Id
      );

      //falha de login
      TEleicaoRateLimitAPIService.RegistrarFalhaValidacaoCodigo(
                              Contexto.IdEmpresa,
                              Contexto.IdEleicao,
                              Contexto.IdUsuario,
                              Slug
                            );

      //auditoria
      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn, Contexto.IdEmpresa, Contexto.IdEleicao, Contexto.IdUsuario,
        AUDITORIA_CODIGO_INVALIDO, AUDITORIA_ORIGEM_ELEITOR, False,
        'Código de confirmação inválido.',AIP, AUserAgent);

      TAppErrors.RaiseBadRequest(
        'Código inválido ou expirado.'
      );
    end;

    //
    // 8. Código correto
    //
    TEleicaoAPIPublicDao.ConfirmarCodigo(
      Conn,
      Confirmacao.Id
    );

    //auditoria
    TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn, Contexto.IdEmpresa, Contexto.IdEleicao, Contexto.IdUsuario,
        AUDITORIA_CODIGO_VALIDADO, AUDITORIA_ORIGEM_ELEITOR, True,
        'Código de confirmação validado com sucesso.',AIP, AUserAgent);


    //
    // 9. Gerar token específico para votação
    //
    SetLength(Roles, 1);
    Roles[0] := 'ELEITOR_VOTACAO';

//    Result.TokenVotacao :=
//    TAppJWT.GerarToken(
//      Config.JWT,
//      Contexto.IdUsuario,
//      Contexto.IdEmpresa,
//      Roles,
//      Slug
//    );

      Result.TokenVotacao := TAppJWT.GerarToken(
                              Config.JWT,
                              Contexto.IdUsuario,
                              Contexto.IdEmpresa,
                              Roles,
                              Slug,
                              Config.JWT.TtlVotacaoMinutos);

    Result.Confirmado := 'S';

  finally
    Conn.Free;
  end;
end;



{$ENDREGION}

class function TEleicaoAPIPublicService.BuscarCedulaVotacao(const ASlug: string;
                const AIdUsuario: Integer; const AIdEmpresa: Integer): TJSONObject;
var
  Config   : TAppApiConfig;
  Conn     : TUniConnection;
  Slug     : string;
  Contexto : TEleicaoConfirmacaoContexto;
begin
  Result := nil;
  // 1. Normalizar e validar slug
  Slug := NormalizarSlug(ASlug);

  if Slug.IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  // 2. Validar dados vindos do token_votacao
  if AIdUsuario <= 0 then
    TAppErrors.RaiseUnauthorized('Acesso à votação não autorizado.');

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Acesso à votação não autorizado.');

  // 3. Conexão
  Config      := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try

    TEleicaoHorarioAPIService.ValidarPeriodoVotacao(Conn, Slug, AIdEmpresa);

    //
    // 4. Validar contexto novamente.
    //
    // Aqui garantimos:
    //
    // - slug publicado
    // - empresa do token = empresa do slug
    // - eleição ativa
    // - eleição ABERTA
    // - usuário ativo
    // - pessoa ativa
    //
    if not TEleicaoAPIPublicDao.BuscarContextoConfirmacao(Conn,Slug, AIdEmpresa,
                                                      AIdUsuario, Contexto) then
      TAppErrors.RaiseUnauthorized('Não foi possível acessar esta votação.');

    // 6. Verifica se ja votou
    if TEleicaoVotacaoAPIDao.EleitorJaVotou(Conn, Contexto.IdEleicao,AIdUsuario) then
    begin
      TAppErrors.RaiseBadRequest('Seu voto já foi registrado nesta eleição.');
    end;

    // 5. Carregar cédula
    Result :=   TEleicaoAPIPublicDao.BuscarCedulaVotacao(Conn,  Slug, AIdEmpresa);

    if Result = nil then
      TAppErrors.RaiseNotFound('Não foi possível carregar os dados da votação.');

  finally
    Conn.Free;
  end;
end;



end.
