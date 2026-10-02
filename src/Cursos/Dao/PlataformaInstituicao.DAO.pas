unit PlataformaInstituicao.DAO;

interface

uses
  Uni,
  System.Generics.Collections,
  PlataformaInstituicao.Model;

type
  TPlataformaInstituicaoDAO = class
  private
    class procedure CarregarModel(const AQry: TUniQuery; const AModel: TPlataformaInstituicaoModel); static;
  public
    class function Listar(const AConn: TUniConnection; const APesquisa, ASituacao: string): TObjectList<TPlataformaInstituicaoModel>; static;
    class function BuscarPorId(const AConn: TUniConnection; const AIdInstituicao: Int64): TPlataformaInstituicaoModel; static;
    class function ExisteSlug(const AConn: TUniConnection; const ASlug: string; const AIgnorarId: Int64 = 0): Boolean; static;
    class function ExisteDocumento(const AConn: TUniConnection; const ADocumento: string; const AIgnorarId: Int64 = 0): Boolean; static;

    class function Inserir(const AConn: TUniConnection; const AModel: TPlataformaInstituicaoModel): Int64; static;
    class procedure Atualizar(const AConn: TUniConnection; const AModel: TPlataformaInstituicaoModel); static;
    class procedure SalvarConfiguracao(const AConn: TUniConnection; const AModel: TPlataformaInstituicaoModel); static;

    class function BuscarUsuarioPorEmail(const AConn: TUniConnection; const AEmail: string): Int64; static;
    class function InserirUsuario(const AConn: TUniConnection; const ANome, AEmail, ASenhaHash: string): Int64; static;
    class procedure VincularAdministradorPrincipal(const AConn: TUniConnection; const AIdInstituicao, AIdUsuario: Int64; const AEmail: string); static;

    class procedure RegistrarAuditoria(const AConn: TUniConnection; const AIdInstituicao, AIdUsuario: Int64;
      const AAcao, AMensagem, AMetodo, ARota, AIP, AUserAgent: string); static;
  end;

implementation

uses
  System.SysUtils;

class procedure TPlataformaInstituicaoDAO.CarregarModel(const AQry: TUniQuery;
  const AModel: TPlataformaInstituicaoModel);
begin
  AModel.Id := AQry.FieldByName('id').AsLargeInt;
  AModel.CodigoPublico := AQry.FieldByName('codigo_publico').AsString;
  AModel.Slug := AQry.FieldByName('slug').AsString;
  AModel.RazaoSocial := AQry.FieldByName('razao_social').AsString;
  AModel.NomeFantasia := AQry.FieldByName('nome_fantasia').AsString;
  AModel.Documento := AQry.FieldByName('cnpj').AsString;
  AModel.Tipo := AQry.FieldByName('tipo').AsString;
  AModel.Email := AQry.FieldByName('email').AsString;
  AModel.Telefone := AQry.FieldByName('telefone').AsString;
  AModel.Site := AQry.FieldByName('site').AsString;
  AModel.Situacao := AQry.FieldByName('situacao').AsString;
  AModel.CriadoEm := AQry.FieldByName('criado_em').AsDateTime;
  AModel.AdministradorNome := AQry.FieldByName('administrador_nome').AsString;
  AModel.AdministradorEmail := AQry.FieldByName('administrador_email').AsString;

  AModel.Tema.NomeExibicao := AQry.FieldByName('nome_exibicao').AsString;
  AModel.Tema.LogoUrl := AQry.FieldByName('logo_url').AsString;
  AModel.Tema.FaviconUrl := AQry.FieldByName('favicon_url').AsString;
  AModel.Tema.ImagemLoginUrl := AQry.FieldByName('imagem_login_url').AsString;
  AModel.Tema.CorPrimaria := AQry.FieldByName('cor_primaria').AsString;
  AModel.Tema.CorSecundaria := AQry.FieldByName('cor_secundaria').AsString;
  AModel.Tema.CorDestaque := AQry.FieldByName('cor_destaque').AsString;
  AModel.Tema.CorFundo := AQry.FieldByName('cor_fundo').AsString;
  AModel.Tema.CorTexto := AQry.FieldByName('cor_texto').AsString;

  AModel.MetricasUsuarios := AQry.FieldByName('metricas_usuarios').AsInteger;
  AModel.MetricasParticipantes := AQry.FieldByName('metricas_participantes').AsInteger;
  AModel.MetricasCursos := AQry.FieldByName('metricas_cursos').AsInteger;
  AModel.MetricasTurmas := AQry.FieldByName('metricas_turmas').AsInteger;
  AModel.MetricasCertificados := AQry.FieldByName('metricas_certificados').AsInteger;
