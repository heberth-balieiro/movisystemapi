unit PlataformaEmail.DAO;

interface

uses
  Uni,
  PlataformaEmail.Model;

type
  TPlataformaEmailDAO = class
  public
    class function Buscar(
      const AConn: TUniConnection
    ): TPlataformaEmailConfig; static;

    class function TemSenha(
      const AConn: TUniConnection
    ): Boolean; static;

    class function ObterSenha(
      const AConn: TUniConnection;
      const ASecret: string
    ): string; static;

    class procedure Salvar(
      const AConn: TUniConnection;
      const ADados: TPlataformaEmailInput;
      const ASecret: string
    ); static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const AIP,
            AUserAgent: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TPlataformaEmailDAO.Buscar(
  const AConn: TUniConnection
): TPlataformaEmailConfig;
var
  Qry: TUniQuery;
begin
  Result := Default(TPlataformaEmailConfig);
  Result.SmtpPorta := 587;
  Result.Seguranca := 'STARTTLS';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ativo, smtp_host, smtp_porta, seguranca, usuario, ' +
      '       senha_criptografada, senha_hint, ' +
      '       remetente_nome, remetente_email, responder_para ' +
      'FROM plataforma_email_configuracao ' +
      'WHERE id = 1';

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
      Result.SenhaMascarada :=
        '********' + Qry.FieldByName('senha_hint').AsString;

    Result.RemetenteNome := Qry.FieldByName('remetente_nome').AsString;
    Result.RemetenteEmail := Qry.FieldByName('remetente_email').AsString;
    Result.ResponderPara := Qry.FieldByName('responder_para').AsString;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaEmailDAO.TemSenha(
  const AConn: TUniConnection
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT senha_criptografada ' +
      'FROM plataforma_email_configuracao ' +
      'WHERE id = 1';

    Qry.Open;

    Result :=
      (not Qry.IsEmpty) and
      (not Qry.FieldByName('senha_criptografada').IsNull);
  finally
    Qry.Free;
  end;
end;

class function TPlataformaEmailDAO.ObterSenha(
  const AConn: TUniConnection;
  const ASecret: string
): string;
var
  Qry: TUniQuery;
begin
  Result := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT CAST(AES_DECRYPT(senha_criptografada, :secret) AS CHAR(4096)) AS senha ' +
      'FROM plataforma_email_configuracao ' +
      'WHERE id = 1 ' +
      '  AND senha_criptografada IS NOT NULL';

    Qry.ParamByName('secret').AsString := ASecret;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('senha').AsString;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaEmailDAO.Salvar(
  const AConn: TUniConnection;
  const ADados: TPlataformaEmailInput;
  const ASecret: string
);
var
  Qry: TUniQuery;
  Hint: string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    if not Trim(ADados.Senha).IsEmpty then
    begin
      if Length(ADados.Senha) <= 4 then
        Hint := ADados.Senha
      else
        Hint := Copy(ADados.Senha, Length(ADados.Senha) - 3, 4);

      Qry.SQL.Text :=
        'INSERT INTO plataforma_email_configuracao (' +
        ' id, ativo, smtp_host, smtp_porta, seguranca, usuario, ' +
        ' senha_criptografada, senha_hint, remetente_nome, remetente_email, responder_para' +
        ') VALUES (' +
        ' 1, :ativo, :smtp_host, :smtp_porta, :seguranca, :usuario, ' +
        ' AES_ENCRYPT(:senha, :secret), :senha_hint, :remetente_nome, :remetente_email, NULLIF(:responder_para, '''')' +
        ') ON DUPLICATE KEY UPDATE ' +
        ' ativo = VALUES(ativo), smtp_host = VALUES(smtp_host), smtp_porta = VALUES(smtp_porta), ' +
        ' seguranca = VALUES(seguranca), usuario = VALUES(usuario), ' +
        ' senha_criptografada = VALUES(senha_criptografada), senha_hint = VALUES(senha_hint), ' +
        ' remetente_nome = VALUES(remetente_nome), remetente_email = VALUES(remetente_email), ' +
        ' responder_para = VALUES(responder_para)';
    end
    else
    begin
      Qry.SQL.Text :=
        'INSERT INTO plataforma_email_configuracao (' +
        ' id, ativo, smtp_host, smtp_porta, seguranca, usuario, ' +
        ' remetente_nome, remetente_email, responder_para' +
        ') VALUES (' +
        ' 1, :ativo, :smtp_host, :smtp_porta, :seguranca, :usuario, ' +
        ' :remetente_nome, :remetente_email, NULLIF(:responder_para, '''')' +
        ') ON DUPLICATE KEY UPDATE ' +
        ' ativo = VALUES(ativo), smtp_host = VALUES(smtp_host), smtp_porta = VALUES(smtp_porta), ' +
        ' seguranca = VALUES(seguranca), usuario = VALUES(usuario), ' +
        ' remetente_nome = VALUES(remetente_nome), remetente_email = VALUES(remetente_email), ' +
        ' responder_para = VALUES(responder_para)';
    end;

    Qry.ParamByName('ativo').AsBoolean := ADados.Ativo;
    Qry.ParamByName('smtp_host').AsString := ADados.SmtpHost;
    Qry.ParamByName('smtp_porta').AsInteger := ADados.SmtpPorta;
    Qry.ParamByName('seguranca').AsString := ADados.Seguranca;
    Qry.ParamByName('usuario').AsString := ADados.Usuario;
    Qry.ParamByName('remetente_nome').AsString := ADados.RemetenteNome;
    Qry.ParamByName('remetente_email').AsString := ADados.RemetenteEmail;
    Qry.ParamByName('responder_para').AsString := ADados.ResponderPara;

    if not Trim(ADados.Senha).IsEmpty then
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

class procedure TPlataformaEmailDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const AIP,
        AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, ' +
      'acao, entidade, registro_id, metodo_http, rota, ' +
      'ip, user_agent, sucesso, mensagem) ' +
      'VALUES ' +
      '(NULL, :id_usuario, NULL, ' +
      '''PLATAFORMA_EMAIL_CONFIG_ALTERADA'', ' +
      '''plataforma_email_configuracao'', ''1'', ''PUT'', ' +
      '''/v1/certifica/plataforma/configuracoes/email'', ' +
      ':ip, :user_agent, 1, ' +
      '''Configuração global de e-mail da plataforma atualizada.'')';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('ip').AsString := Copy(Trim(AIP), 1, 45);
    Qry.ParamByName('user_agent').AsString := Copy(Trim(AUserAgent), 1, 1000);
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
