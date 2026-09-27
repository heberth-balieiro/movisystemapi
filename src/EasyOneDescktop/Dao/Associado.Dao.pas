unit Associado.Dao;

interface

uses
  System.SysUtils,
  Uni,
  Associado.Model;

type
  TAssociadoDAO = class
  public
    class function ExisteAssociado(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIdSocio: Integer): Boolean; static;
    class function Inserir(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TAssociadoModel): Int64; static;
    class function Atualizar(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TAssociadoModel): Boolean; static;
  end;

implementation

{ TAssociadoDAO }

class function TAssociadoDAO.Atualizar(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TAssociadoModel): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =
    'UPDATE pessoa SET ' +
    ' codigo=:codigo, matricula=:matricula, ativo=:ativo, nome=:nome, apelido=:apelido, telefone=:telefone, celular=:celular, ' +
    ' whatsapp=:whatsapp, cpf=:cpf, nascimento=:nascimento, email=:email, cidade=:cidade, secretaria=:secretaria, profissao=:profissao, ' +
    ' lotacao=:lotacao, localtrabalho=:localtrabalho, funcao=:funcao, naturalde=:naturalde, rg=:rg, data_filiacao=:data_filiacao, ' +
    ' pai=:pai, mae=:mae, foto=:foto, bloqueado=:bloqueado, excluido=:excluido ' +
    'WHERE empresa_id=:empresa_id AND id_socio=:id_socio';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.ParamByName('codigo').AsInteger := ADoc.codigo;
    Qry.ParamByName('matricula').AsInteger := ADoc.matricula;
    Qry.ParamByName('ativo').AsString := ADoc.ativo;
    Qry.ParamByName('nome').AsString := ADoc.nome;
    Qry.ParamByName('apelido').AsString := ADoc.apelido;
    Qry.ParamByName('telefone').AsString := ADoc.telefone;
    Qry.ParamByName('celular').AsString := ADoc.celular;
    Qry.ParamByName('whatsapp').AsString := ADoc.whatsapp;
    Qry.ParamByName('cpf').AsString := ADoc.cpf;

    if ADoc.nascimento > 0 then Qry.ParamByName('nascimento').AsDate := ADoc.nascimento else Qry.ParamByName('nascimento').Clear;

    Qry.ParamByName('email').AsString := ADoc.email;
    Qry.ParamByName('cidade').AsString := ADoc.cidade;
    Qry.ParamByName('secretaria').AsString := ADoc.secretaria;
    Qry.ParamByName('profissao').AsString := ADoc.profissao;
    Qry.ParamByName('lotacao').AsString := ADoc.lotacao;
    Qry.ParamByName('localtrabalho').AsString := ADoc.localtrabalho;
    Qry.ParamByName('funcao').AsString := ADoc.funcao;
    Qry.ParamByName('naturalde').AsString := ADoc.naturalde;
    Qry.ParamByName('rg').AsString := ADoc.rg;

    if ADoc.data_filiacao > 0 then Qry.ParamByName('data_filiacao').AsDate := ADoc.data_filiacao else Qry.ParamByName('data_filiacao').Clear;

    Qry.ParamByName('pai').AsString := ADoc.pai;
    Qry.ParamByName('mae').AsString := ADoc.mae;

    if Trim(ADoc.foto) <> '' then Qry.ParamByName('foto').AsString := ADoc.foto else Qry.ParamByName('foto').Clear;

    Qry.ParamByName('bloqueado').AsString := ADoc.bloqueado;
    Qry.ParamByName('excluido').AsInteger := ADoc.excluido;
    Qry.ParamByName('empresa_id').AsInteger := AEmpresaId;
    Qry.ParamByName('id_socio').AsInteger := ADoc.id_socio;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TAssociadoDAO.ExisteAssociado(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIdSocio: Integer): Boolean;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT 1 FROM pessoa WHERE empresa_id=:id AND id_socio=:id_socio LIMIT 1';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('id').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_socio').AsInteger := AIdSocio;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TAssociadoDAO.Inserir(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TAssociadoModel): Int64;
var
  Qry: TUniQuery;
const
  StrSql =
    'INSERT INTO pessoa (' +
    ' id_socio, codigo, matricula, ativo, nome, apelido, telefone, celular, whatsapp, cpf, nascimento, email, cidade, secretaria, ' +
    ' profissao, lotacao, localtrabalho, funcao, naturalde, rg, data_filiacao, pai, mae, foto, bloqueado, excluido, empresa_id) ' +
    'VALUES (' +
    ' :id_socio, :codigo, :matricula, :ativo, :nome, :apelido, :telefone, :celular, :whatsapp, :cpf, :nascimento, :email, :cidade, ' +
    ' :secretaria, :profissao, :lotacao, :localtrabalho, :funcao, :naturalde, :rg, :data_filiacao, :pai, :mae, :foto, :bloqueado, ' +
    ' :excluido, :empresa_id)';
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.ParamByName('id_socio').AsInteger := ADoc.id_socio;
    Qry.ParamByName('codigo').AsInteger := ADoc.codigo;
    Qry.ParamByName('matricula').AsInteger := ADoc.matricula;
    Qry.ParamByName('ativo').AsString := ADoc.ativo;
    Qry.ParamByName('nome').AsString := ADoc.nome;
    Qry.ParamByName('apelido').AsString := ADoc.apelido;
    Qry.ParamByName('telefone').AsString := ADoc.telefone;
    Qry.ParamByName('celular').AsString := ADoc.celular;
    Qry.ParamByName('whatsapp').AsString := ADoc.whatsapp;
    Qry.ParamByName('cpf').AsString := ADoc.cpf;

    if ADoc.nascimento > 0 then Qry.ParamByName('nascimento').AsDate := ADoc.nascimento else Qry.ParamByName('nascimento').Clear;

    Qry.ParamByName('email').AsString := ADoc.email;
    Qry.ParamByName('cidade').AsString := ADoc.cidade;
    Qry.ParamByName('secretaria').AsString := ADoc.secretaria;
    Qry.ParamByName('profissao').AsString := ADoc.profissao;
    Qry.ParamByName('lotacao').AsString := ADoc.lotacao;
    Qry.ParamByName('localtrabalho').AsString := ADoc.localtrabalho;
    Qry.ParamByName('funcao').AsString := ADoc.funcao;
    Qry.ParamByName('naturalde').AsString := ADoc.naturalde;
    Qry.ParamByName('rg').AsString := ADoc.rg;

    if ADoc.data_filiacao > 0 then Qry.ParamByName('data_filiacao').AsDate := ADoc.data_filiacao else Qry.ParamByName('data_filiacao').Clear;

    Qry.ParamByName('pai').AsString := ADoc.pai;
    Qry.ParamByName('mae').AsString := ADoc.mae;

    if Trim(ADoc.foto) <> '' then Qry.ParamByName('foto').AsString := ADoc.foto else Qry.ParamByName('foto').Clear;

    Qry.ParamByName('bloqueado').AsString := ADoc.bloqueado;
    Qry.ParamByName('excluido').AsInteger := ADoc.excluido;
    Qry.ParamByName('empresa_id').AsInteger := AEmpresaId;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    Qry.Open;
    Result := Qry.FieldByName('ID').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

end.
