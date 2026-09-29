unit PlataformaUsuarioWhatsApp.DAO;

interface

uses
  Uni,
  System.JSON;

type
  TPlataformaUsuarioWhatsAppDAO = class
  public
    class function UsuarioPlataformaExiste(
      const AConn: TUniConnection;
      const AIdUsuario: Int64
    ): Boolean; static;

    class function Buscar(
      const AConn: TUniConnection;
      const AIdUsuario: Int64
    ): TJSONObject; static;

    class function BuscarNomeInstancia(
      const AConn: TUniConnection;
      const AIdUsuario: Int64
    ): string; static;

    class function NomeInstanciaExiste(
      const AConn: TUniConnection;
      const ANomeInstancia: string
    ): Boolean; static;

    class procedure SalvarInstancia(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const ANomeInstancia,
            AEstado: string
    ); static;

    class procedure AtualizarEstado(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const AEstado,
            ANumero: string
    ); static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdUsuarioAcao,
            AIdUsuarioAlvo: Int64;
      const AAcao,
            AMensagem,
            AMetodo,
            ARota,
            AIP,
            AUserAgent: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TPlataformaUsuarioWhatsAppDAO.UsuarioPlataformaExiste(
  const AConn: TUniConnection;
  const AIdUsuario: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM usuario ' +
      'WHERE id = :id AND is_super_admin = 1 LIMIT 1';
    Qry.ParamByName('id').AsLargeInt := AIdUsuario;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaUsuarioWhatsAppDAO.Buscar(
  const AConn: TUniConnection;
  const AIdUsuario: Int64
): TJSONObject;
var
  Qry: TUniQuery;
begin
  Result := TJSONObject.Create;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT i.id, i.nome_instancia, i.estado, i.numero_conectado, ' +
      '       i.ultimo_status_em, i.criado_em, i.atualizado_em ' +
      'FROM plataforma_usuario_whatsapp_instancia i ' +
      'WHERE i.id_usuario = :id_usuario LIMIT 1';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.Open;

    Result.AddPair(
      'id_usuario',
      TJSONNumber.Create(AIdUsuario)
    );

    if Qry.IsEmpty then
    begin
      Result.AddPair('instancia_criada', TJSONBool.Create(False));
      Result.AddPair('nome_instancia', TJSONNull.Create);
      Result.AddPair('estado', 'NAO_CRIADA');
      Result.AddPair('conectado', TJSONBool.Create(False));
      Result.AddPair('numero', TJSONNull.Create);
      Exit;
    end;

    Result.AddPair('instancia_criada', TJSONBool.Create(True));
    Result.AddPair('nome_instancia', Qry.FieldByName('nome_instancia').AsString);
    Result.AddPair('estado', Qry.FieldByName('estado').AsString);
    Result.AddPair(
      'conectado',
      TJSONBool.Create(
        SameText(Qry.FieldByName('estado').AsString, 'OPEN') or
        SameText(Qry.FieldByName('estado').AsString, 'CONNECTED')
      )
    );

    if Qry.FieldByName('numero_conectado').IsNull then
      Result.AddPair('numero', TJSONNull.Create)
    else
      Result.AddPair('numero', Qry.FieldByName('numero_conectado').AsString);

    if Qry.FieldByName('ultimo_status_em').IsNull then
      Result.AddPair('ultimo_status_em', TJSONNull.Create)
    else
      Result.AddPair(
        'ultimo_status_em',
        FormatDateTime(
          'yyyy-mm-dd"T"hh:nn:ss.zzz',
          Qry.FieldByName('ultimo_status_em').AsDateTime
        )
      );
  finally
    Qry.Free;
  end;
end;

class function TPlataformaUsuarioWhatsAppDAO.BuscarNomeInstancia(
  const AConn: TUniConnection;
  const AIdUsuario: Int64
): string;
var
  Qry: TUniQuery;
begin
  Result := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT nome_instancia ' +
      'FROM plataforma_usuario_whatsapp_instancia ' +
      'WHERE id_usuario = :id_usuario LIMIT 1';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('nome_instancia').AsString;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaUsuarioWhatsAppDAO.NomeInstanciaExiste(
  const AConn: TUniConnection;
  const ANomeInstancia: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM plataforma_usuario_whatsapp_instancia ' +
      'WHERE nome_instancia = :nome LIMIT 1';
    Qry.ParamByName('nome').AsString := ANomeInstancia;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaUsuarioWhatsAppDAO.SalvarInstancia(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const ANomeInstancia,
        AEstado: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO plataforma_usuario_whatsapp_instancia ' +
      '(id_usuario, nome_instancia, estado) ' +
      'VALUES (:id_usuario, :nome_instancia, :estado) ' +
      'ON DUPLICATE KEY UPDATE ' +
      'nome_instancia = VALUES(nome_instancia), ' +
      'estado = VALUES(estado), ultimo_erro = NULL';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('nome_instancia').AsString := ANomeInstancia;
    Qry.ParamByName('estado').AsString := Copy(UpperCase(Trim(AEstado)), 1, 30);
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaUsuarioWhatsAppDAO.AtualizarEstado(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const AEstado,
        ANumero: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE plataforma_usuario_whatsapp_instancia SET ' +
      'estado = :estado, ' +
      'numero_conectado = NULLIF(:numero, ''''), ' +
      'ultimo_status_em = CURRENT_TIMESTAMP(3), ' +
      'ultimo_erro = NULL ' +
      'WHERE id_usuario = :id_usuario';

    Qry.ParamByName('estado').AsString := Copy(UpperCase(Trim(AEstado)), 1, 30);
    Qry.ParamByName('numero').AsString := Copy(Trim(ANumero), 1, 80);
    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaUsuarioWhatsAppDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdUsuarioAcao,
        AIdUsuarioAlvo: Int64;
  const AAcao,
        AMensagem,
        AMetodo,
        ARota,
        AIP,
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
      'acao, entidade, registro_id, metodo_http, rota, ip, user_agent, sucesso, mensagem) ' +
      'VALUES (NULL, :id_usuario, NULL, :acao, ' +
      '''plataforma_usuario_whatsapp_instancia'', :registro_id, :metodo, :rota, ' +
      ':ip, :user_agent, 1, :mensagem)';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuarioAcao;
    Qry.ParamByName('acao').AsString := Copy(UpperCase(Trim(AAcao)), 1, 80);
    Qry.ParamByName('registro_id').AsString := AIdUsuarioAlvo.ToString;
    Qry.ParamByName('metodo').AsString := Copy(UpperCase(Trim(AMetodo)), 1, 10);
    Qry.ParamByName('rota').AsString := Copy(Trim(ARota), 1, 500);
    Qry.ParamByName('ip').AsString := Copy(Trim(AIP), 1, 45);
    Qry.ParamByName('user_agent').AsString := Copy(Trim(AUserAgent), 1, 1000);
    Qry.ParamByName('mensagem').AsString := Copy(Trim(AMensagem), 1, 1000);
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
