unit NotificacaoFila.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  NotificacaoFila.Model;

type
  TNotificacaoFilaService = class
  private
    class function NormalizarCanal(const ACanal: string): string; static;
    class function NormalizarStatus(const AStatus: string): string; static;
    class procedure ValidarNotificacao(const ANotificacao: TNotificacaoFilaModel); static;
  public
    class function CriarNotificacao(
      const ANotificacao: TNotificacaoFilaModel
    ): Int64; static;

    class procedure CriarNotificacoesPedido(
      const AIdEmpresa: Int64;
      const AIdPedido: Int64;
      const ANomeCliente: string;
      const AWhatsappCliente: string;
      const AEmailCliente: string;
      const AValorTotal: Currency
    ); static;

    class function ListarPorEmpresa(
      const AIdEmpresa: Int64
    ): TObjectList<TNotificacaoFilaModel>; static;

    class function ListarPendentes(
      const ACanal: string = '';
      const ALimite: Integer = 50
    ): TObjectList<TNotificacaoFilaModel>; static;

    class procedure MarcarEnviado(
      const AIdNotificacao: Int64
    ); static;

    class procedure MarcarErro(
      const AIdNotificacao: Int64;
      const AMensagemErro: string
    ); static;

    class procedure Cancelar(
      const AIdEmpresa: Int64;
      const AIdNotificacao: Int64
    ); static;
  end;

implementation

uses
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  NotificacaoFila.DAO;

class function TNotificacaoFilaService.NormalizarCanal(const ACanal: string): string;
var
  Canal: string;
begin
  Canal := UpperCase(Trim(ACanal));

  if (Canal <> 'WHATSAPP') and (Canal <> 'EMAIL') then
    TAppErrors.RaiseBadRequest('Canal de notificação inválido.');

  Result := Canal;
end;

class function TNotificacaoFilaService.NormalizarStatus(const AStatus: string): string;
var
  Status: string;
begin
  Status := UpperCase(Trim(AStatus));

  if Status.IsEmpty then
    Status := 'PENDENTE';

  if (Status <> 'PENDENTE') and
     (Status <> 'ENVIADO') and
     (Status <> 'ERRO') and
     (Status <> 'CANCELADO') then
    Status := 'PENDENTE';

  Result := Status;
end;

class procedure TNotificacaoFilaService.ValidarNotificacao(
  const ANotificacao: TNotificacaoFilaModel
);
begin
  if ANotificacao = nil then
    TAppErrors.RaiseBadRequest('Dados da notificação não informados.');

  if ANotificacao.IdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa da notificação não informada.');

  ANotificacao.Canal := NormalizarCanal(ANotificacao.Canal);

  if Trim(ANotificacao.Destinatario).IsEmpty then
    TAppErrors.RaiseBadRequest('Destinatário da notificação não informado.');

  if Length(Trim(ANotificacao.Destinatario)) > 150 then
    TAppErrors.RaiseBadRequest('Destinatário deve possuir no máximo 150 caracteres.');

  if Trim(ANotificacao.Titulo).IsEmpty then
    TAppErrors.RaiseBadRequest('Título da notificação não informado.');

  if Length(Trim(ANotificacao.Titulo)) > 150 then
    TAppErrors.RaiseBadRequest('Título da notificação deve possuir no máximo 150 caracteres.');

  if Trim(ANotificacao.Mensagem).IsEmpty then
    TAppErrors.RaiseBadRequest('Mensagem da notificação não informada.');

  ANotificacao.Destinatario := Trim(ANotificacao.Destinatario);
  ANotificacao.Titulo := Trim(ANotificacao.Titulo);
  ANotificacao.Mensagem := Trim(ANotificacao.Mensagem);
  ANotificacao.Status := NormalizarStatus(ANotificacao.Status);
end;

class function TNotificacaoFilaService.CriarNotificacao(
  const ANotificacao: TNotificacaoFilaModel
): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := 0;

  ValidarNotificacao(ANotificacao);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TNotificacaoFilaDAO.Inserir(Conn, ANotificacao);
  finally
    Conn.Free;
  end;
end;