end;

class function TPlataformaInstituicaoDAO.Listar(const AConn: TUniConnection;
  const APesquisa, ASituacao: string): TObjectList<TPlataformaInstituicaoModel>;
var
  Qry: TUniQuery;
  Item: TPlataformaInstituicaoModel;
begin
  Result := TObjectList<TPlataformaInstituicaoModel>.Create(True);
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT i.id, i.codigo_publico, i.slug, i.razao_social, i.nome_fantasia, i.cnpj, i.tipo, ' +
      '       i.email, i.telefone, i.site, i.situacao, i.criado_em, ' +
      '       COALESCE(ic.nome_exibicao, i.nome_fantasia) AS nome_exibicao, ' +
      '       COALESCE(ic.logo_url, '''') AS logo_url, COALESCE(ic.favicon_url, '''') AS favicon_url, ' +
      '       COALESCE(ic.imagem_login_url, '''') AS imagem_login_url, ' +
      '       COALESCE(ic.cor_primaria, ''#2563EB'') AS cor_primaria, ' +
      '       COALESCE(ic.cor_secundaria, ''#1E40AF'') AS cor_secundaria, ' +
      '       COALESCE(ic.cor_destaque, ''#F59E0B'') AS cor_destaque, ' +
      '       COALESCE(ic.cor_fundo, ''#F8FAFC'') AS cor_fundo, ' +
      '       COALESCE(ic.cor_texto, ''#0F172A'') AS cor_texto, ' +
      '       COALESCE(u.nome, '''') AS administrador_nome, COALESCE(u.email, '''') AS administrador_email, ' +
      '       (SELECT COUNT(*) FROM usuario_instituicao ux WHERE ux.id_instituicao=i.id AND ux.situacao=''ATIVO'' ' +
      '          AND (ux.principal=1 OR EXISTS (SELECT 1 FROM usuario_instituicao_perfil uip WHERE uip.id_instituicao=ux.id_instituicao AND uip.id_usuario_instituicao=ux.id))) AS metricas_usuarios, ' +
      '       (SELECT COUNT(*) FROM participante p WHERE p.id_instituicao=i.id AND p.situacao<>''ANONIMIZADO'') AS metricas_participantes, ' +
      '       (SELECT COUNT(*) FROM curso c WHERE c.id_instituicao=i.id) AS metricas_cursos, ' +
      '       (SELECT COUNT(*) FROM turma t WHERE t.id_instituicao=i.id) AS metricas_turmas, ' +
      '       (SELECT COUNT(*) FROM certificado ce WHERE ce.id_instituicao=i.id) AS metricas_certificados ' +
      'FROM instituicao i ' +
      'LEFT JOIN instituicao_configuracao ic ON ic.id_instituicao = i.id ' +
      'LEFT JOIN usuario_instituicao ui ON ui.id_instituicao = i.id AND ui.principal = 1 ' +
      'LEFT JOIN usuario u ON u.id = ui.id_usuario ' +
      'WHERE 1 = 1 ';

    if not Trim(APesquisa).IsEmpty then
      Qry.SQL.Add('AND (i.nome_fantasia LIKE :pesquisa OR i.razao_social LIKE :pesquisa OR i.slug LIKE :pesquisa OR i.cnpj LIKE :pesquisa) ');
    if not Trim(ASituacao).IsEmpty then
      Qry.SQL.Add('AND i.situacao = :situacao ');

    Qry.SQL.Add('ORDER BY i.nome_fantasia, i.id');

    if not Trim(APesquisa).IsEmpty then
      Qry.ParamByName('pesquisa').AsString := '%' + Trim(APesquisa) + '%';
    if not Trim(ASituacao).IsEmpty then
      Qry.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));

    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TPlataformaInstituicaoModel.Create;
      CarregarModel(Qry, Item);
      Result.Add(Item);
      Qry.Next;
    end;

    //Result.Free;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaInstituicaoDAO.BuscarPorId(const AConn: TUniConnection;
  const AIdInstituicao: Int64): TPlataformaInstituicaoModel;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT i.id, i.codigo_publico, i.slug, i.razao_social, i.nome_fantasia, i.cnpj, i.tipo, ' +
      '       i.email, i.telefone, i.site, i.situacao, i.criado_em, ' +
      '       COALESCE(ic.nome_exibicao, i.nome_fantasia) AS nome_exibicao, ' +
      '       COALESCE(ic.logo_url, '''') AS logo_url, COALESCE(ic.favicon_url, '''') AS favicon_url, ' +
      '       COALESCE(ic.imagem_login_url, '''') AS imagem_login_url, ' +
      '       COALESCE(ic.cor_primaria, ''#2563EB'') AS cor_primaria, ' +
      '       COALESCE(ic.cor_secundaria, ''#1E40AF'') AS cor_secundaria, ' +
      '       COALESCE(ic.cor_destaque, ''#F59E0B'') AS cor_destaque, ' +
      '       COALESCE(ic.cor_fundo, ''#F8FAFC'') AS cor_fundo, ' +
      '       COALESCE(ic.cor_texto, ''#0F172A'') AS cor_texto, ' +
      '       COALESCE(u.nome, '''') AS administrador_nome, COALESCE(u.email, '''') AS administrador_email, ' +
      '       (SELECT COUNT(*) FROM usuario_instituicao ux WHERE ux.id_instituicao=i.id AND ux.situacao=''ATIVO'' ' +
      '          AND (ux.principal=1 OR EXISTS (SELECT 1 FROM usuario_instituicao_perfil uip WHERE uip.id_instituicao=ux.id_instituicao AND uip.id_usuario_instituicao=ux.id))) AS metricas_usuarios, ' +
      '       (SELECT COUNT(*) FROM participante p WHERE p.id_instituicao=i.id AND p.situacao<>''ANONIMIZADO'') AS metricas_participantes, ' +
      '       (SELECT COUNT(*) FROM curso c WHERE c.id_instituicao=i.id) AS metricas_cursos, ' +
      '       (SELECT COUNT(*) FROM turma t WHERE t.id_instituicao=i.id) AS metricas_turmas, ' +
      '       (SELECT COUNT(*) FROM certificado ce WHERE ce.id_instituicao=i.id) AS metricas_certificados ' +
      'FROM instituicao i ' +
      'LEFT JOIN instituicao_configuracao ic ON ic.id_instituicao = i.id ' +
      'LEFT JOIN usuario_instituicao ui ON ui.id_instituicao = i.id AND ui.principal = 1 ' +
      'LEFT JOIN usuario u ON u.id = ui.id_usuario ' +
      'WHERE i.id = :id LIMIT 1';
    Qry.ParamByName('id').AsLargeInt := AIdInstituicao;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result    := TPlataformaInstituicaoModel.Create;
    CarregarModel(Qry, Result);
  finally
    Qry.Free;
  end;
