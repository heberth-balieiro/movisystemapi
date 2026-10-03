unit PlataformaInstituicao.Service;

{$CODEPAGE UTF8}

interface

uses
  Uni,
  System.JSON,
  System.Generics.Collections,
  PlataformaInstituicao.Model;

type
  TPlataformaInstituicaoService = class
  private
    class procedure Validar(const AModel: TPlataformaInstituicaoModel); static;
    class function NormalizarSlug(const AValue: string): string; static;
    class function SomenteNumeros(const AValue: string): string; static;
    class function GerarCodigoPublico: string; static;
    class function GerarSenhaTemporaria: string; static;
    class function EmailValido(const AEmail: string): Boolean; static;
    class function CorHexValida(const ACor: string): Boolean; static;
    class function NormalizarWhatsApp(const AValor: string): string; static;
    class function GarantirAdministrador(const AConn: TUniConnection; const AModel: TPlataformaInstituicaoModel;
      out ASenhaTemporaria: string): Int64; static;
  public
    class function Listar(const APesquisa, ASituacao: string): TObjectList<TPlataformaInstituicaoModel>; static;
    class function Buscar(const AIdInstituicao: Int64): TPlataformaInstituicaoModel; static;
    class function Criar(const AModel: TPlataformaInstituicaoModel; const AIdUsuarioAcao: Int64;
      const AIP, AUserAgent: string; out ASenhaTemporaria: string): TPlataformaInstituicaoModel; static;
    class function Atualizar(const AIdInstituicao: Int64; const AModel: TPlataformaInstituicaoModel;
      const AIdUsuarioAcao: Int64; const AIP, AUserAgent: string; out ASenhaTemporaria: string): TPlataformaInstituicaoModel; static;

    class function EnviarAcesso(
      const AIdInstituicao, AIdUsuarioAcao: Int64;
      const ACanal, AIP, AUserAgent: string
    ): TJSONObject; static;
  end;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  App.Config,
  APP.Errors,
  Auth.Passwords,
  Database.Connection,
  PlataformaInstituicao.DAO,
  PlataformaModulo.DAO,
  InstituicaoPermissao.DAO,
  PlataformaEmailEnvio.Service,
  PlataformaWhatsApp.Model,
  PlataformaWhatsApp.Service,
  PlataformaUsuarioWhatsApp.Service,
  PlataformaIdentidade.Model,
  PlataformaIdentidade.Service,
  EvolutionApi.Service;

class function TPlataformaInstituicaoService.SomenteNumeros(const AValue: string): string;
var
  C: Char;
begin
  Result := '';
  for C in AValue do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

class function TPlataformaInstituicaoService.NormalizarSlug(const AValue: string): string;
var
  C: Char;
begin
  Result := LowerCase(Trim(AValue));
  if Result.IsEmpty then
    Exit;

  for C in Result do
    if not CharInSet(C, ['a'..'z', '0'..'9', '-']) then
      TAppErrors.RaiseBadRequest('Slug inválido. Utilize somente letras minúsculas, números e hífen.');

  if Result.StartsWith('-') or Result.EndsWith('-') or Result.Contains('--') then
    TAppErrors.RaiseBadRequest('Slug inválido.');
end;

class function TPlataformaInstituicaoService.EmailValido(const AEmail: string): Boolean;
var
  P: Integer;
begin
  P := Pos('@', Trim(AEmail));
  Result := (P > 1) and (Pos('.', Copy(Trim(AEmail), P + 2, MaxInt)) > 0);
end;

class function TPlataformaInstituicaoService.NormalizarWhatsApp(
  const AValor: string
): string;
var
  C: Char;
begin
  Result := '';
  for C in AValor do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;

  if (Length(Result) = 10) or (Length(Result) = 11) then
    Result := '55' + Result;
end;

class function TPlataformaInstituicaoService.CorHexValida(const ACor: string): Boolean;
var
  I: Integer;
  C: Char;
