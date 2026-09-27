unit WhatsAppConfigAPI.Dao;

interface

uses
  System.SysUtils,
  Uni;

type
  TWhatsAppConfigDados = record
    IdEmpresa: Integer;
    URL: string;
    Instancia: string;
    Token: string;
    Ativo: string;
  end;

  TWhatsAppConfigAPIDao = class
  public
    class function BuscarConfiguracao(const AConn: TUniConnection; const AIdEmpresa: Integer;
      out AConfig: TWhatsAppConfigDados): Boolean; static;
  end;

implementation

{ TWhatsAppConfigAPIDao }

class function TWhatsAppConfigAPIDao.BuscarConfiguracao(const AConn: TUniConnection;
  const AIdEmpresa: Integer; out AConfig: TWhatsAppConfigDados): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AConfig := Default(TWhatsAppConfigDados);

  if (AConn = nil) or (AIdEmpresa <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT id, whatsapp_url, whatsapp_instancia, whatsapp_token, ativo ' +
      'FROM empresa ' +
      'WHERE id = :idempresa ' +
      'LIMIT 1';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AConfig.IdEmpresa       := Qry.FieldByName('id').AsInteger;
    AConfig.URL             := Trim(Qry.FieldByName('whatsapp_url').AsString);
    AConfig.Instancia       := Trim(Qry.FieldByName('whatsapp_instancia').AsString);
    AConfig.Token           := Trim(Qry.FieldByName('whatsapp_token').AsString);
    AConfig.Ativo           := UpperCase(Trim(Qry.FieldByName('ativo').AsString));

    Result := True;
  finally
    Qry.Free;
  end;
end;

end.
