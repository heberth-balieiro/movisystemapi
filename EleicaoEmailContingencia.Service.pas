unit EleicaoEmailContingencia.Service;

interface

type
  TEleicaoEmailContingenciaResult = record
    Enviado: string;
    Destino: string;
    ExpiraEmSegundos: Integer;
    ReenviarEmSegundos: Integer;
  end;

  TEleicaoEmailContingenciaInfo = record
    Disponivel: Boolean;
    DestinoMascarado: string;
  end;

  TEleicaoEmailContingenciaService = class
  private
    class function NormalizarSlug(const ASlug: string): string; static;
    class function BuscarEmailPessoa(const AConn: TObject; const AIdPessoa,
      AIdEmpresa: Integer): string; static;
    class function EmailValido(const AEmail: string): Boolean; static;
    class function MascararEmail(const AEmail: string): string; static;
    class function GerarCodigoConfirmacao: string; static;
    class function GerarHashCodigo(const ACodigo: string): string; static;
    class function MontarHtmlCodigo(const ANome, ACodigo: string): string; static;
  public
    class function Consultar(const ASlug: string; const AIdUsuario,
      AIdEmpresa: Integer): TEleicaoEmailContingenciaInfo; static;

    class function SolicitarCodigo(const ASlug: string; const AIdUsuario,
      AIdEmpresa: Integer; const AIP,
      AUserAgent: string): TEleicaoEmailContingenciaResult; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Hash,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  EleicaoAPIPublic,
  EleicaoHorarioAPI.Service,
  EleicaoRateLimitAPI.Service,
  EleicaoAuditoriaAPI.Service,
  EleicaoEmail.Contracts,
  EleicaoEmail.Service,
  EleicaoEmailConfigAPI.Model,
  EleicaoEmailConfigAPI.Service;

const
  TEMPO_EXPIRACAO_SEGUNDOS = 60;
  TEMPO_REENVIO_SEGUNDOS = 60;
  MINIMO_ENVIOS_WHATSAPP = 2;

class function TEleicaoEmailContingenciaService.NormalizarSlug(
  const ASlug: string): string;
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

class function TEleicaoEmailContingenciaService.BuscarEmailPessoa(
  const AConn: TObject; const AIdPessoa, AIdEmpresa: Integer): string;
var
  Conn: TUniConnection;
  Qry: TUniQuery;
