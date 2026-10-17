unit EleicaoMelhoriasAPI.Service;

interface

type
  TAtualizacaoCadastralIdentificacaoResult = record
    Identificado: string;
    Nome: string;
    Token: string;
  end;

  TAtualizacaoCadastralSolicitacaoResult = record
    IdSolicitacao: Int64;
    Situacao: string;
  end;

  TEleicaoMelhoriasAPIService = class
  private
    class function SomenteNumeros(const AValor: string): string; static;
    class function MascararNome(const ANome: string): string; static;
    class function GerarChaveRateLimit(const ACPF, AMatricula, AIP: string): string; static;
    class procedure VerificarRateLimit(const AChave: string); static;
    class procedure RegistrarFalhaRateLimit(const AChave: string); static;
    class procedure LimparRateLimit(const AChave: string); static;
  public
    class procedure EnsureSchema; static;
    class function AjustarExpiracaoOTP(const ASlug: string; const AIdEmpresa, AIdUsuario: Int64): Integer; static;
    class function IdentificarAssociado(const ACPF, AMatricula, AIP: string): TAtualizacaoCadastralIdentificacaoResult; static;
    class function SolicitarAtualizacao(const AIdEmpresa, AIdUsuario: Int64;
      const AEmail, ATelefone, AWhatsapp, AIP, AUserAgent: string): TAtualizacaoCadastralSolicitacaoResult; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Hash,
  Uni,
  App.Config,
  App.Errors,
  App.JWT,
  Database.Connection;

const
  OTP_EXPIRACAO_SEGUNDOS = 90;
  RATE_MAX_TENTATIVAS = 5;
  RATE_JANELA_MINUTOS = 15;
  RATE_BLOQUEIO_MINUTOS = 15;

class function TEleicaoMelhoriasAPIService.SomenteNumeros(const AValor: string): string;
var
  C: Char;
begin
  Result := '';
  for C in AValor do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

class function TEleicaoMelhoriasAPIService.MascararNome(const ANome: string): string;
var
  S: string;
  P: Integer;
begin
  S := Trim(ANome);
  if S.IsEmpty then
    Exit('Associado identificado');

  P := Pos(' ', S);
  if P <= 0 then
    Exit(S);

  Result := Copy(S, 1, P - 1) + ' ' + Copy(Trim(Copy(S, P + 1, MaxInt)), 1, 1) + '.';
end;

class function TEleicaoMelhoriasAPIService.GerarChaveRateLimit(const ACPF, AMatricula, AIP: string): string;
begin
  Result := UpperCase(
    THashSHA2.GetHashString(
      SomenteNumeros(ACPF) + '|' + Trim(AMatricula) + '|' + Trim(AIP),
      SHA256
    )
  );
end;

