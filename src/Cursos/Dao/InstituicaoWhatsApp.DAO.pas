unit InstituicaoWhatsApp.DAO;

interface

uses
  Uni;

type
  TInstituicaoWhatsAppDAO = class
  public
    class function BuscarNomeInstancia(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ): string; static;

    class function NomeInstanciaExiste(
      const AConn: TUniConnection;
      const ANomeInstancia: string
    ): Boolean; static;

    class procedure SalvarInstancia(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ANomeInstancia,
            AEstado: string
    ); static;

    class procedure AtualizarEstado(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AEstado,
            ANumero: string
    ); static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuario,
            AIdUsuarioInstituicao: Int64;
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

class function TInstituicaoWhatsAppDAO.BuscarNomeInstancia(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
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
      'FROM instituicao_whatsapp_instancia ' +
      'WHERE id_instituicao = :id_instituicao';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.Open;

    if not Qry.IsEmpty then
      Result :=
        Qry.FieldByName('nome_instancia').AsString;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoWhatsAppDAO.NomeInstanciaExiste(
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
      'SELECT 1 ' +
      'FROM instituicao_whatsapp_instancia ' +
      'WHERE nome_instancia = :nome_instancia ' +
      'LIMIT 1';

    Qry.ParamByName('nome_instancia').AsString :=
      ANomeInstancia;

    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoWhatsAppDAO.SalvarInstancia(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
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
      'INSERT INTO instituicao_whatsapp_instancia ' +
      '(id_instituicao, nome_instancia, estado) ' +
      'VALUES (:id_instituicao, :nome_instancia, :estado) ' +
      'ON DUPLICATE KEY UPDATE ' +
      'nome_instancia = VALUES(nome_instancia), ' +
      'estado = VALUES(estado), ' +
      'ultimo_erro = NULL';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;
    Qry.ParamByName('nome_instancia').AsString :=
      ANomeInstancia;
    Qry.ParamByName('estado').AsString :=
      AEstado;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoWhatsAppDAO.AtualizarEstado(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
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
      'UPDATE instituicao_whatsapp_instancia SET ' +
      'estado = :estado, ' +
      'numero_conectado = NULLIF(:numero, ''''), ' +
      'ultimo_status_em = CURRENT_TIMESTAMP(3), ' +
      'ultimo_erro = NULL ' +
      'WHERE id_instituicao = :id_instituicao';

    Qry.ParamByName('estado').AsString :=
      Copy(UpperCase(Trim(AEstado)), 1, 30);
    Qry.ParamByName('numero').AsString :=
      Copy(Trim(ANumero), 1, 80);
    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoWhatsAppDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuario,
        AIdUsuarioInstituicao: Int64;
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
      'VALUES ' +
      '(:id_instituicao, :id_usuario, :id_usuario_instituicao, ' +
      ':acao, ''instituicao_whatsapp_instancia'', :registro_id, :metodo, :rota, ' +
      ':ip, :user_agent, 1, :mensagem)';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('id_usuario_instituicao').AsLargeInt := AIdUsuarioInstituicao;
    Qry.ParamByName('acao').AsString := Copy(UpperCase(Trim(AAcao)), 1, 80);
    Qry.ParamByName('registro_id').AsString := AIdInstituicao.ToString;
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