end;

class function TPlataformaInstituicaoDAO.ExisteSlug(const AConn: TUniConnection;
  const ASlug: string; const AIgnorarId: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'SELECT COUNT(*) total FROM instituicao WHERE slug = :slug';
    if AIgnorarId > 0 then
      Qry.SQL.Add('AND id <> :ignorar_id');
    Qry.ParamByName('slug').AsString := LowerCase(Trim(ASlug));
    if AIgnorarId > 0 then
      Qry.ParamByName('ignorar_id').AsLargeInt := AIgnorarId;
    Qry.Open;
    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaInstituicaoDAO.ExisteDocumento(const AConn: TUniConnection;
  const ADocumento: string; const AIgnorarId: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  if Trim(ADocumento).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'SELECT COUNT(*) total FROM instituicao WHERE cnpj = :cnpj';
    if AIgnorarId > 0 then
      Qry.SQL.Add('AND id <> :ignorar_id');
    Qry.ParamByName('cnpj').AsString := Trim(ADocumento);
    if AIgnorarId > 0 then
      Qry.ParamByName('ignorar_id').AsLargeInt := AIgnorarId;
    Qry.Open;
    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaInstituicaoDAO.Inserir(const AConn: TUniConnection;
  const AModel: TPlataformaInstituicaoModel): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO instituicao ' +
      '(codigo_publico, slug, razao_social, nome_fantasia, cnpj, tipo, email, telefone, site, situacao) ' +
      'VALUES (:codigo_publico, :slug, :razao_social, :nome_fantasia, :cnpj, :tipo, :email, :telefone, :site, :situacao)';
    Qry.ParamByName('codigo_publico').AsString := AModel.CodigoPublico;
    Qry.ParamByName('slug').AsString := AModel.Slug;
    Qry.ParamByName('razao_social').AsString := AModel.RazaoSocial;
    Qry.ParamByName('nome_fantasia').AsString := AModel.NomeFantasia;
    if Trim(AModel.Documento).IsEmpty then Qry.ParamByName('cnpj').Clear else Qry.ParamByName('cnpj').AsString := AModel.Documento;
    Qry.ParamByName('tipo').AsString := AModel.Tipo;
    if Trim(AModel.Email).IsEmpty then Qry.ParamByName('email').Clear else Qry.ParamByName('email').AsString := AModel.Email;
    if Trim(AModel.Telefone).IsEmpty then Qry.ParamByName('telefone').Clear else Qry.ParamByName('telefone').AsString := AModel.Telefone;
    if Trim(AModel.Site).IsEmpty then Qry.ParamByName('site').Clear else Qry.ParamByName('site').AsString := AModel.Site;
    Qry.ParamByName('situacao').AsString := AModel.Situacao;
    Qry.Execute;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaInstituicaoDAO.Atualizar(const AConn: TUniConnection;
  const AModel: TPlataformaInstituicaoModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE instituicao SET slug = :slug, razao_social = :razao_social, nome_fantasia = :nome_fantasia, ' +
      'cnpj = :cnpj, tipo = :tipo, email = :email, telefone = :telefone, site = :site, situacao = :situacao, ' +
      'inativado_em = CASE WHEN :situacao_inativada = 1 THEN COALESCE(inativado_em, CURRENT_TIMESTAMP(3)) ELSE NULL END ' +
      'WHERE id = :id';
    Qry.ParamByName('slug').AsString := AModel.Slug;
    Qry.ParamByName('razao_social').AsString := AModel.RazaoSocial;
    Qry.ParamByName('nome_fantasia').AsString := AModel.NomeFantasia;
    if Trim(AModel.Documento).IsEmpty then Qry.ParamByName('cnpj').Clear else Qry.ParamByName('cnpj').AsString := AModel.Documento;
    Qry.ParamByName('tipo').AsString := AModel.Tipo;
    if Trim(AModel.Email).IsEmpty then Qry.ParamByName('email').Clear else Qry.ParamByName('email').AsString := AModel.Email;
    if Trim(AModel.Telefone).IsEmpty then Qry.ParamByName('telefone').Clear else Qry.ParamByName('telefone').AsString := AModel.Telefone;
    if Trim(AModel.Site).IsEmpty then Qry.ParamByName('site').Clear else Qry.ParamByName('site').AsString := AModel.Site;
    Qry.ParamByName('situacao').AsString := AModel.Situacao;
    Qry.ParamByName('situacao_inativada').AsInteger := Ord(SameText(AModel.Situacao, 'INATIVA'));
    Qry.ParamByName('id').AsLargeInt := AModel.Id;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaInstituicaoDAO.SalvarConfiguracao(const AConn: TUniConnection;
  const AModel: TPlataformaInstituicaoModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO instituicao_configuracao ' +
      '(id_instituicao, nome_exibicao, logo_url, favicon_url, imagem_login_url, cor_primaria, cor_secundaria, cor_destaque, cor_fundo, cor_texto, email_contato, telefone_contato) ' +
      'VALUES (:id_instituicao, :nome_exibicao, :logo_url, :favicon_url, :imagem_login_url, :cor_primaria, :cor_secundaria, :cor_destaque, :cor_fundo, :cor_texto, :email_contato, :telefone_contato) ' +
      'ON DUPLICATE KEY UPDATE nome_exibicao = VALUES(nome_exibicao), logo_url = VALUES(logo_url), favicon_url = VALUES(favicon_url), ' +
      'imagem_login_url = VALUES(imagem_login_url), cor_primaria = VALUES(cor_primaria), cor_secundaria = VALUES(cor_secundaria), ' +
      'cor_destaque = VALUES(cor_destaque), cor_fundo = VALUES(cor_fundo), cor_texto = VALUES(cor_texto), ' +
      'email_contato = VALUES(email_contato), telefone_contato = VALUES(telefone_contato)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AModel.Id;
    Qry.ParamByName('nome_exibicao').AsString := AModel.Tema.NomeExibicao;
    if Trim(AModel.Tema.LogoUrl).IsEmpty then Qry.ParamByName('logo_url').Clear else Qry.ParamByName('logo_url').AsString := AModel.Tema.LogoUrl;
    if Trim(AModel.Tema.FaviconUrl).IsEmpty then Qry.ParamByName('favicon_url').Clear else Qry.ParamByName('favicon_url').AsString := AModel.Tema.FaviconUrl;
    if Trim(AModel.Tema.ImagemLoginUrl).IsEmpty then Qry.ParamByName('imagem_login_url').Clear else Qry.ParamByName('imagem_login_url').AsString := AModel.Tema.ImagemLoginUrl;
    Qry.ParamByName('cor_primaria').AsString := AModel.Tema.CorPrimaria;
    Qry.ParamByName('cor_secundaria').AsString := AModel.Tema.CorSecundaria;
    Qry.ParamByName('cor_destaque').AsString := AModel.Tema.CorDestaque;
    Qry.ParamByName('cor_fundo').AsString := AModel.Tema.CorFundo;
    Qry.ParamByName('cor_texto').AsString := AModel.Tema.CorTexto;
    if Trim(AModel.Email).IsEmpty then Qry.ParamByName('email_contato').Clear else Qry.ParamByName('email_contato').AsString := AModel.Email;
    if Trim(AModel.Telefone).IsEmpty then Qry.ParamByName('telefone_contato').Clear else Qry.ParamByName('telefone_contato').AsString := AModel.Telefone;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaInstituicaoDAO.BuscarUsuarioPorEmail(const AConn: TUniConnection;
  const AEmail: string): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'SELECT id FROM usuario WHERE email_normalizado = :email LIMIT 1';
    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmail));
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaInstituicaoDAO.InserirUsuario(const AConn: TUniConnection;
  const ANome, AEmail, ASenhaHash: string): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO usuario (nome, email, email_normalizado, senha_hash, is_super_admin, situacao, senha_alterada_em) ' +
      'VALUES (:nome, :email, :email_normalizado, :senha_hash, 0, ''ATIVO'', CURRENT_TIMESTAMP(3))';
    Qry.ParamByName('nome').AsString := Trim(ANome);
    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmail));
    Qry.ParamByName('email_normalizado').AsString := LowerCase(Trim(AEmail));
    Qry.ParamByName('senha_hash').AsString := ASenhaHash;
    Qry.Execute;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaInstituicaoDAO.VincularAdministradorPrincipal(const AConn: TUniConnection;
  const AIdInstituicao, AIdUsuario: Int64; const AEmail: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    // Garante apenas um administrador marcado como principal por instituição.
    Qry.SQL.Text := 'UPDATE usuario_instituicao SET principal = 0 WHERE id_instituicao = :id_instituicao AND principal = 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Execute;

    Qry.SQL.Text :=
      'INSERT INTO usuario_instituicao (id_instituicao, id_usuario, login, situacao, principal) ' +
      'VALUES (:id_instituicao, :id_usuario, :login, ''ATIVO'', 1) ' +
      'ON DUPLICATE KEY UPDATE login = VALUES(login), situacao = ''ATIVO'', principal = 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('login').AsString := LowerCase(Trim(AEmail));
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaInstituicaoDAO.RegistrarAuditoria(const AConn: TUniConnection;
  const AIdInstituicao, AIdUsuario: Int64; const AAcao, AMensagem, AMetodo, ARota, AIP, AUserAgent: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, acao, entidade, registro_id, metodo_http, rota, ip, user_agent, sucesso, mensagem) ' +
      'VALUES (:id_instituicao, :id_usuario, NULL, :acao, ''instituicao'', :registro_id, :metodo, :rota, :ip, :user_agent, 1, :mensagem)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('acao').AsString := Copy(UpperCase(Trim(AAcao)), 1, 80);
    Qry.ParamByName('registro_id').AsString := AIdInstituicao.ToString;
    Qry.ParamByName('metodo').AsString := Copy(UpperCase(Trim(AMetodo)), 1, 10);
    Qry.ParamByName('rota').AsString := Copy(Trim(ARota), 1, 500);
    Qry.ParamByName('ip').AsString := Copy(Trim(AIP), 1, 45);
    Qry.ParamByName('user_agent').AsString := Copy(Trim(AUserAgent), 1, 1000);
    Qry.ParamByName('mensagem').AsString := Copy(Trim(AMensagem), 1, 1000);
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
