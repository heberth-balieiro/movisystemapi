unit PlataformaAuth.DAO;

interface
uses
  Uni;
type
  // DTO enxuto usado somente durante a autenticação global da MoviSystem.
  TPlataformaAuthUsuario = record
    IdUsuario: Int64;
    Nome: string;
    Email: string;
    SenhaHash: string;
    Situacao: string;
    IsSuperAdmin: Boolean;
  end;
  TPlataformaAuthDAO = class
  public
    class function BuscarSuperAdminPorEmail(const AConn: TUniConnection; const AEmail: string;
      out AUsuario: TPlataformaAuthUsuario): Boolean; static;
    class procedure AtualizarUltimoLogin(const AConn: TUniConnection; const AIdUsuario: Int64); static;
    class procedure RegistrarAuditoriaLogin(const AConn: TUniConnection; const AIdUsuario: Int64;
      const ASucesso: Boolean; const AMensagem, AIP, AUserAgent: string); static;
  end;
implementation
uses
  System.SysUtils;
class function TPlataformaAuthDAO.BuscarSuperAdminPorEmail(const AConn: TUniConnection;
  const AEmail: string; out AUsuario: TPlataformaAuthUsuario): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AUsuario := Default(TPlataformaAuthUsuario);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id, nome, email, senha_hash, situacao, is_super_admin ' +
      'FROM usuario ' +
      'WHERE email_normalizado = :email ' +
      '  AND is_super_admin = 1 ' +
      'LIMIT 1';
    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmail));
    Qry.Open;
    if Qry.IsEmpty then
      Exit;
    AUsuario.IdUsuario    := Qry.FieldByName('id').AsLargeInt;
    AUsuario.Nome         := Qry.FieldByName('nome').AsString;
    AUsuario.Email        := Qry.FieldByName('email').AsString;
    AUsuario.SenhaHash    := Qry.FieldByName('senha_hash').AsString;
    AUsuario.Situacao     := Qry.FieldByName('situacao').AsString;
    AUsuario.IsSuperAdmin := Qry.FieldByName('is_super_admin').AsBoolean;
    Result := True;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaAuthDAO.AtualizarUltimoLogin(const AConn: TUniConnection;
  const AIdUsuario: Int64);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE usuario SET ultimo_login_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id = :id_usuario AND is_super_admin = 1';
    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaAuthDAO.RegistrarAuditoriaLogin(const AConn: TUniConnection;
  const AIdUsuario: Int64; const ASucesso: Boolean; const AMensagem, AIP, AUserAgent: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, acao, entidade, registro_id, ' +
      ' metodo_http, rota, ip, user_agent, sucesso, mensagem) ' +
      'VALUES ' +
      '(NULL, :id_usuario, NULL, ''PLATAFORMA_LOGIN'', ''usuario'', :registro_id, ' +
      ' ''POST'', ''/v1/cursos/plataforma/auth/login'', :ip, :user_agent, :sucesso, :mensagem)';
    if AIdUsuario > 0 then
    begin
      Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
      Qry.ParamByName('registro_id').AsString := AIdUsuario.ToString;
    end
    else
    begin
      Qry.ParamByName('id_usuario').Clear;
      Qry.ParamByName('registro_id').Clear;
    end;
    Qry.ParamByName('ip').AsString        := Copy(Trim(AIP), 1, 45);
    Qry.ParamByName('user_agent').AsString:= Copy(Trim(AUserAgent), 1, 1000);
    Qry.ParamByName('sucesso').AsInteger  := Ord(ASucesso);
    Qry.ParamByName('mensagem').AsString  := Copy(Trim(AMensagem), 1, 1000);
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.