begin
  Result := '';
  Conn := TUniConnection(AConn);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := Conn;
    Qry.SQL.Text :=
      'SELECT COALESCE(email, '''') AS email ' +
      'FROM pessoa ' +
      'WHERE id = :idpessoa AND empresa_id = :idempresa ' +
      'LIMIT 1';
    Qry.ParamByName('idpessoa').AsInteger := AIdPessoa;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := LowerCase(Trim(Qry.FieldByName('email').AsString));
  finally
    Qry.Free;
  end;
end;

class function TEleicaoEmailContingenciaService.EmailValido(
  const AEmail: string): Boolean;
var
  Email: string;
  P: Integer;
begin
  Email := Trim(AEmail);
  P := Pos('@', Email);
  Result := (P > 1) and (P < Length(Email) - 2) and
    (Pos('.', Copy(Email, P + 2, MaxInt)) > 0);
end;

class function TEleicaoEmailContingenciaService.MascararEmail(
  const AEmail: string): string;
var
  P: Integer;
  Local: string;
  Dominio: string;
  QtdMascara: Integer;
begin
  Result := 'E-mail cadastrado';
  P := Pos('@', Trim(AEmail));
  if P <= 1 then
    Exit;

  Local := Copy(Trim(AEmail), 1, P - 1);
  Dominio := Copy(Trim(AEmail), P, MaxInt);

  QtdMascara := Length(Local) - 1;
  if QtdMascara < 5 then
    QtdMascara := 5;

  Result := Copy(Local, 1, 1) + StringOfChar('*', QtdMascara) + Dominio;
end;

class function TEleicaoEmailContingenciaService.GerarCodigoConfirmacao: string;
var
  Guid: TGUID;
  Hash: string;
  Numero: Integer;
begin
  CreateGUID(Guid);
  Hash := THashSHA2.GetHashString(GUIDToString(Guid), SHA256);
  Numero := StrToInt('$' + Copy(Hash, 1, 7));
  Numero := 100000 + (Numero mod 900000);
  Result := Format('%.6d', [Numero]);
end;

class function TEleicaoEmailContingenciaService.GerarHashCodigo(
  const ACodigo: string): string;
begin
  Result := THashSHA2.GetHashString(Trim(ACodigo), SHA256);
end;

class function TEleicaoEmailContingenciaService.MontarHtmlCodigo(
  const ANome, ACodigo: string): string;
begin
  Result :=
    '<h2>Confirmação de identidade</h2>' +
    '<p>Olá, ' + ANome + '.</p>' +
    '<p>Seu código de confirmação para acessar a votação é:</p>' +
    '<p style="font-size:28px;font-weight:bold;letter-spacing:6px">' + ACodigo + '</p>' +
    '<p>O código é de uso único e possui validade limitada.</p>' +
    '<p>Não compartilhe este código com outras pessoas.</p>';
end;

class function TEleicaoEmailContingenciaService.Consultar(
  const ASlug: string; const AIdUsuario,
  AIdEmpresa: Integer): TEleicaoEmailContingenciaInfo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
  Contexto: TEleicaoConfirmacaoContexto;
  Confirmacao: TEleicaoConfirmacao;
  Email: string;
  EmailConfig: TEleicaoEmailConfig;
begin
  Result.Disponivel := False;
  Result.DestinoMascarado := '';

  Slug := NormalizarSlug(ASlug);
  if Slug.IsEmpty or (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
    Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TEleicaoAPIPublicDao.BuscarContextoConfirmacao(
      Conn, Slug, AIdEmpresa, AIdUsuario, Contexto
    ) then
      Exit;

    Email := BuscarEmailPessoa(Conn, Contexto.IdPessoa, Contexto.IdEmpresa);
    if not EmailValido(Email) then
      Exit;

    if not TEleicaoAPIPublicDao.BuscarConfirmacao(
      Conn, Contexto.IdEleicao, Contexto.IdUsuario, Confirmacao
    ) then
      Exit;

    if SameText(Trim(Confirmacao.Confirmado), 'S') then
      Exit;

    if Confirmacao.QuantidadeEnvios < MINIMO_ENVIOS_WHATSAPP then
      Exit;

    EmailConfig := TEleicaoEmailConfigService.Buscar(Contexto.IdEmpresa);
    if not EmailConfig.Ativo or
       EmailConfig.SmtpHost.IsEmpty or
       EmailConfig.Usuario.IsEmpty or
       not EmailConfig.SenhaConfigurada or
       EmailConfig.RemetenteEmail.IsEmpty then
      Exit;

    Result.Disponivel := True;
    Result.DestinoMascarado := MascararEmail(Email);
  finally
    Conn.Free;
  end;
end;

class function TEleicaoEmailContingenciaService.SolicitarCodigo(
  const ASlug: string; const AIdUsuario,
  AIdEmpresa: Integer; const AIP,
  AUserAgent: string): TEleicaoEmailContingenciaResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
  Contexto: TEleicaoConfirmacaoContexto;
  Confirmacao: TEleicaoConfirmacao;
  Email: string;
  Codigo: string;
  CodigoHash: string;
  SegundosDesdeEnvio: Integer;
  EmailConfig: TEleicaoEmailConfig;
  EmailService: IEmailService;
begin
  Result.Enviado := '';
  Result.Destino := '';
  Result.ExpiraEmSegundos := 0;
  Result.ReenviarEmSegundos := 0;

  Slug := NormalizarSlug(ASlug);
  if Slug.IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
    TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TEleicaoHorarioAPIService.ValidarPeriodoVotacao(Conn, Slug, AIdEmpresa);

    if not TEleicaoAPIPublicDao.BuscarContextoConfirmacao(
      Conn, Slug, AIdEmpresa, AIdUsuario, Contexto
    ) then
      TAppErrors.RaiseUnauthorized('Não foi possível iniciar a confirmação.');

    Email := BuscarEmailPessoa(Conn, Contexto.IdPessoa, Contexto.IdEmpresa);
    if not EmailValido(Email) then
      TAppErrors.RaiseBadRequest('Não há um e-mail válido cadastrado para este eleitor.');

    if not TEleicaoAPIPublicDao.BuscarConfirmacao(
      Conn, Contexto.IdEleicao, Contexto.IdUsuario, Confirmacao
    ) then
      TAppErrors.RaiseBadRequest('Solicite o código pelo WhatsApp antes de usar a contingência por e-mail.');

    if SameText(Trim(Confirmacao.Confirmado), 'S') then
      TAppErrors.RaiseBadRequest('A confirmação já foi realizada.');

    if Confirmacao.QuantidadeEnvios < MINIMO_ENVIOS_WHATSAPP then
      TAppErrors.RaiseBadRequest(
        'Reenvie o código pelo WhatsApp antes de solicitar o envio por e-mail.'
      );

    if Confirmacao.EnviadoEm > 0 then
    begin
      SegundosDesdeEnvio := SecondsBetween(Now, Confirmacao.EnviadoEm);
      if SegundosDesdeEnvio < TEMPO_REENVIO_SEGUNDOS then
        TAppErrors.RaiseBadRequest(
          'Aguarde o tempo de reenvio antes de solicitar um novo código.'
        );
    end;

    EmailConfig := TEleicaoEmailConfigService.Buscar(Contexto.IdEmpresa);
    if not EmailConfig.Ativo or
       EmailConfig.SmtpHost.IsEmpty or
       EmailConfig.Usuario.IsEmpty or
       not EmailConfig.SenhaConfigurada or
       EmailConfig.RemetenteEmail.IsEmpty then
      TAppErrors.RaiseBadRequest('O envio por e-mail não está disponível para esta empresa.');

    TEleicaoRateLimitAPIService.VerificarEnvioCodigo(
      Contexto.IdEmpresa,
      Contexto.IdEleicao,
      Contexto.IdUsuario,
      Slug
    );

    Codigo := GerarCodigoConfirmacao;
    CodigoHash := GerarHashCodigo(Codigo);

    // O novo hash substitui o anterior, invalidando imediatamente o código antigo.
    TEleicaoAPIPublicDao.SalvarCodigoConfirmacao(
      Conn,
      Contexto.IdEmpresa,
      Contexto.IdEleicao,
      Contexto.IdUsuario,
      CodigoHash
    );

    EmailService := TEleicaoEmailService.New;
    EmailService.Enviar(
      Contexto.IdEmpresa,
      Email,
      'Código de confirmação - Eleição',
      MontarHtmlCodigo(Contexto.Nome, Codigo)
    );

    TEleicaoAPIPublicDao.RegistrarEnvioCodigo(
      Conn,
      Contexto.IdEleicao,
      Contexto.IdUsuario
    );

    TEleicaoRateLimitAPIService.RegistrarEnvioCodigo(
      Contexto.IdEmpresa,
      Contexto.IdEleicao,
      Contexto.IdUsuario,
      Slug
    );

    TEleicaoAuditoriaAPIService.RegistrarEvento(
      Conn,
      Contexto.IdEmpresa,
      Contexto.IdEleicao,
      Contexto.IdUsuario,
      AUDITORIA_CODIGO_ENVIADO,
      AUDITORIA_ORIGEM_ELEITOR,
      True,
      'Código de confirmação enviado por e-mail.',
      AIP,
      AUserAgent
    );

    Result.Enviado := 'S';
    Result.Destino := MascararEmail(Email);
    Result.ExpiraEmSegundos := TEMPO_EXPIRACAO_SEGUNDOS;
    Result.ReenviarEmSegundos := TEMPO_REENVIO_SEGUNDOS;
  finally
    Conn.Free;
  end;
end;

end.