begin
  Result := (Length(Trim(ACor)) = 7) and (Trim(ACor)[1] = '#');
  if not Result then Exit;
  for I := 2 to 7 do
  begin
    C := UpCase(Trim(ACor)[I]);
    if not CharInSet(C, ['0'..'9', 'A'..'F']) then
      Exit(False);
  end;
end;

class procedure TPlataformaInstituicaoService.Validar(const AModel: TPlataformaInstituicaoModel);
begin
  if Trim(AModel.RazaoSocial).IsEmpty then TAppErrors.RaiseBadRequest('Informe a razão social/nome oficial.');
  if Trim(AModel.NomeFantasia).IsEmpty then TAppErrors.RaiseBadRequest('Informe o nome de exibição da instituição.');
  if Trim(AModel.Slug).IsEmpty then TAppErrors.RaiseBadRequest('Informe o slug da instituição.');
  if not SameText(AModel.Tipo, 'PRIVADA') and not SameText(AModel.Tipo, 'PUBLICA') then TAppErrors.RaiseBadRequest('Tipo de instituição inválido.');
  if not SameText(AModel.Situacao, 'ATIVA') and not SameText(AModel.Situacao, 'IMPLANTACAO') and
     not SameText(AModel.Situacao, 'BLOQUEADA') and not SameText(AModel.Situacao, 'INATIVA') then
    TAppErrors.RaiseBadRequest('Situação da instituição inválida.');
  if not Trim(AModel.Email).IsEmpty and not EmailValido(AModel.Email) then TAppErrors.RaiseBadRequest('E-mail de contato inválido.');
  if not Trim(AModel.Documento).IsEmpty and (Length(AModel.Documento) <> 14) then TAppErrors.RaiseBadRequest('CNPJ deve possuir 14 dígitos.');
  if Trim(AModel.AdministradorNome).IsEmpty then TAppErrors.RaiseBadRequest('Informe o administrador inicial.');
  if not EmailValido(AModel.AdministradorEmail) then TAppErrors.RaiseBadRequest('E-mail do administrador inválido.');
  if Trim(AModel.Tema.NomeExibicao).IsEmpty then AModel.Tema.NomeExibicao := AModel.NomeFantasia;
  if not CorHexValida(AModel.Tema.CorPrimaria) then TAppErrors.RaiseBadRequest('Cor primária inválida.');
  if not CorHexValida(AModel.Tema.CorSecundaria) then TAppErrors.RaiseBadRequest('Cor secundária inválida.');
  if not CorHexValida(AModel.Tema.CorDestaque) then TAppErrors.RaiseBadRequest('Cor de destaque inválida.');
  if not CorHexValida(AModel.Tema.CorFundo) then TAppErrors.RaiseBadRequest('Cor de fundo inválida.');
  if not CorHexValida(AModel.Tema.CorTexto) then TAppErrors.RaiseBadRequest('Cor do texto inválida.');
end;

class function TPlataformaInstituicaoService.GerarCodigoPublico: string;
var
  G: TGUID;
  S: string;
begin
  CreateGUID(G);
  S := UpperCase(GUIDToString(G));
  S := StringReplace(S, '{', '', [rfReplaceAll]);
  S := StringReplace(S, '}', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '', [rfReplaceAll]);
  Result := Copy(S, 1, 26);
end;

class function TPlataformaInstituicaoService.GerarSenhaTemporaria: string;
var
  G: TGUID;
  S: string;
begin
  CreateGUID(G);
  S := UpperCase(GUIDToString(G));
  S := StringReplace(S, '{', '', [rfReplaceAll]);
  S := StringReplace(S, '}', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '', [rfReplaceAll]);
  Result := 'Mv@' + Copy(S, 1, 10) + '1a';
end;

class function TPlataformaInstituicaoService.GarantirAdministrador(const AConn: TUniConnection;
  const AModel: TPlataformaInstituicaoModel; out ASenhaTemporaria: string): Int64;
