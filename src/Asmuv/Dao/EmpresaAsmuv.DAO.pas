unit EmpresaAsmuv.DAO;

interface

uses
  System.SysUtils,
  Uni,
  EmpresaAsmuv.Model,
  System.Generics.Collections;

type
  TEmpresaDAO = class
  private

  public
    class function ExisteEmpresa(const AConn: TUniConnection; Const AIdEmpresa: Int64; const ACNPJ: string; Const AIdEmpresaIgnorar: Int64 = 0): Boolean; static;
    class function Inserir(const AConn: TUniConnection; const AIDEmpresa:Int64; Const AEmpresa: TEmpresaModel): Int64; static;
    class function Atualizar(const AConn: TUniConnection; Const AIdEmpresa:Int64; Const AEmpresa: TEmpresaModel):Boolean; static;
    //class function Listar(const AConn: TUniConnection; const AIdEmpresa: Int64; const APesquisa: string): TObjectList<TEmpresaModel>; static;
    //class function BuscarPorId(const AConn: TUniConnection; Const AIdEmpresa, AIdCupom: Int64): TEmpresaModel; static;

end;

implementation

{ TEmpresaDAO }

class function TEmpresaDAO.Atualizar(const AConn: TUniConnection;const AIdEmpresa:Int64; const AEmpresa: TEmpresaModel): Boolean;
var
  Qry: TUniQuery;
Const
  StrSql  = 'Update empresa set razao_social= :razao, nome_fantasia= :nome, ativo= :ativo, data_alteracao= :data where id_empresa= :idempresa';
begin
  Result := False;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.Params.ParamByName('razao').AsString          := AEmpresa.RazaoSocial;
    Qry.Params.ParamByName('nome').AsString           := AEmpresa.NomeFantasia;
    Qry.Params.ParamByName('ativo').AsString          := AEmpresa.Ativo;
    Qry.Params.ParamByName('data').AsDateTime         := Date;
    Qry.Params.ParamByName('idempresa').AsLargeInt    := AEmpresa.IdEmpresa;

    Qry.Execute;

    Result := Qry.RowsAffected > 0;
  Finally
    Qry.Free;
  End;
end;

class function TEmpresaDAO.ExisteEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64; const ACNPJ: string;
  const AIdEmpresaIgnorar: Int64): Boolean;
var
  Qry: TUniQuery;
Const
  StrSql  = 'Select count(*) as total from empresa where id_empresa= :id_empresa and Upper(razao_social) = UPPER(:razao)';
begin
  Result := False;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    if AIdEmpresaIgnorar > 0 then
      Qry.SQL.Add(' and id_empresa <> :id_empresa ');

    Qry.ParamByName('id_empresa').AsLargeInt  := AIdEmpresa;
    Qry.ParamByName('razao').AsString         := Trim(ACNPJ);

    if AIdEmpresaIgnorar > 0 then
      Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresaIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;

  Finally
    Qry.Free;
  End;
end;

class function TEmpresaDAO.Inserir(const AConn: TUniConnection;const AIDEmpresa: Int64; const AEmpresa: TEmpresaModel): Int64;
var
  Qry: TUniQuery;
Const
  StrSql  = 'Insert into empresa (id_empresa, razao_social, nome_fantasia, ativo, data_criacao) '+
            ' Values(:id_empresa, :razao, :nome, :ativo, :data)';
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.Params.ParamByName('id_empresa').AsLargeInt   := AEmpresa.IdEmpresa;
    Qry.Params.ParamByName('razao').AsString          := AEmpresa.RazaoSocial;
    Qry.Params.ParamByName('nome').AsString           := AEmpresa.NomeFantasia;
    Qry.Params.ParamByName('ativo').AsString          := AEmpresa.Ativo;
    Qry.Params.ParamByName('data').AsDateTime         := Date;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := ' SELECT LAST_INSERT_ID() AS ID ';
    Qry.Open;

    Result := Qry.FieldByName('ID').AsLargeInt;
  Finally
    Qry.Free;
  End;
end;

end.
