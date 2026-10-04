unit Usuarios.Dao;

interface

uses
  System.SysUtils,
  Uni,
  Usuarios.Model;

type
  TUsuariosDao = class
  public
    class function BuscarPessoaId(const AConn: TUniConnection; const AEmpresaId, AIdSocio: Integer): Integer; static;
    class function ExisteUsuario(const AConn: TUniConnection; const AIdEmpresa: Int64; const APessoaId: Integer): Boolean; static;
    class function ExisteUsuarioSistema(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIdUsuarioInt: Integer): Boolean; static;
    class function Inserir(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TUsuariosModel): Int64; static;
    class function Atualizar(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TUsuariosModel): Boolean; static;
    class function AtualizarUsuarioSistema(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TUsuariosModel): Boolean; static;
  end;

implementation

{ TUsuariosDao }

class function TUsuariosDao.BuscarPessoaId(const AConn: TUniConnection; const AEmpresaId, AIdSocio: Integer): Integer;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT id FROM pessoa WHERE empresa_id= :empresa_id AND id_socio= :id_socio LIMIT 1';
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('empresa_id').AsInteger := AEmpresaId;
    Qry.ParamByName('id_socio').AsInteger := AIdSocio;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsInteger;
  finally
    Qry.Free;
  end;
end;

class function TUsuariosDao.ExisteUsuario(const AConn: TUniConnection; const AIdEmpresa: Int64; const APessoaId: Integer): Boolean;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT 1 FROM usuario WHERE empresa_id=:empresa_id AND pessoa_id=:pessoa_id LIMIT 1';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('empresa_id').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('pessoa_id').AsInteger := APessoaId;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TUsuariosDao.ExisteUsuarioSistema(const AConn: TUniConnection;
  const AIdEmpresa: Int64; const AIdUsuarioInt: Integer): Boolean;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT 1 FROM usuario WHERE empresa_id=:empresa_id AND id_usuario_int=:id_usuario_int LIMIT 1';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('empresa_id').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_usuario_int').AsInteger := AIdUsuarioInt;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TUsuariosDao.Inserir(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TUsuariosModel): Int64;
var
  Qry: TUniQuery;
const
  StrSql =
    'INSERT INTO usuario(empresa_id,pessoa_id,nome,login,senha_hash,ativo,email, id_eleitor_int, id_usuario_int, perfil) ' +
    'VALUES(:empresa_id,:pessoa_id,:nome,:login,:senha_hash,:ativo,:email, :id_eleitor_int, :id_usuario_int, :perfil)';
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.ParamByName('empresa_id').AsInteger := AEmpresaId;
    if ADoc.pessoa_id = 0 then
    Qry.ParamByName('pessoa_id').Clear
    else
    Qry.ParamByName('pessoa_id').AsInteger  := ADoc.pessoa_id;
    Qry.ParamByName('nome').AsString        := ADoc.nome;
    Qry.ParamByName('login').AsString       := ADoc.login;
    Qry.ParamByName('senha_hash').AsString  := ADoc.senha_hash;
    Qry.ParamByName('ativo').AsString       := ADoc.ativo;
    Qry.ParamByName('email').AsString       := ADoc.email;
    if ADoc.id_eleitor_int > 0 then
      Qry.ParamByName('id_eleitor_int').AsInteger := ADoc.id_eleitor_int
    else
      Qry.ParamByName('id_eleitor_int').Clear;

    if ADoc.id_usuario_int > 0 then
      Qry.ParamByName('id_usuario_int').AsInteger := ADoc.id_usuario_int
    else
      Qry.ParamByName('id_usuario_int').Clear;

    if ADoc.id_eleitor_int > 0 then
    Qry.ParamByName('perfil').AsString      := 'ELEITOR_IDENTIFICADO'
    else
    Qry.ParamByName('perfil').AsString      := 'ADMIN';

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    Qry.Open;

    Result := Qry.FieldByName('ID').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TUsuariosDao.Atualizar(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TUsuariosModel): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =
    'UPDATE usuario SET ' +
    ' nome=:nome, login=:login, senha_hash=:senha_hash, ativo=:ativo, email=:email ' +
    'WHERE empresa_id=:empresa_id AND pessoa_id=:pessoa_id';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.ParamByName('empresa_id').AsInteger   := AEmpresaId;
    Qry.ParamByName('pessoa_id').AsInteger    := ADoc.pessoa_id;
    Qry.ParamByName('nome').AsString          := ADoc.nome;
    Qry.ParamByName('login').AsString         := ADoc.login;
    Qry.ParamByName('senha_hash').AsString    := ADoc.senha_hash;
    Qry.ParamByName('ativo').AsString         := ADoc.ativo;
    Qry.ParamByName('email').AsString         := ADoc.email;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TUsuariosDao.AtualizarUsuarioSistema(const AConn: TUniConnection;
  const AEmpresaId: Integer; const ADoc: TUsuariosModel): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =
    'UPDATE usuario SET ' +
    ' nome=:nome, login=:login, senha_hash=:senha_hash, ativo=:ativo, email=:email ' +
    'WHERE empresa_id=:empresa_id AND id_usuario_int=:id_usuario_int';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.ParamByName('empresa_id').AsInteger    := AEmpresaId;
    Qry.ParamByName('id_usuario_int').AsInteger:= ADoc.id_usuario_int;
    Qry.ParamByName('nome').AsString           := ADoc.nome;
    Qry.ParamByName('login').AsString          := ADoc.login;
    Qry.ParamByName('senha_hash').AsString     := ADoc.senha_hash;
    Qry.ParamByName('ativo').AsString          := ADoc.ativo;
    Qry.ParamByName('email').AsString          := ADoc.email;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

end.