class procedure TEleicaoMelhoriasAPIService.EnsureSchema;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'CREATE TABLE IF NOT EXISTS eleicao_atualizacao_cadastral (' +
        ' id BIGINT NOT NULL AUTO_INCREMENT,' +
        ' empresa_id INT NOT NULL,' +
        ' usuario_id INT NOT NULL,' +
        ' pessoa_id INT NOT NULL,' +
        ' email_novo VARCHAR(180) NULL,' +
        ' telefone_novo VARCHAR(20) NULL,' +
        ' whatsapp_novo VARCHAR(20) NULL,' +
        ' situacao VARCHAR(20) NOT NULL DEFAULT ''PENDENTE'',' +
        ' ip_origem VARCHAR(64) NULL,' +
        ' user_agent VARCHAR(500) NULL,' +
        ' criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
        ' atualizado_em DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,' +
        ' processado_em DATETIME NULL,' +
        ' observacao VARCHAR(500) NULL,' +
        ' PRIMARY KEY (id),' +
        ' KEY idx_atualizacao_cadastral_situacao (situacao, criado_em),' +
        ' KEY idx_atualizacao_cadastral_pessoa (empresa_id, pessoa_id),' +
        ' CONSTRAINT fk_atualizacao_cadastral_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id),' +
        ' CONSTRAINT fk_atualizacao_cadastral_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id),' +
        ' CONSTRAINT fk_atualizacao_cadastral_pessoa FOREIGN KEY (pessoa_id) REFERENCES pessoa(id)' +
        ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci';
      Qry.Execute;

      Qry.SQL.Text :=
        'CREATE TABLE IF NOT EXISTS eleicao_atualizacao_cadastral_rate_limit (' +
        ' chave_hash CHAR(64) NOT NULL,' +
        ' tentativas INT NOT NULL DEFAULT 0,' +
        ' janela_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
        ' bloqueado_ate DATETIME NULL,' +
        ' atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,' +
        ' PRIMARY KEY (chave_hash)' +
        ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci';
      Qry.Execute;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoMelhoriasAPIService.VerificarRateLimit(const AChave: string);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
  JanelaInicio, BloqueadoAte: TDateTime;
  TemBloqueio: Boolean;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'SELECT tentativas, janela_inicio, bloqueado_ate, NOW() AS agora ' +
        'FROM eleicao_atualizacao_cadastral_rate_limit WHERE chave_hash = :chave LIMIT 1';
      Qry.ParamByName('chave').AsString := AChave;
      Qry.Open;
      if Qry.IsEmpty then
        Exit;

      JanelaInicio := Qry.FieldByName('janela_inicio').AsDateTime;
      TemBloqueio := not Qry.FieldByName('bloqueado_ate').IsNull;
      if TemBloqueio then
      begin
        BloqueadoAte := Qry.FieldByName('bloqueado_ate').AsDateTime;
        if BloqueadoAte > Qry.FieldByName('agora').AsDateTime then
          TAppErrors.RaiseBadRequest('Muitas tentativas de identificação. Tente novamente em alguns minutos.');
      end;

      if IncMinute(JanelaInicio, RATE_JANELA_MINUTOS) <= Qry.FieldByName('agora').AsDateTime then
      begin
        Qry.Close;
        Qry.SQL.Text := 'DELETE FROM eleicao_atualizacao_cadastral_rate_limit WHERE chave_hash = :chave';
        Qry.ParamByName('chave').AsString := AChave;
        Qry.Execute;
      end;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoMelhoriasAPIService.RegistrarFalhaRateLimit(const AChave: string);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'INSERT INTO eleicao_atualizacao_cadastral_rate_limit ' +
        '(chave_hash, tentativas, janela_inicio, bloqueado_ate) ' +
        'VALUES (:chave, 1, NOW(), NULL) ' +
        'ON DUPLICATE KEY UPDATE ' +
        ' tentativas = IF(TIMESTAMPDIFF(MINUTE, janela_inicio, NOW()) >= :janela, 1, tentativas + 1),' +
        ' janela_inicio = IF(TIMESTAMPDIFF(MINUTE, janela_inicio, NOW()) >= :janela, NOW(), janela_inicio),' +
        ' bloqueado_ate = CASE ' +
        '   WHEN TIMESTAMPDIFF(MINUTE, janela_inicio, NOW()) >= :janela THEN NULL ' +
        '   WHEN tentativas + 1 >= :maximo THEN DATE_ADD(NOW(), INTERVAL :bloqueio MINUTE) ' +
        '   ELSE bloqueado_ate END';
      Qry.ParamByName('chave').AsString := AChave;
      Qry.ParamByName('janela').AsInteger := RATE_JANELA_MINUTOS;
      Qry.ParamByName('maximo').AsInteger := RATE_MAX_TENTATIVAS;
      Qry.ParamByName('bloqueio').AsInteger := RATE_BLOQUEIO_MINUTOS;
      Qry.Execute;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoMelhoriasAPIService.LimparRateLimit(const AChave: string);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text := 'DELETE FROM eleicao_atualizacao_cadastral_rate_limit WHERE chave_hash = :chave';
      Qry.ParamByName('chave').AsString := AChave;
      Qry.Execute;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TEleicaoMelhoriasAPIService.AjustarExpiracaoOTP(const ASlug: string;
  const AIdEmpresa, AIdUsuario: Int64): Integer;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
