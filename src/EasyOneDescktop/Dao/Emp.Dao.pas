unit Emp.Dao;

interface

uses
  System.SysUtils,
  Uni,
  Emp.Model,
  System.Generics.Collections;

type
  TEmpDAO = class
  private

  public
    class function ExisteEmpresa(Out ARetID:Integer; const AConn: TUniConnection; Const AIdEmpresa: Int64; const AuuID: string): Boolean; static;
    class function Inserir(const AConn: TUniConnection; Const AEmpresa: TEmpresasModel): Int64; static;
    class function Atualizar(const AConn: TUniConnection; Const AEmpresa: TEmpresasModel):Boolean; static;
end;

implementation

{ TEmpDAO }

class function TEmpDAO.Atualizar(const AConn: TUniConnection;const AEmpresa: TEmpresasModel): Boolean;
var
  Qry: TUniQuery;
Const
  StrSql  = 'Update empresa set razao= :razao, fantasia= :fantasia, '+
            ' telefone= :telefone, ativo= :ativo '+
            ' whatsapp_url = :whatsapp_url, ' +
            ' whatsapp_instancia = :whatsapp_instancia, ' +
            ' whatsapp_token = :whatsapp_token, ' +
            ' easyone_api_key_hash = CASE ' +
            '   WHEN TRIM(:easyone_api_key_hash) <> '''' THEN :easyone_api_key_hash ' +
            '   ELSE easyone_api_key_hash ' +
            ' END, ' +
            ' easyone_integracao_ativo = :easyone_integracao_ativo ' +

            ' where uuid= :uuid  ';

begin
  Result := False;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.Params.ParamByName('razao').AsString                    := AEmpresa.razao;
    Qry.Params.ParamByName('fantasia').AsString                 := AEmpresa.fantasia;
    Qry.Params.ParamByName('telefone').AsString                 := AEmpresa.telefone;
    Qry.Params.ParamByName('ativo').AsString                    := AEmpresa.ativo;

    Qry.Params.ParamByName('whatsapp_url').AsString             := AEmpresa.whatsapp_url;
    Qry.Params.ParamByName('whatsapp_instancia').AsString       := AEmpresa.whatsapp_instancia;
    Qry.Params.ParamByName('whatsapp_token').AsString           := AEmpresa.whatsapp_token;

    Qry.Params.ParamByName('easyone_api_key_hash').AsString     := AEmpresa.easyone_api_key_hash;
    Qry.Params.ParamByName('easyone_integracao_ativo').AsString := AEmpresa.easyone_integracao_ativo;

    Qry.Params.ParamByName('uuid').AsString                     := AEmpresa.uuid;

    Qry.ExecSQL;
    Result        := True;
  Finally
    Qry.Free;
  End;
end;

class function TEmpDAO.ExisteEmpresa(Out ARetID:Integer; const AConn: TUniConnection;const AIdEmpresa: Int64; const AuuID: string): Boolean;
var
  Qry: TUniQuery;
Const
  StrSql  = 'SELECT COUNT(*) AS total, MAX(id) AS id FROM empresa WHERE id_empresa = :idempresa AND UPPER(uuid) = UPPER(:uuid)';
begin
  Result := False;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.ParamByName('idempresa').AsLargeInt  := AIdEmpresa;
    Qry.ParamByName('uuid').AsString         := Trim(AuuID);

    Qry.Open;
    ARetID  := Qry.FieldByName('id').AsInteger ;
    Result  := Qry.FieldByName('total').AsInteger  > 0;

  Finally
    Qry.Free;
  End;
end;

class function TEmpDAO.Inserir(const AConn: TUniConnection; const AEmpresa: TEmpresasModel): Int64;
var
  Qry: TUniQuery;
Const
  StrSql  = 'INSERT INTO empresa(id_empresa, uuid, razao, fantasia, telefone, ativo, cpfcnpj, '+
            ' whatsapp_url, whatsapp_instancia, whatsapp_token, ' +
            ' easyone_api_key_hash, easyone_integracao_ativo)'+
              'VALUES(:id_empresa, :uuid, :razao, :fantasia, :telefone, :ativo, :cpfcnpj, '+
              ' :whatsapp_url, :whatsapp_instancia, :whatsapp_token, ' +
              ' :easyone_api_key_hash, :easyone_integracao_ativo ' +
              ' );';
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.Params.ParamByName('id_empresa').AsInteger  := AEmpresa.id_empresa;
    Qry.Params.ParamByName('uuid').AsString         := AEmpresa.uuid;
    Qry.Params.ParamByName('razao').AsString        := AEmpresa.razao;
    Qry.Params.ParamByName('fantasia').AsString     := AEmpresa.fantasia;
    Qry.Params.ParamByName('telefone').AsString     := AEmpresa.telefone;
    Qry.Params.ParamByName('ativo').AsString        := AEmpresa.ativo;
    Qry.Params.ParamByName('cpfcnpj').AsString      := AEmpresa.cpfcnpj;
    Qry.Params.ParamByName('whatsapp_url').AsString := AEmpresa.whatsapp_url;
    Qry.Params.ParamByName('whatsapp_instancia').AsString := AEmpresa.whatsapp_instancia;
    Qry.Params.ParamByName('whatsapp_token').AsString := AEmpresa.whatsapp_token;

    Qry.Params.ParamByName('easyone_api_key_hash').AsString := AEmpresa.easyone_api_key_hash;
    Qry.Params.ParamByName('easyone_integracao_ativo').AsString := AEmpresa.easyone_integracao_ativo;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text  := ' SELECT LAST_INSERT_ID() AS ID ';
    Qry.Open;

    Result        := Qry.FieldByName('ID').AsLargeInt;
  Finally
    Qry.Free;
  End;
end;

end.
