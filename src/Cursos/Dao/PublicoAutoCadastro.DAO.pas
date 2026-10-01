unit PublicoAutoCadastro.DAO;

interface

uses
  Uni;

type
  TPublicoAutoCadastroInstituicao = record
    Encontrada: Boolean;
    IdInstituicao: Int64;
    Nome: string;
    Situacao: string;
    PermitirAutoCadastro: Boolean;
  end;

  TPublicoAutoCadastroUsuario = record
    Encontrado: Boolean;
    IdUsuario: Int64;
    SenhaHash: string;
    Situacao: string;
  end;

  TPublicoAutoCadastroDAO = class
  public
    class function BuscarInstituicao(
      const AConn: TUniConnection;
      const ASlug: string
    ): TPublicoAutoCadastroInstituicao; static;

    class function BuscarUsuarioPorEmail(
      const AConn: TUniConnection;
      const AEmailNormalizado: string
    ): TPublicoAutoCadastroUsuario; static;

    class function BuscarUsuarioInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdUsuario: Int64
    ): Int64; static;

    class function ParticipanteVinculado(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdUsuarioInstituicao: Int64
    ): Boolean; static;

    class function ExisteCpf(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACpfHash: string
    ): Boolean; static;

    class function CodigoPublicoExiste(
      const AConn: TUniConnection;
      const ACodigoPublico: string
    ): Boolean; static;

    class function CriarUsuario(
      const AConn: TUniConnection;
      const ANome, AEmail, AEmailNormalizado, ASenhaHash: string
    ): Int64; static;

    class function CriarUsuarioInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdUsuario: Int64
    ): Int64; static;

    class function CriarParticipante(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdUsuarioInstituicao: Int64;
      const ACodigoPublico, ANome, ACpfHash, ACpfMascarado,
            AEmail, ATelefone: string
    ): Int64; static;

    class procedure RegistrarAceitesVigentes(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdParticipante: Int64
    ); static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdUsuarioInstituicao, AIdParticipante: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TPublicoAutoCadastroDAO.BuscarInstituicao(
  const AConn: TUniConnection;
  const ASlug: string
): TPublicoAutoCadastroInstituicao;
var
  Q: TUniQuery;
begin
  Result := Default(TPublicoAutoCadastroInstituicao);
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT i.id, i.nome_fantasia, i.situacao, ' +
      'COALESCE(ic.permitir_auto_cadastro,0) AS permitir_auto_cadastro ' +
      'FROM instituicao i ' +
      'LEFT JOIN instituicao_configuracao ic ON ic.id_instituicao=i.id ' +
      'WHERE i.slug=:slug LIMIT 1';
    Q.ParamByName('slug').AsString := LowerCase(Trim(ASlug));
    Q.Open;
    if Q.IsEmpty then Exit;

    Result.Encontrada := True;
    Result.IdInstituicao := Q.FieldByName('id').AsLargeInt;
    Result.Nome := Q.FieldByName('nome_fantasia').AsString;
    Result.Situacao := Q.FieldByName('situacao').AsString;
    Result.PermitirAutoCadastro := Q.FieldByName('permitir_auto_cadastro').AsInteger = 1;
  finally
    Q.Free;
  end;
end;

class function TPublicoAutoCadastroDAO.BuscarUsuarioPorEmail(
  const AConn: TUniConnection;
  const AEmailNormalizado: string
): TPublicoAutoCadastroUsuario;
var
  Q: TUniQuery;
begin
  Result := Default(TPublicoAutoCadastroUsuario);
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT id, senha_hash, situacao FROM usuario ' +
      'WHERE email_normalizado=:email LIMIT 1';
    Q.ParamByName('email').AsString := LowerCase(Trim(AEmailNormalizado));
    Q.Open;
    if Q.IsEmpty then Exit;

    Result.Encontrado := True;
    Result.IdUsuario := Q.FieldByName('id').AsLargeInt;
    Result.SenhaHash := Q.FieldByName('senha_hash').AsString;
    Result.Situacao := Q.FieldByName('situacao').AsString;
  finally
    Q.Free;
  end;
end;

class function TPublicoAutoCadastroDAO.BuscarUsuarioInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdUsuario: Int64
): Int64;
var
  Q: TUniQuery;
begin
  Result := 0;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT id FROM usuario_instituicao ' +
      'WHERE id_instituicao=:id_instituicao AND id_usuario=:id_usuario LIMIT 1';
    Q.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Q.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Q.Open;
    if not Q.IsEmpty then
      Result := Q.FieldByName('id').AsLargeInt;
  finally
    Q.Free;
  end;
end;

class function TPublicoAutoCadastroDAO.ParticipanteVinculado(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdUsuarioInstituicao: Int64
): Boolean;
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT 1 FROM participante ' +
      'WHERE id_instituicao=:id_instituicao ' +
      'AND id_usuario_instituicao=:id_usuario_instituicao LIMIT 1';
    Q.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Q.ParamByName('id_usuario_instituicao').AsLargeInt := AIdUsuarioInstituicao;
    Q.Open;
    Result := not Q.IsEmpty;
  finally
    Q.Free;
  end;
end;

