unit Usuario.DAO;

interface

uses
  Uni,
  Usuario.Model,
  System.SysUtils;

type
  TUsuarioLoginDTO = record
    IdUsuario: Int64;
    IdEmpresa: Int64;
    NomeUsuario: string;
    Email: string;
    SenhaHash: string;
    Perfil: string;
    UsuarioAtivo: string;

    EmpresaNome: string;
    EmpresaAtivo: string;
    EmpresaDataValidade: TDate;

    Licencatrialtermina : TDate;
    LicencaSituacao     : String;
  end;

  TUsuarioDAO = class
  private

  public
    class function ExisteEmail(const AConn: TUniConnection; const AEmail: string): Boolean; static;
    class function Inserir(const AConn: TUniConnection; const AUsuario: TUsuarioModel): Int64; static;
    class procedure LimparUsuarioLoginDTO(out AUsuario: TUsuarioLoginDTO); static;
    class function BuscarLoginPorEmail(const AConn: TUniConnection; const AEmail: string; out AUsuario: TUsuarioLoginDTO): Boolean; static;
    class function ExisteEmailEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64; const AEmail: string;const AIdUsuarioIgnorar: Int64): Boolean; static;
  end;

implementation

class procedure TUsuarioDAO.LimparUsuarioLoginDTO(out AUsuario: TUsuarioLoginDTO);
begin
  AUsuario.IdUsuario := 0;
  AUsuario.IdEmpresa := 0;
  AUsuario.NomeUsuario := '';
  AUsuario.Email := '';
  AUsuario.SenhaHash := '';
  AUsuario.Perfil := '';
  AUsuario.UsuarioAtivo := '';

  AUsuario.EmpresaNome := '';
  AUsuario.EmpresaAtivo := '';
  AUsuario.EmpresaDataValidade := 0;
end;

class function TUsuarioDAO.ExisteEmail(const AConn: TUniConnection; const AEmail: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM usuario ' +
      'WHERE LOWER(TRIM(email)) = LOWER(TRIM(:email))';

    Qry.ParamByName('email').AsString := Trim(AEmail);
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TUsuarioDAO.Inserir(const AConn: TUniConnection; const AUsuario: TUsuarioModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO usuario (' +
      ' id_empresa, nome, email, senha_hash, perfil, ativo, id_cliente ' +
      ') VALUES (' +
      ' :id_empresa, :nome, :email, :senha_hash, :perfil, :ativo, :id_cliente ' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt  := AUsuario.IdEmpresa;
    Qry.ParamByName('nome').AsString          := Trim(AUsuario.Nome);
    Qry.ParamByName('email').AsString         := LowerCase(Trim(AUsuario.Email));
    Qry.ParamByName('senha_hash').AsString    := AUsuario.SenhaHash;
    Qry.ParamByName('perfil').AsString        := UpperCase(Trim(AUsuario.Perfil));
    Qry.ParamByName('ativo').AsString         := UpperCase(Trim(AUsuario.Ativo));

    if AUsuario.IdCliente > 0 then
    Qry.ParamByName('id_cliente').AsLargeInt  := AUsuario.IdCliente
    else
    Qry.ParamByName('id_cliente').Clear;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_usuario';
    Qry.Open;

    Result := Qry.FieldByName('id_usuario').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TUsuarioDAO.BuscarLoginPorEmail(const AConn: TUniConnection;const AEmail: string;out AUsuario: TUsuarioLoginDTO): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  LimparUsuarioLoginDTO(AUsuario);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' u.id_usuario, ' +
      ' u.id_empresa, ' +
      ' u.nome AS nome_usuario, ' +
      ' u.email, ' +
      ' u.senha_hash, ' +
      ' u.perfil, ' +
      ' u.ativo AS usuario_ativo, ' +
      ' e.nome AS empresa_nome, ' +
      ' e.ativo AS empresa_ativo, ' +
      ' e.data_validade AS empresa_data_validade, a.proximo_vencimento, a.trial_termina_em, a.situacao ' +
      ' FROM usuario u ' +
      ' INNER JOIN empresa e '+
      ' ON e.id_empresa = u.id_empresa ' +
      ' left join assinatura a  '+
      ' on u.id_empresa = a.id_empresa '+
      ' WHERE LOWER(TRIM(u.email)) = LOWER(TRIM(:email)) ' +
      ' LIMIT 1';

    Qry.ParamByName('email').AsString := Trim(AEmail);
    Qry.Open;

    if Qry.IsEmpty then
      Exit(False);

    AUsuario.IdUsuario            := Qry.FieldByName('id_usuario').AsLargeInt;
    AUsuario.IdEmpresa            := Qry.FieldByName('id_empresa').AsLargeInt;
    AUsuario.NomeUsuario          := Qry.FieldByName('nome_usuario').AsString;
    AUsuario.Email                := Qry.FieldByName('email').AsString;
    AUsuario.SenhaHash            := Qry.FieldByName('senha_hash').AsString;
    AUsuario.Perfil               := Qry.FieldByName('perfil').AsString;
    AUsuario.UsuarioAtivo         := Qry.FieldByName('usuario_ativo').AsString;

    AUsuario.EmpresaNome          := Qry.FieldByName('empresa_nome').AsString;
    AUsuario.EmpresaAtivo         := Qry.FieldByName('empresa_ativo').AsString;
    AUsuario.EmpresaDataValidade  := Qry.FieldByName('proximo_vencimento').AsDateTime;
    AUsuario.Licencatrialtermina  := Qry.FieldByName('trial_termina_em').AsDateTime;
    AUsuario.LicencaSituacao      := Qry.FieldByName('situacao').AsString;

    Result := True;
  finally
    Qry.Free;
  end;
end;

class function TUsuarioDAO.ExisteEmailEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64;const AEmail: string; const AIdUsuarioIgnorar: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if Trim(AEmail).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM usuario ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND LOWER(TRIM(email)) = LOWER(TRIM(:email)) ';

    if AIdUsuarioIgnorar > 0 then
      Qry.SQL.Text := Qry.SQL.Text +
        'AND id_usuario <> :id_usuario ';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('email').AsString := Trim(AEmail);

    if AIdUsuarioIgnorar > 0 then
      Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuarioIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;


end.