begin
  ASenhaTemporaria := '';
  Result := TPlataformaInstituicaoDAO.BuscarUsuarioPorEmail(AConn, AModel.AdministradorEmail);

  // Se o usuário ainda não existir, cria uma senha temporária que é devolvida somente nesta operação.
  if Result <= 0 then
  begin
    ASenhaTemporaria := GerarSenhaTemporaria;
    Result := TPlataformaInstituicaoDAO.InserirUsuario(AConn, AModel.AdministradorNome,
      AModel.AdministradorEmail, HashSenha(ASenhaTemporaria));
  end;

  TPlataformaInstituicaoDAO.VincularAdministradorPrincipal(AConn, AModel.Id, Result, AModel.AdministradorEmail);
end;

class function TPlataformaInstituicaoService.Listar(const APesquisa,
  ASituacao: string): TObjectList<TPlataformaInstituicaoModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Item: TPlataformaInstituicaoModel;
  Modulos: TList<string>;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaInstituicaoDAO.Listar(Conn, APesquisa, ASituacao);

    for Item in Result do
    begin
      Modulos :=
        TPlataformaModuloDAO.ListarCodigosInstituicao(
          Conn,
          Item.Id
        );
      try
        Item.Modulos.AddRange(
          Modulos.ToArray
        );
      finally
        Modulos.Free;
      end;
    end;
  finally
    Conn.Free;
  end;
end;

