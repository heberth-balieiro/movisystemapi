unit EleicaoEmailConfigAPI.Repository;

interface

uses
  Uni,
  EleicaoEmailConfigAPI.Model;

type
  TEleicaoEmailConfigRepository = class
  public
    class procedure GarantirSchema(const AConn: TUniConnection); static;
    class function Buscar(const AConn: TUniConnection; const AIdEmpresa: Integer): TEleicaoEmailConfig; static;
    class function TemSenha(const AConn: TUniConnection; const AIdEmpresa: Integer): Boolean; static;
    class procedure Salvar(const AConn: TUniConnection; const AIdEmpresa: Integer;
      const ADados: TEleicaoEmailInput; const ASecret: string); static;
    class function ObterSenha(const AConn: TUniConnection; const AIdEmpresa: Integer;
      const ASecret: string): string; static;
  end;

implementation

uses
  System.SysUtils;

class procedure TEleicaoEmailConfigRepository.GarantirSchema(const AConn: TUniConnection);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS empresa_email_configuracao (' +
      ' empresa_id INT NOT NULL,' +
      ' ativo TINYINT(1) NOT NULL DEFAULT 0,' +
      ' smtp_host VARCHAR(255) NOT NULL DEFAULT '''',' +
      ' smtp_porta SMALLINT UNSIGNED NOT NULL DEFAULT 587,' +
      ' seguranca VARCHAR(20) NOT NULL DEFAULT ''STARTTLS'',' +
      ' usuario VARCHAR(254) NOT NULL DEFAULT '''',' +
      ' senha_criptografada VARBINARY(4096) NULL,' +
      ' senha_hint VARCHAR(16) NULL,' +
      ' remetente_nome VARCHAR(180) NOT NULL DEFAULT '''',' +
      ' remetente_email VARCHAR(254) NOT NULL DEFAULT '''',' +
      ' responder_para VARCHAR(254) NULL,' +
      ' criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
      ' atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,' +
      ' PRIMARY KEY (empresa_id),' +
      ' CONSTRAINT fk_empresa_email_configuracao_empresa ' +
      ' FOREIGN KEY (empresa_id) REFERENCES empresa(id)' +
      ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci';
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoEmailConfigRepository.Buscar(const AConn: TUniConnection;
  const AIdEmpresa: Integer): TEleicaoEmailConfig;
var
  Qry: TUniQuery;
begin
  Result := Default(TEleicaoEmailConfig);
  Result.SmtpPorta := 587;
  Result.Seguranca := 'STARTTLS';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ativo, smtp_host, smtp_porta, seguranca, usuario, ' +
      'senha_criptografada, senha_hint, remetente_nome, remetente_email, responder_para ' +
      'FROM empresa_email_configuracao WHERE empresa_id = :empresa_id LIMIT 1';
    Qry.ParamByName('empresa_id').AsInteger := AIdEmpresa;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Ativo := Qry.FieldByName('ativo').AsBoolean;
    Result.SmtpHost := Qry.FieldByName('smtp_host').AsString;
    Result.SmtpPorta := Qry.FieldByName('smtp_porta').AsInteger;
    Result.Seguranca := Qry.FieldByName('seguranca').AsString;
    Result.Usuario := Qry.FieldByName('usuario').AsString;
    Result.SenhaConfigurada := not Qry.FieldByName('senha_criptografada').IsNull;
    if Result.SenhaConfigurada then
      Result.SenhaMascarada := '********' + Qry.FieldByName('senha_hint').AsString;
    Result.RemetenteNome := Qry.FieldByName('remetente_nome').AsString;
    Result.RemetenteEmail := Qry.FieldByName('remetente_email').AsString;
    Result.ResponderPara := Qry.FieldByName('responder_para').AsString;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoEmailConfigRepository.TemSenha(const AConn: TUniConnection;
  const AIdEmpresa: Integer): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT senha_criptografada FROM empresa_email_configuracao ' +
      'WHERE empresa_id = :empresa_id LIMIT 1';
    Qry.ParamByName('empresa_id').AsInteger := AIdEmpresa;
    Qry.Open;
    Result := (not Qry.IsEmpty) and (not Qry.FieldByName('senha_criptografada').IsNull);
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoEmailConfigRepository.Salvar(const AConn: TUniConnection;
  const AIdEmpresa: Integer; const ADados: TEleicaoEmailInput; const ASecret: string);
var
  Qry: TUniQuery;
  Hint: string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    if not ADados.Senha.IsEmpty then
    begin
      if Length(ADados.Senha) <= 4 then
        Hint := ADados.Senha
      else
        Hint := Copy(ADados.Senha, Length(ADados.Senha) - 3, 4);

      Qry.SQL.Text :=
        'INSERT INTO empresa_email_configuracao (' +
        'empresa_id, ativo, smtp_host, smtp_porta, seguranca, usuario, ' +
        'senha_criptografada, senha_hint, remetente_nome, remetente_email, responder_para) ' +
        'VALUES (:empresa_id, :ativo, :smtp_host, :smtp_porta, :seguranca, :usuario, ' +
        'AES_ENCRYPT(:senha, :secret), :senha_hint, :remetente_nome, :remetente_email, NULLIF(:responder_para, '''')) ' +
        'ON DUPLICATE KEY UPDATE ' +
        'ativo=VALUES(ativo), smtp_host=VALUES(smtp_host), smtp_porta=VALUES(smtp_porta), ' +
        'seguranca=VALUES(seguranca), usuario=VALUES(usuario), ' +
        'senha_criptografada=VALUES(senha_criptografada), senha_hint=VALUES(senha_hint), ' +
        'remetente_nome=VALUES(remetente_nome), remetente_email=VALUES(remetente_email), ' +
        'responder_para=VALUES(responder_para)';
    end
    else
    begin
      Qry.SQL.Text :=
        'INSERT INTO empresa_email_configuracao (' +
        'empresa_id, ativo, smtp_host, smtp_porta, seguranca, usuario, ' +
        'remetente_nome, remetente_email, responder_para) ' +
        'VALUES (:empresa_id, :ativo, :smtp_host, :smtp_porta, :seguranca, :usuario, ' +
        ':remetente_nome, :remetente_email, NULLIF(:responder_para, '''')) ' +
        'ON DUPLICATE KEY UPDATE ' +
        'ativo=VALUES(ativo), smtp_host=VALUES(smtp_host), smtp_porta=VALUES(smtp_porta), ' +
        'seguranca=VALUES(seguranca), usuario=VALUES(usuario), ' +
        'remetente_nome=VALUES(remetente_nome), remetente_email=VALUES(remetente_email), ' +
        'responder_para=VALUES(responder_para)';
    end;

    Qry.ParamByName('empresa_id').AsInteger := AIdEmpresa;
    Qry.ParamByName('ativo').AsBoolean := ADados.Ativo;
    Qry.ParamByName('smtp_host').AsString := ADados.SmtpHost;
    Qry.ParamByName('smtp_porta').AsInteger := ADados.SmtpPorta;
    Qry.ParamByName('seguranca').AsString := ADados.Seguranca;
    Qry.ParamByName('usuario').AsString := ADados.Usuario;
    Qry.ParamByName('remetente_nome').AsString := ADados.RemetenteNome;
    Qry.ParamByName('remetente_email').AsString := ADados.RemetenteEmail;
    Qry.ParamByName('responder_para').AsString := ADados.ResponderPara;

    if not ADados.Senha.IsEmpty then
    begin
      Qry.ParamByName('senha').AsString := ADados.Senha;
      Qry.ParamByName('secret').AsString := ASecret;
      Qry.ParamByName('senha_hint').AsString := Hint;
    end;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoEmailConfigRepository.ObterSenha(const AConn: TUniConnection;
  const AIdEmpresa: Integer; const ASecret: string): string;
var
  Qry: TUniQuery;
begin
  Result := '';
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT CAST(AES_DECRYPT(senha_criptografada, :secret) AS CHAR(4096)) AS senha ' +
      'FROM empresa_email_configuracao ' +
      'WHERE empresa_id = :empresa_id AND senha_criptografada IS NOT NULL LIMIT 1';
    Qry.ParamByName('secret').AsString := ASecret;
    Qry.ParamByName('empresa_id').AsInteger := AIdEmpresa;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('senha').AsString;
  finally
    Qry.Free;
  end;
end;

end.
