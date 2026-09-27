unit EasyOneIntegracao.Dao;

interface

uses
  Uni;

type
  TEasyOneIntegracaoDados = record
    Id                   : Integer;
    IdEmpresa            : Integer;
    UUID                 : string;
    Ativo                : string;
    APIKeyHash           : string;
    IntegracaoAtiva      : string;
  end;

  TEasyOneIntegracaoDAO = class
  public
    class function BuscarEmpresaPorUUID(const AConn: TUniConnection; const AUUID: string; out ADados: TEasyOneIntegracaoDados): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

{ TEasyOneIntegracaoDAO }

class function TEasyOneIntegracaoDAO.BuscarEmpresaPorUUID(const AConn: TUniConnection; const AUUID: string; out ADados: TEasyOneIntegracaoDados): Boolean;
var
  Qry: TUniQuery;
const
  SQL =
    'SELECT id, id_empresa, uuid, ativo, easyone_api_key_hash, easyone_integracao_ativo ' +
    'FROM empresa ' +
    'WHERE UPPER(uuid) = UPPER(:uuid) ' +
    'LIMIT 1';
begin
  Result := False;
  ADados := Default(TEasyOneIntegracaoDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;
    Qry.ParamByName('uuid').AsString := Trim(AUUID);
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    ADados.Id              := Qry.FieldByName('id').AsInteger;
    ADados.IdEmpresa       := Qry.FieldByName('id_empresa').AsInteger;
    ADados.UUID            := Qry.FieldByName('uuid').AsString;
    ADados.Ativo           := Qry.FieldByName('ativo').AsString;
    ADados.APIKeyHash      := Qry.FieldByName('easyone_api_key_hash').AsString;
    ADados.IntegracaoAtiva := Qry.FieldByName('easyone_integracao_ativo').AsString;

    Result := True;
  finally
    Qry.Free;
  end;
end;

end.