class function TPublicoAutoCadastroDAO.ExisteCpf(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACpfHash: string
): Boolean;
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT 1 FROM participante ' +
      'WHERE id_instituicao=:id_instituicao AND cpf_hash_busca=:cpf LIMIT 1';
    Q.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Q.ParamByName('cpf').AsString := ACpfHash;
    Q.Open;
    Result := not Q.IsEmpty;
  finally
    Q.Free;
  end;
end;

class function TPublicoAutoCadastroDAO.CodigoPublicoExiste(
  const AConn: TUniConnection;
  const ACodigoPublico: string
): Boolean;
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'SELECT 1 FROM participante WHERE codigo_publico=:codigo LIMIT 1';
    Q.ParamByName('codigo').AsString := ACodigoPublico;
    Q.Open;
    Result := not Q.IsEmpty;
  finally
    Q.Free;
  end;
end;

class function TPublicoAutoCadastroDAO.CriarUsuario(
  const AConn: TUniConnection;
  const ANome, AEmail, AEmailNormalizado, ASenhaHash: string
): Int64;
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO usuario ' +
      '(nome,email,email_normalizado,senha_hash,is_super_admin,situacao,senha_alterada_em) ' +
      'VALUES (:nome,:email,:email_normalizado,:senha_hash,0,''ATIVO'',CURRENT_TIMESTAMP(3))';
    Q.ParamByName('nome').AsString := ANome;
    Q.ParamByName('email').AsString := AEmail;
    Q.ParamByName('email_normalizado').AsString := AEmailNormalizado;
    Q.ParamByName('senha_hash').AsString := ASenhaHash;
    Q.ExecSQL;
    Q.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Q.Open;
    Result := Q.FieldByName('id').AsLargeInt;
  finally
    Q.Free;
  end;
end;

class function TPublicoAutoCadastroDAO.CriarUsuarioInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdUsuario: Int64
): Int64;
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO usuario_instituicao ' +
      '(id_instituicao,id_usuario,id_unidade_organizacional,login,situacao,principal) ' +
      'VALUES (:id_instituicao,:id_usuario,NULL,NULL,''ATIVO'',0)';
    Q.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Q.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Q.ExecSQL;
    Q.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Q.Open;
    Result := Q.FieldByName('id').AsLargeInt;
  finally
    Q.Free;
  end;
end;

class function TPublicoAutoCadastroDAO.CriarParticipante(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdUsuarioInstituicao: Int64;
  const ACodigoPublico, ANome, ACpfHash, ACpfMascarado,
        AEmail, ATelefone: string
): Int64;
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO participante ' +
      '(id_instituicao,id_unidade_organizacional,id_usuario_instituicao,codigo_publico,' +
      'nome,cpf_criptografado,cpf_hash_busca,cpf_mascarado,email,matricula,telefone,' +
      'orgao_empresa,cargo,situacao,criado_por) ' +
      'VALUES (:id_instituicao,NULL,:id_usuario_instituicao,:codigo_publico,' +
      ':nome,NULL,:cpf_hash,:cpf_mascarado,:email,NULL,:telefone,NULL,NULL,''ATIVO'',NULL)';
    Q.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Q.ParamByName('id_usuario_instituicao').AsLargeInt := AIdUsuarioInstituicao;
    Q.ParamByName('codigo_publico').AsString := ACodigoPublico;
    Q.ParamByName('nome').AsString := ANome;
    Q.ParamByName('cpf_hash').AsString := ACpfHash;
    Q.ParamByName('cpf_mascarado').AsString := ACpfMascarado;
    Q.ParamByName('email').AsString := AEmail;
    if Trim(ATelefone).IsEmpty then
      Q.ParamByName('telefone').Clear
    else
      Q.ParamByName('telefone').AsString := ATelefone;
    Q.ExecSQL;
    Q.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Q.Open;
    Result := Q.FieldByName('id').AsLargeInt;
  finally
    Q.Free;
  end;
end;

class procedure TPublicoAutoCadastroDAO.RegistrarAceitesVigentes(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdParticipante: Int64
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO termo_aceite ' +
      '(id_instituicao,id_termo,id_participante,id_usuario_instituicao,aceito_em) ' +
      'SELECT id_instituicao,id,:id_participante,NULL,CURRENT_TIMESTAMP(3) ' +
      'FROM termo WHERE id_instituicao=:id_instituicao AND vigente=1 ' +
      'AND tipo IN (''PRIVACIDADE'',''USO'',''CONSENTIMENTO'')';
    Q.ParamByName('id_participante').AsLargeInt := AIdParticipante;
    Q.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class procedure TPublicoAutoCadastroDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdUsuarioInstituicao, AIdParticipante: Int64
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao,id_usuario,id_usuario_instituicao,acao,entidade,registro_id,' +
      'metodo_http,rota,sucesso,mensagem) ' +
      'VALUES (:id_instituicao,NULL,:id_usuario_instituicao,''PARTICIPANTE_AUTO_CADASTRO'',' +
      '''participante'',:registro_id,''POST'',''/v1/certifica/publico/instituicoes/:slug/auto-cadastro'',1,' +
      '''Participante realizou auto cadastro no portal publico.'')';
    Q.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Q.ParamByName('id_usuario_instituicao').AsLargeInt := AIdUsuarioInstituicao;
    Q.ParamByName('registro_id').AsString := AIdParticipante.ToString;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