class procedure TNotificacaoFilaService.CriarNotificacoesPedido(
  const AIdEmpresa: Int64;
  const AIdPedido: Int64;
  const ANomeCliente: string;
  const AWhatsappCliente: string;
  const AEmailCliente: string;
  const AValorTotal: Currency
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
  Notificacao: TNotificacaoFilaModel;
  NotificarWhatsapp: string;
  NotificarEmail: string;
  WhatsappEmpresa: string;
  EmailEmpresa: string;
  MensagemModelo: string;
  Mensagem: string;
begin
  if AIdEmpresa <= 0 then
    Exit;

  if AIdPedido <= 0 then
    Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'SELECT ' +
        ' whatsapp, email, notificar_pedido_whatsapp, notificar_pedido_email, mensagem_modelo ' +
        'FROM empresa ' +
        'WHERE id_empresa = :id_empresa ' +
        'LIMIT 1';

      Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
      Qry.Open;

      if Qry.IsEmpty then
        Exit;

      WhatsappEmpresa := Trim(Qry.FieldByName('whatsapp').AsString);
      EmailEmpresa := Trim(Qry.FieldByName('email').AsString);
      NotificarWhatsapp := UpperCase(Trim(Qry.FieldByName('notificar_pedido_whatsapp').AsString));
      NotificarEmail := UpperCase(Trim(Qry.FieldByName('notificar_pedido_email').AsString));
      MensagemModelo := Trim(Qry.FieldByName('mensagem_modelo').AsString);

      if MensagemModelo.IsEmpty then
      begin
        Mensagem :=
          'Novo pedido recebido no catálogo digital.' + sLineBreak +
          'Pedido: #' + AIdPedido.ToString + sLineBreak +
          'Cliente: ' + Trim(ANomeCliente) + sLineBreak +
          'WhatsApp: ' + Trim(AWhatsappCliente) + sLineBreak +
          'Valor total: R$ ' + FormatFloat('0.00', AValorTotal);
      end
      else
      begin
        Mensagem := MensagemModelo;
        Mensagem := StringReplace(Mensagem, '{id_pedido}', AIdPedido.ToString, [rfReplaceAll]);
        Mensagem := StringReplace(Mensagem, '{nome_cliente}', Trim(ANomeCliente), [rfReplaceAll]);
        Mensagem := StringReplace(Mensagem, '{whatsapp_cliente}', Trim(AWhatsappCliente), [rfReplaceAll]);
        Mensagem := StringReplace(Mensagem, '{valor_total}', FormatFloat('0.00', AValorTotal), [rfReplaceAll]);
      end;

      if (NotificarWhatsapp = 'S') and (not WhatsappEmpresa.IsEmpty) then
      begin
        Notificacao := TNotificacaoFilaModel.Create;
        try
          Notificacao.IdEmpresa := AIdEmpresa;
          Notificacao.IdPedido := AIdPedido;
          Notificacao.Canal := 'WHATSAPP';
          Notificacao.Destinatario := WhatsappEmpresa;
          Notificacao.Titulo := 'Novo pedido recebido';
          Notificacao.Mensagem := Mensagem;
          Notificacao.Status := 'PENDENTE';

          TNotificacaoFilaDAO.Inserir(Conn, Notificacao);
        finally
          Notificacao.Free;
        end;
      end;

      if (NotificarEmail = 'S') and (not EmailEmpresa.IsEmpty) then
      begin
        Notificacao := TNotificacaoFilaModel.Create;
        try
          Notificacao.IdEmpresa := AIdEmpresa;
          Notificacao.IdPedido := AIdPedido;
          Notificacao.Canal := 'EMAIL';
          Notificacao.Destinatario := EmailEmpresa;
          Notificacao.Titulo := 'Novo pedido recebido';
          Notificacao.Mensagem := Mensagem;
          Notificacao.Status := 'PENDENTE';

          TNotificacaoFilaDAO.Inserir(Conn, Notificacao);
        finally
          Notificacao.Free;
        end;
      end;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TNotificacaoFilaService.ListarPorEmpresa(
  const AIdEmpresa: Int64
): TObjectList<TNotificacaoFilaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TNotificacaoFilaDAO.ListarPorEmpresa(Conn, AIdEmpresa);
  finally
    Conn.Free;
  end;
end;

class function TNotificacaoFilaService.ListarPendentes(
  const ACanal: string;
  const ALimite: Integer
): TObjectList<TNotificacaoFilaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Canal: string;
begin
  Canal := UpperCase(Trim(ACanal));

  if (not Canal.IsEmpty) and
     (Canal <> 'WHATSAPP') and
     (Canal <> 'EMAIL') then
    TAppErrors.RaiseBadRequest('Canal de notificação inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TNotificacaoFilaDAO.ListarPendentes(Conn, Canal, ALimite);
  finally
    Conn.Free;
  end;
end;

class procedure TNotificacaoFilaService.MarcarEnviado(
  const AIdNotificacao: Int64
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdNotificacao <= 0 then
    TAppErrors.RaiseBadRequest('Notificação não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TNotificacaoFilaDAO.MarcarEnviado(Conn, AIdNotificacao);
  finally
    Conn.Free;
  end;
end;

class procedure TNotificacaoFilaService.MarcarErro(
  const AIdNotificacao: Int64;
  const AMensagemErro: string
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdNotificacao <= 0 then
    TAppErrors.RaiseBadRequest('Notificação não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TNotificacaoFilaDAO.MarcarErro(Conn, AIdNotificacao, AMensagemErro);
  finally
    Conn.Free;
  end;
end;

class procedure TNotificacaoFilaService.Cancelar(
  const AIdEmpresa: Int64;
  const AIdNotificacao: Int64
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdNotificacao <= 0 then
    TAppErrors.RaiseBadRequest('Notificação não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TNotificacaoFilaDAO.Cancelar(Conn, AIdEmpresa, AIdNotificacao);
  finally
    Conn.Free;
  end;
end;

end.