begin
  Result := 0;
  if Trim(ASlug).IsEmpty or (AIdEmpresa <= 0) or (AIdUsuario <= 0) then
    Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'UPDATE eleicao_confirmacao c ' +
        'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id = c.eleicao_id AND ec.empresa_id = c.empresa_id ' +
        'SET c.expira_em = DATE_ADD(c.enviado_em, INTERVAL ' + IntToStr(OTP_EXPIRACAO_SEGUNDOS) + ' SECOND) ' +
        'WHERE c.empresa_id = :empresa AND c.usuario_id = :usuario ' +
        'AND LOWER(TRIM(ec.slug)) = LOWER(TRIM(:slug)) AND c.confirmado = ''N''';
      Qry.ParamByName('empresa').AsLargeInt := AIdEmpresa;
      Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
      Qry.ParamByName('slug').AsString := Trim(ASlug);
      Qry.Execute;

      Qry.SQL.Text :=
        'SELECT GREATEST(0, TIMESTAMPDIFF(SECOND, NOW(), c.expira_em)) AS segundos ' +
        'FROM eleicao_confirmacao c ' +
        'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id = c.eleicao_id AND ec.empresa_id = c.empresa_id ' +
        'WHERE c.empresa_id = :empresa AND c.usuario_id = :usuario ' +
        'AND LOWER(TRIM(ec.slug)) = LOWER(TRIM(:slug)) AND c.confirmado = ''N'' LIMIT 1';
      Qry.ParamByName('empresa').AsLargeInt := AIdEmpresa;
      Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
      Qry.ParamByName('slug').AsString := Trim(ASlug);
      Qry.Open;
      if not Qry.IsEmpty then
        Result := Qry.FieldByName('segundos').AsInteger;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TEleicaoMelhoriasAPIService.IdentificarAssociado(const ACPF, AMatricula, AIP: string): TAtualizacaoCadastralIdentificacaoResult;
var
  CPF, Matricula, Chave: string;
  MatriculaInt, Quantidade: Integer;
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
  IdUsuario, IdEmpresa: Int64;
  Nome: string;
  Roles: TArray<string>;