class function TPlataformaInstituicaoService.Buscar(const AIdInstituicao: Int64): TPlataformaInstituicaoModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Modulos: TList<string>;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseBadRequest('Instituição inválida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaInstituicaoDAO.BuscarPorId(Conn, AIdInstituicao);
    if Result = nil then
      TAppErrors.RaiseNotFound('Instituição não encontrada.');

    Modulos :=
      TPlataformaModuloDAO.ListarCodigosInstituicao(
        Conn,
        AIdInstituicao
      );
    try
      Result.Modulos.AddRange(
        Modulos.ToArray
      );
    finally
      Modulos.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TPlataformaInstituicaoService.Criar(const AModel: TPlataformaInstituicaoModel;
  const AIdUsuarioAcao: Int64; const AIP, AUserAgent: string;
  out ASenhaTemporaria: string): TPlataformaInstituicaoModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  CodigoModulo: string;
begin
  Result := nil;
  ASenhaTemporaria := '';

  AModel.Slug := NormalizarSlug(AModel.Slug);
  AModel.Documento := SomenteNumeros(AModel.Documento);
  AModel.Email := LowerCase(Trim(AModel.Email));
  AModel.AdministradorEmail := LowerCase(Trim(AModel.AdministradorEmail));
  AModel.Tipo := UpperCase(Trim(AModel.Tipo));
  AModel.Situacao := UpperCase(Trim(AModel.Situacao));
  Validar(AModel);

  if AModel.Modulos.Count = 0 then
    TAppErrors.RaiseBadRequest(
      'Selecione ao menos um módulo para a instituição.'
    );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    for CodigoModulo in AModel.Modulos do
      if not TPlataformaModuloDAO.CodigoAtivoExiste(
        Conn,
        CodigoModulo
      ) then
        TAppErrors.RaiseBadRequest(
          'Módulo inválido ou inativo: ' +
          UpperCase(Trim(CodigoModulo))
        );

    if TPlataformaInstituicaoDAO.ExisteSlug(Conn, AModel.Slug) then
      TAppErrors.RaiseBadRequest('Este slug j' + #$00E1 + ' est' + #$00E1 + ' sendo utilizado por outra institui' + #$00E7 + #$00E3 + 'o.');
    if TPlataformaInstituicaoDAO.ExisteDocumento(Conn, AModel.Documento) then
      TAppErrors.RaiseBadRequest('Este CNPJ j' + #$00E1 + ' est' + #$00E1 + ' cadastrado.');

    Conn.StartTransaction;
    try
      AModel.CodigoPublico := GerarCodigoPublico;
      AModel.Id := TPlataformaInstituicaoDAO.Inserir(Conn, AModel);
      TPlataformaInstituicaoDAO.SalvarConfiguracao(Conn, AModel);

      TPlataformaModuloDAO.SalvarModulosInstituicao(
        Conn,
        AModel.Id,
        AIdUsuarioAcao,
        AModel.Modulos
      );

      GarantirAdministrador(Conn, AModel, ASenhaTemporaria);

      TInstituicaoPermissaoDAO.GarantirPerfilAdministrador(
        Conn,
        AModel.Id
      );

      TPlataformaInstituicaoDAO.RegistrarAuditoria(Conn, AModel.Id, AIdUsuarioAcao,
        'INSTITUICAO_CRIADA', 'Instituição ' + AModel.NomeFantasia + ' cadastrada.', 'POST',
        '/v1/cursos/plataforma/instituicoes', AIP, AUserAgent);
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

    Result := TPlataformaInstituicaoDAO.BuscarPorId(Conn, AModel.Id);
    if Result <> nil then
      Result.Modulos.AddRange(
        AModel.Modulos.ToArray
      );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaInstituicaoService.Atualizar(const AIdInstituicao: Int64;
  const AModel: TPlataformaInstituicaoModel; const AIdUsuarioAcao: Int64;
  const AIP, AUserAgent: string; out ASenhaTemporaria: string): TPlataformaInstituicaoModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Existente: TPlataformaInstituicaoModel;
  Modulos: TList<string>;
  CodigoModulo: string;
begin
  Result := nil;
  ASenhaTemporaria := '';
  if AIdInstituicao <= 0 then TAppErrors.RaiseBadRequest('Instituição inválida.');

  AModel.Id := AIdInstituicao;
  AModel.Slug := NormalizarSlug(AModel.Slug);
  AModel.Documento := SomenteNumeros(AModel.Documento);
  AModel.Email := LowerCase(Trim(AModel.Email));
  AModel.AdministradorEmail := LowerCase(Trim(AModel.AdministradorEmail));
  AModel.Tipo := UpperCase(Trim(AModel.Tipo));
  AModel.Situacao := UpperCase(Trim(AModel.Situacao));
  Validar(AModel);

  if AModel.Modulos.Count = 0 then
    TAppErrors.RaiseBadRequest(
      'Selecione ao menos um módulo para a instituição.'
    );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    for CodigoModulo in AModel.Modulos do
      if not TPlataformaModuloDAO.CodigoAtivoExiste(
        Conn,
        CodigoModulo
      ) then
        TAppErrors.RaiseBadRequest(
          'Módulo inválido ou inativo: ' +
          UpperCase(Trim(CodigoModulo))
        );

    Existente := TPlataformaInstituicaoDAO.BuscarPorId(Conn, AIdInstituicao);
    if Existente = nil then
      TAppErrors.RaiseNotFound('Instituição não encontrada.');
    Existente.Free;

    if TPlataformaInstituicaoDAO.ExisteSlug(Conn, AModel.Slug, AIdInstituicao) then
      TAppErrors.RaiseBadRequest('Este slug j' + #$00E1 + ' est' + #$00E1 + ' sendo utilizado por outra institui' + #$00E7 + #$00E3 + 'o.');
    if TPlataformaInstituicaoDAO.ExisteDocumento(Conn, AModel.Documento, AIdInstituicao) then
      TAppErrors.RaiseBadRequest('Este CNPJ j' + #$00E1 + ' est' + #$00E1 + ' cadastrado.');

    Conn.StartTransaction;
    try
      TPlataformaInstituicaoDAO.Atualizar(Conn, AModel);
      TPlataformaInstituicaoDAO.SalvarConfiguracao(Conn, AModel);

      TPlataformaModuloDAO.SalvarModulosInstituicao(
        Conn,
        AIdInstituicao,
        AIdUsuarioAcao,
        AModel.Modulos
      );

      GarantirAdministrador(Conn, AModel, ASenhaTemporaria);

      TInstituicaoPermissaoDAO.GarantirPerfilAdministrador(
        Conn,
        AIdInstituicao
      );

      TPlataformaInstituicaoDAO.RegistrarAuditoria(Conn, AIdInstituicao, AIdUsuarioAcao,
        'INSTITUICAO_ALTERADA', 'Instituição ' + AModel.NomeFantasia + ' atualizada.', 'PUT',
        '/v1/cursos/plataforma/instituicoes/' + AIdInstituicao.ToString, AIP, AUserAgent);
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

    Result := TPlataformaInstituicaoDAO.BuscarPorId(Conn, AIdInstituicao);
    if Result <> nil then
    begin
      Modulos :=
        TPlataformaModuloDAO.ListarCodigosInstituicao(
          Conn,
          AIdInstituicao
        );
      try
        Result.Modulos.AddRange(
          Modulos.ToArray
        );
      finally
        Modulos.Free;
      end;
    end;
  finally
    Conn.Free;
  end;
end;


class function TPlataformaInstituicaoService.EnviarAcesso(
  const AIdInstituicao, AIdUsuarioAcao: Int64;
  const ACanal, AIP, AUserAgent: string
): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Instituicao: TPlataformaInstituicaoModel;
  IdUsuarioAdmin: Int64;
  Canal, SenhaTemporaria, UrlAcesso, Destinatario, NomePlataforma: string;
  ApiUrl, ApiKey, Instancia, Numero, Mensagem, Html: string;
  Identidade: TPlataformaIdentidadeConfig;
  WhatsAppConfig: TPlataformaWhatsAppConfig;
  RetornoEvolution: TJSONValue;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseBadRequest('Instituição inválida.');

  if AIdUsuarioAcao <= 0 then
    TAppErrors.RaiseForbidden('Usuário responsável pela operação não identificado.');

  Canal := UpperCase(Trim(ACanal));
  if (Canal <> 'EMAIL') and (Canal <> 'WHATSAPP') then
    TAppErrors.RaiseBadRequest('Canal inválido. Utilize EMAIL ou WHATSAPP.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  UrlAcesso := Trim(Config.Web.PublicURL);
  while UrlAcesso.EndsWith('/') do
    Delete(UrlAcesso, Length(UrlAcesso), 1);

  if UrlAcesso.IsEmpty then
    TAppErrors.RaiseBadRequest('Configure WEB.PublicURL antes de enviar o acesso.');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  Instituicao := nil;
  try
    Instituicao := TPlataformaInstituicaoDAO.BuscarPorId(Conn, AIdInstituicao);
    if Instituicao = nil then
      TAppErrors.RaiseNotFound('Instituição não encontrada.');

    IdUsuarioAdmin := TPlataformaInstituicaoDAO.BuscarAdministradorPrincipalId(
      Conn,
      AIdInstituicao
    );

    if IdUsuarioAdmin <= 0 then
      TAppErrors.RaiseBadRequest('A instituição não possui administrador principal ativo.');

    UrlAcesso := UrlAcesso + '/' + Instituicao.Slug + '/login';
    SenhaTemporaria := GerarSenhaTemporaria;

    Identidade := TPlataformaIdentidadeService.Buscar;
    NomePlataforma := Trim(Identidade.NomePlataforma);
    if NomePlataforma.IsEmpty then
      NomePlataforma := 'MoviSystem';

    if Canal = 'EMAIL' then
    begin
      Destinatario := LowerCase(Trim(Instituicao.AdministradorEmail));
      if not EmailValido(Destinatario) then
        TAppErrors.RaiseBadRequest('O administrador principal não possui e-mail válido.');

      Html :=
        '<div style="font-family:Arial,sans-serif;color:#0f172a">' +
        '<h2>Acesso à ' + TNetEncoding.HTML.Encode(NomePlataforma) + '</h2>' +
        '<p>Olá, ' + TNetEncoding.HTML.Encode(Instituicao.AdministradorNome) + '.</p>' +
        '<p>O acesso administrativo da instituição <strong>' +
        TNetEncoding.HTML.Encode(Instituicao.NomeFantasia) + '</strong> está disponível.</p>' +
        '<p><strong>URL:</strong> <a href="' + TNetEncoding.HTML.Encode(UrlAcesso) + '">' +
        TNetEncoding.HTML.Encode(UrlAcesso) + '</a><br>' +
        '<strong>E-mail:</strong> ' + TNetEncoding.HTML.Encode(Destinatario) + '<br>' +
        '<strong>Senha temporária:</strong> ' + TNetEncoding.HTML.Encode(SenhaTemporaria) + '</p>' +
        '<p>Por segurança, altere sua senha após o primeiro acesso.</p>' +
        '</div>';
    end
    else
    begin
      Numero := NormalizarWhatsApp(Instituicao.Telefone);
      if (Length(Numero) < 12) or (Length(Numero) > 13) then
        TAppErrors.RaiseBadRequest(
          'Informe um telefone/WhatsApp válido no cadastro da instituição antes de enviar o acesso.'
        );

      Destinatario := Numero;
      Mensagem :=
        'Acesso ' + NomePlataforma + sLineBreak +
        'Instituição: ' + Instituicao.NomeFantasia + sLineBreak +
        'URL: ' + UrlAcesso + sLineBreak +
        'E-mail: ' + Instituicao.AdministradorEmail + sLineBreak +
        'Senha temporária: ' + SenhaTemporaria + sLineBreak +
        'Por segurança, altere sua senha após o primeiro acesso.';

      WhatsAppConfig := TPlataformaWhatsAppService.Buscar;

      if SameText(WhatsAppConfig.ModoInstancia, 'USUARIO') then
      begin
        if not TPlataformaUsuarioWhatsAppService.ObterInstanciaParaEnvio(
          AIdUsuarioAcao,
          ApiUrl,
          ApiKey,
          Instancia
        ) then
          TAppErrors.RaiseBadRequest(
            'Conecte o WhatsApp do seu usuário antes de enviar o acesso.'
          );
      end
      else if not TPlataformaWhatsAppService.ObterCredenciais(
        ApiUrl,
        ApiKey,
        Instancia
      ) then
        TAppErrors.RaiseBadRequest(
          'Configuração global do WhatsApp da empresa indisponível.'
        );
    end;

    Conn.StartTransaction;
    try
      TPlataformaInstituicaoDAO.AtualizarSenhaUsuario(
        Conn,
        IdUsuarioAdmin,
        HashSenha(SenhaTemporaria)
      );

      if Canal = 'EMAIL' then
        TPlataformaEmailEnvioService.Enviar(
          Destinatario,
          'Acesso à ' + NomePlataforma + ' - ' + Instituicao.NomeFantasia,
          Html
        )
      else
      begin
        RetornoEvolution := TEvolutionApiService.EnviarTexto(
          ApiUrl,
          ApiKey,
          Instancia,
          Destinatario,
          Mensagem
        );
        RetornoEvolution.Free;
      end;

      TPlataformaInstituicaoDAO.RegistrarAuditoria(
        Conn,
        AIdInstituicao,
        AIdUsuarioAcao,
        'INSTITUICAO_ACESSO_ENVIADO',
        'Acesso do administrador principal enviado por ' + Canal + '.',
        'POST',
        '/v1/certifica/plataforma/instituicoes/' + AIdInstituicao.ToString + '/acesso/enviar',
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Result := TJSONObject.Create;
    Result.AddPair('canal', Canal);
    Result.AddPair('destinatario', Destinatario);
    Result.AddPair('url_acesso', UrlAcesso);
  finally
    Instituicao.Free;
    Conn.Free;
  end;
end;

end.
