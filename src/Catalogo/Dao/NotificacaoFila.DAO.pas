unit NotificacaoFila.DAO;

interface

uses
  Uni,
  NotificacaoFila.Model,
  System.Generics.Collections;

type
  TNotificacaoFilaDAO = class
  public
    class function Inserir(
      const AConn: TUniConnection;
      const ANotificacao: TNotificacaoFilaModel
    ): Int64; static;

    class function ListarPorEmpresa(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64
    ): TObjectList<TNotificacaoFilaModel>; static;

    class function ListarPendentes(
      const AConn: TUniConnection;
      const ACanal: string = '';
      const ALimite: Integer = 50
    ): TObjectList<TNotificacaoFilaModel>; static;

    class procedure MarcarEnviado(
      const AConn: TUniConnection;
      const AIdNotificacao: Int64
    ); static;

    class procedure MarcarErro(
      const AConn: TUniConnection;
      const AIdNotificacao: Int64;
      const AMensagemErro: string
    ); static;

    class procedure Cancelar(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdNotificacao: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils;

procedure PreencherModel(const Qry: TUniQuery; const ANotificacao: TNotificacaoFilaModel);
begin
  ANotificacao.IdNotificacao := Qry.FieldByName('id_notificacao').AsLargeInt;
  ANotificacao.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;

  if not Qry.FieldByName('id_pedido').IsNull then
    ANotificacao.IdPedido := Qry.FieldByName('id_pedido').AsLargeInt;

  ANotificacao.Canal := Qry.FieldByName('canal').AsString;
  ANotificacao.Destinatario := Qry.FieldByName('destinatario').AsString;
  ANotificacao.Titulo := Qry.FieldByName('titulo').AsString;
  ANotificacao.Mensagem := Qry.FieldByName('mensagem').AsString;
  ANotificacao.Status := Qry.FieldByName('status').AsString;
  ANotificacao.Tentativas := Qry.FieldByName('tentativas').AsInteger;
  ANotificacao.UltimoErro := Qry.FieldByName('ultimo_erro').AsString;
  ANotificacao.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

  if not Qry.FieldByName('data_envio').IsNull then
    ANotificacao.DataEnvio := Qry.FieldByName('data_envio').AsDateTime;

  if not Qry.FieldByName('data_alteracao').IsNull then
    ANotificacao.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;
end;

class function TNotificacaoFilaDAO.Inserir(
  const AConn: TUniConnection;
  const ANotificacao: TNotificacaoFilaModel
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO notificacao_fila (' +
      ' id_empresa, id_pedido, canal, destinatario, titulo, mensagem, status ' +
      ') VALUES (' +
      ' :id_empresa, :id_pedido, :canal, :destinatario, :titulo, :mensagem, :status ' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt := ANotificacao.IdEmpresa;

    if ANotificacao.IdPedido > 0 then
      Qry.ParamByName('id_pedido').AsLargeInt := ANotificacao.IdPedido
    else
      Qry.ParamByName('id_pedido').Clear;

    Qry.ParamByName('canal').AsString := UpperCase(Trim(ANotificacao.Canal));
    Qry.ParamByName('destinatario').AsString := Trim(ANotificacao.Destinatario);
    Qry.ParamByName('titulo').AsString := Trim(ANotificacao.Titulo);
    Qry.ParamByName('mensagem').AsString := Trim(ANotificacao.Mensagem);
    Qry.ParamByName('status').AsString := UpperCase(Trim(ANotificacao.Status));

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_notificacao';
    Qry.Open;

    Result := Qry.FieldByName('id_notificacao').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TNotificacaoFilaDAO.ListarPorEmpresa(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64
): TObjectList<TNotificacaoFilaModel>;
var
  Qry: TUniQuery;
  Notificacao: TNotificacaoFilaModel;
begin
  Result := TObjectList<TNotificacaoFilaModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_notificacao, id_empresa, id_pedido, canal, destinatario, titulo, mensagem, ' +
      ' status, tentativas, ultimo_erro, data_criacao, data_envio, data_alteracao ' +
      'FROM notificacao_fila ' +
      'WHERE id_empresa = :id_empresa ' +
      'ORDER BY data_criacao DESC, id_notificacao DESC ' +
      'LIMIT 200';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      Notificacao := TNotificacaoFilaModel.Create;
      PreencherModel(Qry, Notificacao);
      Result.Add(Notificacao);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TNotificacaoFilaDAO.ListarPendentes(
  const AConn: TUniConnection;
  const ACanal: string;
  const ALimite: Integer
): TObjectList<TNotificacaoFilaModel>;
var
  Qry: TUniQuery;
  Notificacao: TNotificacaoFilaModel;
  Limite: Integer;
begin
  Result := TObjectList<TNotificacaoFilaModel>.Create(True);

  Limite := ALimite;
  if Limite <= 0 then
    Limite := 50;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_notificacao, id_empresa, id_pedido, canal, destinatario, titulo, mensagem, ' +
      ' status, tentativas, ultimo_erro, data_criacao, data_envio, data_alteracao ' +
      'FROM notificacao_fila ' +
      'WHERE status = ''PENDENTE'' ';

    if not Trim(ACanal).IsEmpty then
      Qry.SQL.Add('AND canal = :canal ');

    Qry.SQL.Add('ORDER BY data_criacao, id_notificacao LIMIT :limite');

    if not Trim(ACanal).IsEmpty then
      Qry.ParamByName('canal').AsString := UpperCase(Trim(ACanal));

    Qry.ParamByName('limite').AsInteger := Limite;

    Qry.Open;

    while not Qry.Eof do
    begin
      Notificacao := TNotificacaoFilaModel.Create;
      PreencherModel(Qry, Notificacao);
      Result.Add(Notificacao);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TNotificacaoFilaDAO.MarcarEnviado(
  const AConn: TUniConnection;
  const AIdNotificacao: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE notificacao_fila SET ' +
      ' status = ''ENVIADO'', ' +
      ' data_envio = NOW(), ' +
      ' data_alteracao = NOW(), ' +
      ' ultimo_erro = NULL ' +
      'WHERE id_notificacao = :id_notificacao';

    Qry.ParamByName('id_notificacao').AsLargeInt := AIdNotificacao;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TNotificacaoFilaDAO.MarcarErro(
  const AConn: TUniConnection;
  const AIdNotificacao: Int64;
  const AMensagemErro: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE notificacao_fila SET ' +
      ' status = ''ERRO'', ' +
      ' tentativas = tentativas + 1, ' +
      ' ultimo_erro = :ultimo_erro, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_notificacao = :id_notificacao';

    Qry.ParamByName('id_notificacao').AsLargeInt := AIdNotificacao;
    Qry.ParamByName('ultimo_erro').AsString := Trim(AMensagemErro);
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TNotificacaoFilaDAO.Cancelar(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdNotificacao: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE notificacao_fila SET ' +
      ' status = ''CANCELADO'', ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_notificacao = :id_notificacao';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_notificacao').AsLargeInt := AIdNotificacao;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