begin
  Result.Identificado := '';
  Result.Nome := '';
  Result.Token := '';

  CPF := SomenteNumeros(ACPF);
  Matricula := Trim(AMatricula);

  if Length(CPF) <> 11 then
    TAppErrors.RaiseBadRequest('Informe um CPF válido.');
  if not TryStrToInt(Matricula, MatriculaInt) then
    TAppErrors.RaiseBadRequest('Informe uma matrícula válida.');

  Chave := GerarChaveRateLimit(CPF, Matricula, AIP);
  VerificarRateLimit(Chave);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'SELECT u.id AS id_usuario, p.empresa_id, p.nome ' +
        'FROM pessoa p INNER JOIN usuario u ON u.pessoa_id = p.id AND u.empresa_id = p.empresa_id ' +
        'WHERE REPLACE(REPLACE(REPLACE(TRIM(p.cpf), ''.'', ''''), ''-'', ''''), '' '', '''') = :cpf ' +
        'AND p.matricula = :matricula AND p.ativo = ''S'' AND p.excluido = 0 ' +
        'AND p.bloqueado = ''N'' AND u.ativo = ''S'' ' +
        'GROUP BY u.id, p.empresa_id, p.nome LIMIT 2';
      Qry.ParamByName('cpf').AsString := CPF;
      Qry.ParamByName('matricula').AsInteger := MatriculaInt;
      Qry.Open;

      Quantidade := 0;
      IdUsuario := 0;
      IdEmpresa := 0;
      Nome := '';
      while not Qry.Eof do
      begin
        Inc(Quantidade);
        if Quantidade = 1 then
        begin
          IdUsuario := Qry.FieldByName('id_usuario').AsLargeInt;
          IdEmpresa := Qry.FieldByName('empresa_id').AsLargeInt;
          Nome := Qry.FieldByName('nome').AsString;
        end;
        Qry.Next;
      end;

      if Quantidade <> 1 then
      begin
        RegistrarFalhaRateLimit(Chave);
        TAppErrors.RaiseUnauthorized('Não foi possível localizar um cadastro único com os dados informados.');
      end;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;

  LimparRateLimit(Chave);
  SetLength(Roles, 1);
  Roles[0] := 'ATUALIZACAO_CADASTRAL';

  Result.Identificado := 'S';
  Result.Nome := MascararNome(Nome);
  Result.Token := TAppJWT.GerarToken(
    Config.JWT,
    IdUsuario,
    IdEmpresa,
    Roles,
    'atualizacao-cadastral',
    Config.JWT.TtlIdentificacaoMinutos
  );
end;

class function TEleicaoMelhoriasAPIService.SolicitarAtualizacao(const AIdEmpresa, AIdUsuario: Int64;
  const AEmail, ATelefone, AWhatsapp, AIP, AUserAgent: string): TAtualizacaoCadastralSolicitacaoResult;
var
  Email, Telefone, Whatsapp: string;
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
  IdPessoa: Int64;
begin
  Result.IdSolicitacao := 0;
  Result.Situacao := '';

  Email := Trim(AEmail);
  Telefone := SomenteNumeros(ATelefone);
  Whatsapp := SomenteNumeros(AWhatsapp);

  if Email.IsEmpty and Telefone.IsEmpty and Whatsapp.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe ao menos um dado de contato para atualização.');
  if (not Email.IsEmpty) and (Pos('@', Email) <= 1) then
    TAppErrors.RaiseBadRequest('Informe um e-mail válido.');
  if (not Telefone.IsEmpty) and ((Length(Telefone) < 10) or (Length(Telefone) > 13)) then
    TAppErrors.RaiseBadRequest('Informe um telefone válido.');
  if (not Whatsapp.IsEmpty) and ((Length(Whatsapp) < 10) or (Length(Whatsapp) > 13)) then
    TAppErrors.RaiseBadRequest('Informe um WhatsApp válido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'SELECT p.id AS pessoa_id FROM usuario u ' +
        'INNER JOIN pessoa p ON p.id = u.pessoa_id AND p.empresa_id = u.empresa_id ' +
        'WHERE u.id = :usuario AND u.empresa_id = :empresa AND u.ativo = ''S'' ' +
        'AND p.ativo = ''S'' AND p.excluido = 0 LIMIT 1';
      Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
      Qry.ParamByName('empresa').AsLargeInt := AIdEmpresa;
      Qry.Open;
      if Qry.IsEmpty then
        TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');
      IdPessoa := Qry.FieldByName('pessoa_id').AsLargeInt;

      Qry.Close;
      Qry.SQL.Text :=
        'SELECT id FROM eleicao_atualizacao_cadastral ' +
        'WHERE empresa_id = :empresa AND usuario_id = :usuario AND pessoa_id = :pessoa ' +
        'AND situacao = ''PENDENTE'' ORDER BY id DESC LIMIT 1';
      Qry.ParamByName('empresa').AsLargeInt := AIdEmpresa;
      Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
      Qry.ParamByName('pessoa').AsLargeInt := IdPessoa;
      Qry.Open;

      if Qry.IsEmpty then
      begin
        Qry.Close;
        Qry.SQL.Text :=
          'INSERT INTO eleicao_atualizacao_cadastral ' +
          '(empresa_id, usuario_id, pessoa_id, email_novo, telefone_novo, whatsapp_novo, situacao, ip_origem, user_agent) ' +
          'VALUES (:empresa, :usuario, :pessoa, :email, :telefone, :whatsapp, ''PENDENTE'', :ip, :agent)';
        Qry.ParamByName('empresa').AsLargeInt := AIdEmpresa;
        Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
        Qry.ParamByName('pessoa').AsLargeInt := IdPessoa;
        Qry.ParamByName('email').AsString := Email;
        Qry.ParamByName('telefone').AsString := Telefone;
        Qry.ParamByName('whatsapp').AsString := Whatsapp;
        Qry.ParamByName('ip').AsString := Copy(Trim(AIP), 1, 64);
        Qry.ParamByName('agent').AsString := Copy(Trim(AUserAgent), 1, 500);
        Qry.Execute;

        // UniDAC desta versão não expõe LastInsertId em TUniConnection.
        // Consulta o AUTO_INCREMENT gerado usando a mesma conexão MySQL.
        Qry.Close;
        Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
        Qry.Open;
        Result.IdSolicitacao := Qry.FieldByName('id').AsLargeInt;
      end
      else
      begin
        Result.IdSolicitacao := Qry.FieldByName('id').AsLargeInt;
        Qry.Close;
        Qry.SQL.Text :=
          'UPDATE eleicao_atualizacao_cadastral SET email_novo = :email, telefone_novo = :telefone, ' +
          'whatsapp_novo = :whatsapp, ip_origem = :ip, user_agent = :agent, atualizado_em = NOW() ' +
          'WHERE id = :id AND situacao = ''PENDENTE''';
        Qry.ParamByName('email').AsString := Email;
        Qry.ParamByName('telefone').AsString := Telefone;
        Qry.ParamByName('whatsapp').AsString := Whatsapp;
        Qry.ParamByName('ip').AsString := Copy(Trim(AIP), 1, 64);
        Qry.ParamByName('agent').AsString := Copy(Trim(AUserAgent), 1, 500);
        Qry.ParamByName('id').AsLargeInt := Result.IdSolicitacao;
        Qry.Execute;
      end;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;

  Result.Situacao := 'PENDENTE';
end;

end.
