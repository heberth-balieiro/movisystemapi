unit PlataformaCampanha.DAO;

interface

uses
  Uni,
  System.JSON;

type
  TPlataformaCampanhaDAO = class
  public
    class function Listar(
      const AConn: TUniConnection;
      const ABusca, ASituacao, ACanal: string;
      const APagina, APorPagina: Integer
    ): TJSONObject; static;

    class function Buscar(
      const AConn: TUniConnection;
      const AId: Int64
    ): TJSONObject; static;

    class function BuscarSituacao(
      const AConn: TUniConnection;
      const AId: Int64
    ): string; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const ANome, ACanal, AAssuntoEmail, ACorpoEmail, AMensagemWhatsApp: string
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AId: Int64;
      const ANome, ACanal, AAssuntoEmail, ACorpoEmail, AMensagemWhatsApp: string
    ); static;

    class function AdicionarDestinatario(
      const AConn: TUniConnection;
      const AIdCampanha: Int64;
      const ANome, AEmail, AWhatsApp, AEmpresa, AOrigem: string
    ): Int64; static;

    class function DestinatarioDuplicado(
      const AConn: TUniConnection;
      const AIdCampanha: Int64;
      const AEmail, AWhatsApp: string
    ): Boolean; static;

    class procedure ExcluirDestinatario(
      const AConn: TUniConnection;
      const AIdCampanha, AIdDestinatario: Int64
    ); static;

    class function AdicionarAnexo(
      const AConn: TUniConnection;
      const AIdCampanha: Int64;
      const ANomeOriginal, ANomeStorage, ACaminhoStorage, AMimeType: string;
      const ATamanhoBytes: Int64
    ): Int64; static;

    class function BuscarAnexos(
      const AConn: TUniConnection;
      const AIdCampanha: Int64
    ): TJSONArray; static;

    class function BuscarCaminhoAnexo(
      const AConn: TUniConnection;
      const AIdCampanha, AIdAnexo: Int64
    ): string; static;

    class procedure ExcluirAnexo(
      const AConn: TUniConnection;
      const AIdCampanha, AIdAnexo: Int64
    ); static;

    class function ContarAnexos(
      const AConn: TUniConnection;
      const AIdCampanha: Int64
    ): Integer; static;

    class function EstaBloqueado(
      const AConn: TUniConnection;
      const ACanal, AValorNormalizado: string
    ): Boolean; static;

    class procedure AdicionarBloqueio(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const ACanal, AValor, AValorNormalizado, AMotivo: string
    ); static;

    class procedure ExcluirBloqueio(
      const AConn: TUniConnection;
      const AId: Int64
    ); static;

    class function ListarBloqueios(
      const AConn: TUniConnection
    ): TJSONArray; static;

    class procedure DefinirWhatsAppRemetente(
      const AConn: TUniConnection;
      const AIdCampanha: Int64;
      const AModo: string;
      const AIdUsuario: Int64;
      const ANomeInstancia: string
    ); static;

    class procedure Iniciar(
      const AConn: TUniConnection;
      const AIdCampanha: Int64
    ); static;

    class procedure Cancelar(
      const AConn: TUniConnection;
      const AIdCampanha: Int64
    ); static;

    class procedure ReprocessarFalhas(
      const AConn: TUniConnection;
      const AIdCampanha: Int64
    ); static;

    class function ProximoEnvio(
      const AConn: TUniConnection
    ): TJSONObject; static;

    class procedure MarcarProcessando(
      const AConn: TUniConnection;
      const AIdEnvio: Int64
    ); static;

    class procedure MarcarEnviado(
      const AConn: TUniConnection;
      const AIdEnvio: Int64;
      const AProviderId: string
    ); static;

    class procedure MarcarFalha(
      const AConn: TUniConnection;
      const AIdEnvio: Int64;
      const AErro: string
    ); static;

    class procedure AtualizarTotaisCampanha(
      const AConn: TUniConnection;
      const AIdCampanha: Int64
    ); static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const AAcao: string;
      const AIdCampanha: Int64;
      const AMensagem, AIP, AUserAgent: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TPlataformaCampanhaDAO.Listar(
  const AConn: TUniConnection;
  const ABusca, ASituacao, ACanal: string;
  const APagina, APorPagina: Integer
): TJSONObject;
var
  Q: TUniQuery;
  Arr: TJSONArray;
  J, Pag: TJSONObject;
  WhereSQL: string;
  Pagina, PorPagina, Total, TotalPaginas: Integer;
begin
  Pagina := APagina;
  if Pagina <= 0 then Pagina := 1;
  PorPagina := APorPagina;
  if PorPagina <= 0 then PorPagina := 50;
  if PorPagina > 100 then PorPagina := 100;

  WhereSQL := ' WHERE 1=1 ';
  if not Trim(ABusca).IsEmpty then
    WhereSQL := WhereSQL + 'AND c.nome LIKE :busca ';
  if not Trim(ASituacao).IsEmpty then
    WhereSQL := WhereSQL + 'AND c.situacao = :situacao ';
  if not Trim(ACanal).IsEmpty then
    WhereSQL := WhereSQL + 'AND c.canal = :canal ';

  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'SELECT COUNT(*) total FROM plataforma_campanha c ' + WhereSQL;
    if not Trim(ABusca).IsEmpty then Q.ParamByName('busca').AsString := '%' + Trim(ABusca) + '%';
    if not Trim(ASituacao).IsEmpty then Q.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));
    if not Trim(ACanal).IsEmpty then Q.ParamByName('canal').AsString := UpperCase(Trim(ACanal));
    Q.Open;
    Total := Q.FieldByName('total').AsInteger;

    Q.Close;
    Q.SQL.Text :=
      'SELECT c.id, c.nome, c.canal, c.situacao, c.total_destinatarios, c.total_envios, ' +
      'c.total_enviados, c.total_falhas, c.iniciado_em, c.concluido_em, c.criado_em, ' +
      'u.nome criado_por_nome ' +
      'FROM plataforma_campanha c JOIN usuario u ON u.id = c.criado_por ' +
      WhereSQL + 'ORDER BY c.criado_em DESC, c.id DESC LIMIT :limite OFFSET :offset';
    if not Trim(ABusca).IsEmpty then Q.ParamByName('busca').AsString := '%' + Trim(ABusca) + '%';
    if not Trim(ASituacao).IsEmpty then Q.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));
    if not Trim(ACanal).IsEmpty then Q.ParamByName('canal').AsString := UpperCase(Trim(ACanal));
    Q.ParamByName('limite').AsInteger := PorPagina;
    Q.ParamByName('offset').AsInteger := (Pagina - 1) * PorPagina;
    Q.Open;

    Arr := TJSONArray.Create;
    while not Q.Eof do
    begin
      J := TJSONObject.Create;
      J.AddPair('id', TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      J.AddPair('nome', Q.FieldByName('nome').AsString);
      J.AddPair('canal', Q.FieldByName('canal').AsString);
      J.AddPair('situacao', Q.FieldByName('situacao').AsString);
      J.AddPair('total_destinatarios', TJSONNumber.Create(Q.FieldByName('total_destinatarios').AsInteger));
      J.AddPair('total_envios', TJSONNumber.Create(Q.FieldByName('total_envios').AsInteger));
      J.AddPair('total_enviados', TJSONNumber.Create(Q.FieldByName('total_enviados').AsInteger));
      J.AddPair('total_falhas', TJSONNumber.Create(Q.FieldByName('total_falhas').AsInteger));
      J.AddPair('criado_por_nome', Q.FieldByName('criado_por_nome').AsString);
      J.AddPair('criado_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Q.FieldByName('criado_em').AsDateTime));
      if Q.FieldByName('iniciado_em').IsNull then J.AddPair('iniciado_em', TJSONNull.Create)
      else J.AddPair('iniciado_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Q.FieldByName('iniciado_em').AsDateTime));
      if Q.FieldByName('concluido_em').IsNull then J.AddPair('concluido_em', TJSONNull.Create)
      else J.AddPair('concluido_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Q.FieldByName('concluido_em').AsDateTime));
      Arr.AddElement(J);
      Q.Next;
    end;

    if Total = 0 then TotalPaginas := 0
    else TotalPaginas := (Total + PorPagina - 1) div PorPagina;

    Pag := TJSONObject.Create;
    Pag.AddPair('pagina', TJSONNumber.Create(Pagina));
    Pag.AddPair('por_pagina', TJSONNumber.Create(PorPagina));
    Pag.AddPair('total', TJSONNumber.Create(Total));
    Pag.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

    Result := TJSONObject.Create;
    Result.AddPair('itens', Arr);
    Result.AddPair('paginacao', Pag);
  finally
    Q.Free;
  end;
end;

class function TPlataformaCampanhaDAO.Buscar(
  const AConn: TUniConnection;
  const AId: Int64
): TJSONObject;
var
  Q: TUniQuery;
  Dest, Anexos, Envios: TJSONArray;
  J: TJSONObject;
begin
  Result := nil;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT c.*, u.nome criado_por_nome FROM plataforma_campanha c ' +
      'JOIN usuario u ON u.id = c.criado_por WHERE c.id = :id LIMIT 1';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.Open;
    if Q.IsEmpty then Exit;

    Result := TJSONObject.Create;
    Result.AddPair('id', TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
    Result.AddPair('nome', Q.FieldByName('nome').AsString);
    Result.AddPair('canal', Q.FieldByName('canal').AsString);
    Result.AddPair('assunto_email', Q.FieldByName('assunto_email').AsString);
    Result.AddPair('corpo_email', Q.FieldByName('corpo_email').AsString);
    Result.AddPair('mensagem_whatsapp', Q.FieldByName('mensagem_whatsapp').AsString);
    Result.AddPair('whatsapp_modo_remetente', Q.FieldByName('whatsapp_modo_remetente').AsString);
    if Q.FieldByName('id_whatsapp_usuario').IsNull then
      Result.AddPair('id_whatsapp_usuario', TJSONNull.Create)
    else
      Result.AddPair('id_whatsapp_usuario', TJSONNumber.Create(Q.FieldByName('id_whatsapp_usuario').AsLargeInt));
    Result.AddPair('whatsapp_instancia', Q.FieldByName('whatsapp_instancia').AsString);
    Result.AddPair('situacao', Q.FieldByName('situacao').AsString);
    Result.AddPair('total_destinatarios', TJSONNumber.Create(Q.FieldByName('total_destinatarios').AsInteger));
    Result.AddPair('total_envios', TJSONNumber.Create(Q.FieldByName('total_envios').AsInteger));
    Result.AddPair('total_enviados', TJSONNumber.Create(Q.FieldByName('total_enviados').AsInteger));
    Result.AddPair('total_falhas', TJSONNumber.Create(Q.FieldByName('total_falhas').AsInteger));
    Result.AddPair('criado_por_nome', Q.FieldByName('criado_por_nome').AsString);
    Result.AddPair('criado_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Q.FieldByName('criado_em').AsDateTime));

    Q.Close;
    Q.SQL.Text :=
      'SELECT id, nome, email, whatsapp, empresa, origem FROM plataforma_campanha_destinatario ' +
      'WHERE id_campanha = :id ORDER BY id';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.Open;
    Dest := TJSONArray.Create;
    while not Q.Eof do
    begin
      J := TJSONObject.Create;
      J.AddPair('id', TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      J.AddPair('nome', Q.FieldByName('nome').AsString);
      J.AddPair('email', Q.FieldByName('email').AsString);
      J.AddPair('whatsapp', Q.FieldByName('whatsapp').AsString);
      J.AddPair('empresa', Q.FieldByName('empresa').AsString);
      J.AddPair('origem', Q.FieldByName('origem').AsString);
      Dest.AddElement(J);
      Q.Next;
    end;
    Result.AddPair('destinatarios', Dest);

    Anexos := BuscarAnexos(AConn, AId);
    Result.AddPair('anexos', Anexos);

    Q.Close;
    Q.SQL.Text :=
      'SELECT e.id, e.canal, e.destinatario, e.situacao, e.tentativas, e.enviado_em, e.ultimo_erro, ' +
      'd.nome destinatario_nome FROM plataforma_campanha_envio e ' +
      'JOIN plataforma_campanha_destinatario d ON d.id = e.id_destinatario ' +
      'WHERE e.id_campanha = :id ORDER BY e.id DESC LIMIT 500';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.Open;
    Envios := TJSONArray.Create;
    while not Q.Eof do
    begin
      J := TJSONObject.Create;
      J.AddPair('id', TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      J.AddPair('nome', Q.FieldByName('destinatario_nome').AsString);
      J.AddPair('canal', Q.FieldByName('canal').AsString);
      J.AddPair('destinatario', Q.FieldByName('destinatario').AsString);
      J.AddPair('situacao', Q.FieldByName('situacao').AsString);
      J.AddPair('tentativas', TJSONNumber.Create(Q.FieldByName('tentativas').AsInteger));
      J.AddPair('ultimo_erro', Q.FieldByName('ultimo_erro').AsString);
      if Q.FieldByName('enviado_em').IsNull then J.AddPair('enviado_em', TJSONNull.Create)
      else J.AddPair('enviado_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Q.FieldByName('enviado_em').AsDateTime));
      Envios.AddElement(J);
      Q.Next;
    end;
    Result.AddPair('envios', Envios);
  finally
    Q.Free;
  end;
end;

class function TPlataformaCampanhaDAO.BuscarSituacao(
  const AConn: TUniConnection; const AId: Int64): string;
var Q: TUniQuery;
begin
  Result := '';
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'SELECT situacao FROM plataforma_campanha WHERE id = :id LIMIT 1';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.Open;
    if not Q.IsEmpty then Result := Q.FieldByName('situacao').AsString;
  finally Q.Free; end;
end;

class function TPlataformaCampanhaDAO.Inserir(
  const AConn: TUniConnection; const AIdUsuario: Int64;
  const ANome, ACanal, AAssuntoEmail, ACorpoEmail, AMensagemWhatsApp: string): Int64;
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO plataforma_campanha ' +
      '(nome, canal, assunto_email, corpo_email, mensagem_whatsapp, criado_por) ' +
      'VALUES (:nome, :canal, :assunto, :corpo, :whatsapp, :usuario)';
    Q.ParamByName('nome').AsString := ANome;
    Q.ParamByName('canal').AsString := ACanal;
    if AAssuntoEmail.IsEmpty then Q.ParamByName('assunto').Clear else Q.ParamByName('assunto').AsString := AAssuntoEmail;
    if ACorpoEmail.IsEmpty then Q.ParamByName('corpo').Clear else Q.ParamByName('corpo').AsString := ACorpoEmail;
    if AMensagemWhatsApp.IsEmpty then Q.ParamByName('whatsapp').Clear else Q.ParamByName('whatsapp').AsString := AMensagemWhatsApp;
    Q.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Q.Execute;
    Q.SQL.Text := 'SELECT LAST_INSERT_ID() id';
    Q.Open;
    Result := Q.FieldByName('id').AsLargeInt;
  finally Q.Free; end;
end;

class procedure TPlataformaCampanhaDAO.Atualizar(
  const AConn: TUniConnection; const AId: Int64;
  const ANome, ACanal, AAssuntoEmail, ACorpoEmail, AMensagemWhatsApp: string);
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'UPDATE plataforma_campanha SET nome=:nome, canal=:canal, assunto_email=:assunto, ' +
      'corpo_email=:corpo, mensagem_whatsapp=:whatsapp WHERE id=:id AND situacao=''RASCUNHO''';
    Q.ParamByName('nome').AsString := ANome;
    Q.ParamByName('canal').AsString := ACanal;
    if AAssuntoEmail.IsEmpty then Q.ParamByName('assunto').Clear else Q.ParamByName('assunto').AsString := AAssuntoEmail;
    if ACorpoEmail.IsEmpty then Q.ParamByName('corpo').Clear else Q.ParamByName('corpo').AsString := ACorpoEmail;
    if AMensagemWhatsApp.IsEmpty then Q.ParamByName('whatsapp').Clear else Q.ParamByName('whatsapp').AsString := AMensagemWhatsApp;
    Q.ParamByName('id').AsLargeInt := AId;
    Q.Execute;
  finally Q.Free; end;
end;

class function TPlataformaCampanhaDAO.DestinatarioDuplicado(
  const AConn: TUniConnection; const AIdCampanha: Int64;
  const AEmail, AWhatsApp: string): Boolean;
var Q: TUniQuery;
begin
  Result := False;
  if AEmail.IsEmpty and AWhatsApp.IsEmpty then Exit;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT 1 FROM plataforma_campanha_destinatario WHERE id_campanha=:id AND (' +
      '(:email <> '''' AND email=:email) OR (:whatsapp <> '''' AND whatsapp=:whatsapp)) LIMIT 1';
    Q.ParamByName('id').AsLargeInt := AIdCampanha;
    Q.ParamByName('email').AsString := AEmail;
    Q.ParamByName('whatsapp').AsString := AWhatsApp;
    Q.Open;
    Result := not Q.IsEmpty;
  finally Q.Free; end;
end;

class function TPlataformaCampanhaDAO.AdicionarDestinatario(
  const AConn: TUniConnection; const AIdCampanha: Int64;
  const ANome, AEmail, AWhatsApp, AEmpresa, AOrigem: string): Int64;
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO plataforma_campanha_destinatario ' +
      '(id_campanha,nome,email,whatsapp,empresa,origem) VALUES ' +
      '(:campanha,:nome,:email,:whatsapp,:empresa,:origem)';
    Q.ParamByName('campanha').AsLargeInt := AIdCampanha;
    Q.ParamByName('nome').AsString := ANome;
    if AEmail.IsEmpty then Q.ParamByName('email').Clear else Q.ParamByName('email').AsString := AEmail;
    if AWhatsApp.IsEmpty then Q.ParamByName('whatsapp').Clear else Q.ParamByName('whatsapp').AsString := AWhatsApp;
    if AEmpresa.IsEmpty then Q.ParamByName('empresa').Clear else Q.ParamByName('empresa').AsString := AEmpresa;
    Q.ParamByName('origem').AsString := AOrigem;
    Q.Execute;
    Q.SQL.Text := 'SELECT LAST_INSERT_ID() id';
    Q.Open;
    Result := Q.FieldByName('id').AsLargeInt;
  finally Q.Free; end;
end;

class procedure TPlataformaCampanhaDAO.ExcluirDestinatario(
  const AConn: TUniConnection; const AIdCampanha, AIdDestinatario: Int64);
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'DELETE d FROM plataforma_campanha_destinatario d ' +
      'JOIN plataforma_campanha c ON c.id=d.id_campanha ' +
      'WHERE d.id_campanha=:campanha AND d.id=:id AND c.situacao=''RASCUNHO''';
    Q.ParamByName('campanha').AsLargeInt := AIdCampanha;
    Q.ParamByName('id').AsLargeInt := AIdDestinatario;
    Q.Execute;
  finally Q.Free; end;
end;

class function TPlataformaCampanhaDAO.AdicionarAnexo(
  const AConn: TUniConnection; const AIdCampanha: Int64;
  const ANomeOriginal, ANomeStorage, ACaminhoStorage, AMimeType: string;
  const ATamanhoBytes: Int64): Int64;
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO plataforma_campanha_anexo ' +
      '(id_campanha,nome_original,nome_storage,caminho_storage,mime_type,tamanho_bytes) VALUES ' +
      '(:campanha,:original,:storage,:caminho,:mime,:tamanho)';
    Q.ParamByName('campanha').AsLargeInt := AIdCampanha;
    Q.ParamByName('original').AsString := ANomeOriginal;
    Q.ParamByName('storage').AsString := ANomeStorage;
    Q.ParamByName('caminho').AsString := ACaminhoStorage;
    Q.ParamByName('mime').AsString := AMimeType;
    Q.ParamByName('tamanho').AsLargeInt := ATamanhoBytes;
    Q.Execute;
    Q.SQL.Text := 'SELECT LAST_INSERT_ID() id';
    Q.Open;
    Result := Q.FieldByName('id').AsLargeInt;
  finally Q.Free; end;
end;

class function TPlataformaCampanhaDAO.BuscarAnexos(
  const AConn: TUniConnection; const AIdCampanha: Int64): TJSONArray;
var Q: TUniQuery; J:TJSONObject;
begin
  Result := TJSONArray.Create;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'SELECT id,nome_original,nome_storage,caminho_storage,mime_type,tamanho_bytes ' +
      'FROM plataforma_campanha_anexo WHERE id_campanha=:id ORDER BY id';
    Q.ParamByName('id').AsLargeInt := AIdCampanha;
    Q.Open;
    while not Q.Eof do
    begin
      J:=TJSONObject.Create;
      J.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      J.AddPair('nome_original',Q.FieldByName('nome_original').AsString);
      J.AddPair('nome_storage',Q.FieldByName('nome_storage').AsString);
      J.AddPair('caminho_storage',Q.FieldByName('caminho_storage').AsString);
      J.AddPair('mime_type',Q.FieldByName('mime_type').AsString);
      J.AddPair('tamanho_bytes',TJSONNumber.Create(Q.FieldByName('tamanho_bytes').AsLargeInt));
      Result.AddElement(J);
      Q.Next;
    end;
  finally Q.Free; end;
end;

class function TPlataformaCampanhaDAO.BuscarCaminhoAnexo(
  const AConn: TUniConnection; const AIdCampanha, AIdAnexo: Int64): string;
var Q:TUniQuery;
begin
  Result:='';
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:='SELECT caminho_storage FROM plataforma_campanha_anexo WHERE id_campanha=:c AND id=:id LIMIT 1';
    Q.ParamByName('c').AsLargeInt:=AIdCampanha;
    Q.ParamByName('id').AsLargeInt:=AIdAnexo;
    Q.Open;
    if not Q.IsEmpty then Result:=Q.FieldByName('caminho_storage').AsString;
  finally Q.Free; end;
end;

class procedure TPlataformaCampanhaDAO.ExcluirAnexo(
  const AConn: TUniConnection; const AIdCampanha, AIdAnexo: Int64);
var Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:='DELETE a FROM plataforma_campanha_anexo a JOIN plataforma_campanha c ON c.id=a.id_campanha '+
      'WHERE a.id_campanha=:c AND a.id=:id AND c.situacao=''RASCUNHO''';
    Q.ParamByName('c').AsLargeInt:=AIdCampanha;
    Q.ParamByName('id').AsLargeInt:=AIdAnexo;
    Q.Execute;
  finally Q.Free; end;
end;

class function TPlataformaCampanhaDAO.ContarAnexos(
  const AConn: TUniConnection; const AIdCampanha: Int64): Integer;
var Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:='SELECT COUNT(*) total FROM plataforma_campanha_anexo WHERE id_campanha=:id';
    Q.ParamByName('id').AsLargeInt:=AIdCampanha;
    Q.Open; Result:=Q.FieldByName('total').AsInteger;
  finally Q.Free; end;
end;

class function TPlataformaCampanhaDAO.EstaBloqueado(
  const AConn: TUniConnection; const ACanal, AValorNormalizado: string): Boolean;
var Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:='SELECT 1 FROM plataforma_contato_bloqueio WHERE canal=:canal AND valor_normalizado=:valor LIMIT 1';
    Q.ParamByName('canal').AsString:=ACanal;
    Q.ParamByName('valor').AsString:=AValorNormalizado;
    Q.Open; Result:=not Q.IsEmpty;
  finally Q.Free; end;
end;

class procedure TPlataformaCampanhaDAO.AdicionarBloqueio(
  const AConn: TUniConnection; const AIdUsuario: Int64;
  const ACanal,AValor,AValorNormalizado,AMotivo:string);
var Q:TUniQuery;
begin
 Q:=TUniQuery.Create(nil);
 try
  Q.Connection:=AConn;
  Q.SQL.Text:='INSERT INTO plataforma_contato_bloqueio (canal,valor,valor_normalizado,motivo,criado_por) '+
   'VALUES (:canal,:valor,:norm,:motivo,:usuario) ON DUPLICATE KEY UPDATE valor=VALUES(valor), motivo=VALUES(motivo)';
  Q.ParamByName('canal').AsString:=ACanal;
  Q.ParamByName('valor').AsString:=AValor;
  Q.ParamByName('norm').AsString:=AValorNormalizado;
  if AMotivo.IsEmpty then Q.ParamByName('motivo').Clear else Q.ParamByName('motivo').AsString:=AMotivo;
  Q.ParamByName('usuario').AsLargeInt:=AIdUsuario;
  Q.Execute;
 finally Q.Free; end;
end;

class procedure TPlataformaCampanhaDAO.ExcluirBloqueio(
  const AConn: TUniConnection; const AId:Int64);
var Q:TUniQuery;
begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
 Q.SQL.Text:='DELETE FROM plataforma_contato_bloqueio WHERE id=:id';
 Q.ParamByName('id').AsLargeInt:=AId; Q.Execute; finally Q.Free; end; end;

class function TPlataformaCampanhaDAO.ListarBloqueios(
  const AConn: TUniConnection):TJSONArray;
var Q:TUniQuery;J:TJSONObject;
begin
 Result:=TJSONArray.Create; Q:=TUniQuery.Create(nil);
 try Q.Connection:=AConn; Q.SQL.Text:='SELECT id,canal,valor,motivo,criado_em FROM plataforma_contato_bloqueio ORDER BY criado_em DESC,id DESC';
 Q.Open; while not Q.Eof do begin J:=TJSONObject.Create;
 J.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt)); J.AddPair('canal',Q.FieldByName('canal').AsString);
 J.AddPair('valor',Q.FieldByName('valor').AsString); J.AddPair('motivo',Q.FieldByName('motivo').AsString);
 J.AddPair('criado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('criado_em').AsDateTime));
 Result.AddElement(J); Q.Next; end; finally Q.Free; end;
end;

class procedure TPlataformaCampanhaDAO.DefinirWhatsAppRemetente(
  const AConn: TUniConnection;
  const AIdCampanha: Int64;
  const AModo: string;
  const AIdUsuario: Int64;
  const ANomeInstancia: string
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'UPDATE plataforma_campanha SET ' +
      'whatsapp_modo_remetente = :modo, ' +
      'id_whatsapp_usuario = :id_usuario, ' +
      'whatsapp_instancia = :instancia ' +
      'WHERE id = :id AND situacao = ''RASCUNHO''';

    Q.ParamByName('modo').AsString := UpperCase(Trim(AModo));

    if AIdUsuario > 0 then
      Q.ParamByName('id_usuario').AsLargeInt := AIdUsuario
    else
      Q.ParamByName('id_usuario').Clear;

    Q.ParamByName('instancia').AsString := Trim(ANomeInstancia);
    Q.ParamByName('id').AsLargeInt := AIdCampanha;
    Q.Execute;
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaCampanhaDAO.Iniciar(
  const AConn:TUniConnection; const AIdCampanha:Int64);
var Q:TUniQuery;
begin
 Q:=TUniQuery.Create(nil);
 try
  Q.Connection:=AConn;
  Q.SQL.Text:='UPDATE plataforma_campanha SET situacao=''PROCESSANDO'', iniciado_em=CURRENT_TIMESTAMP(3), concluido_em=NULL '+
    'WHERE id=:id AND situacao=''RASCUNHO''';
  Q.ParamByName('id').AsLargeInt:=AIdCampanha; Q.Execute;
  if Q.RowsAffected<>1 then raise Exception.Create('A campanha não está disponível para início.');

  Q.SQL.Text:=
   'INSERT IGNORE INTO plataforma_campanha_envio (id_campanha,id_destinatario,canal,destinatario) '+
   'SELECT c.id,d.id,''EMAIL'',d.email FROM plataforma_campanha c JOIN plataforma_campanha_destinatario d ON d.id_campanha=c.id '+
   'LEFT JOIN plataforma_contato_bloqueio b ON b.canal=''EMAIL'' AND b.valor_normalizado=LOWER(TRIM(d.email)) '+
   'WHERE c.id=:id AND c.canal IN (''EMAIL'',''AMBOS'') AND d.email IS NOT NULL AND d.email<>'''' AND b.id IS NULL';
  Q.ParamByName('id').AsLargeInt:=AIdCampanha; Q.Execute;

  Q.SQL.Text:=
   'INSERT IGNORE INTO plataforma_campanha_envio (id_campanha,id_destinatario,canal,destinatario) '+
   'SELECT c.id,d.id,''WHATSAPP'',d.whatsapp FROM plataforma_campanha c JOIN plataforma_campanha_destinatario d ON d.id_campanha=c.id '+
   'LEFT JOIN plataforma_contato_bloqueio b ON b.canal=''WHATSAPP'' AND b.valor_normalizado=d.whatsapp '+
   'WHERE c.id=:id AND c.canal IN (''WHATSAPP'',''AMBOS'') AND d.whatsapp IS NOT NULL AND d.whatsapp<>'''' AND b.id IS NULL';
  Q.ParamByName('id').AsLargeInt:=AIdCampanha; Q.Execute;
  AtualizarTotaisCampanha(AConn,AIdCampanha);
 finally Q.Free; end;
end;

class procedure TPlataformaCampanhaDAO.Cancelar(
  const AConn:TUniConnection; const AIdCampanha:Int64);
var Q:TUniQuery;
begin
 Q:=TUniQuery.Create(nil);
 try Q.Connection:=AConn;
  Q.SQL.Text:='UPDATE plataforma_campanha SET situacao=''CANCELADA'',cancelado_em=CURRENT_TIMESTAMP(3) '+
   'WHERE id=:id AND situacao IN (''RASCUNHO'',''PROCESSANDO'')';
  Q.ParamByName('id').AsLargeInt:=AIdCampanha; Q.Execute;
  Q.SQL.Text:='UPDATE plataforma_campanha_envio SET situacao=''CANCELADO'' WHERE id_campanha=:id AND situacao=''PENDENTE''';
  Q.ParamByName('id').AsLargeInt:=AIdCampanha; Q.Execute;
  AtualizarTotaisCampanha(AConn,AIdCampanha);
 finally Q.Free; end;
end;

class procedure TPlataformaCampanhaDAO.ReprocessarFalhas(
 const AConn:TUniConnection; const AIdCampanha:Int64);
var Q:TUniQuery;
begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
 Q.SQL.Text:='UPDATE plataforma_campanha_envio SET situacao=''PENDENTE'',proxima_tentativa_em=NULL,ultimo_erro=NULL '+
  'WHERE id_campanha=:id AND situacao=''FALHA''';
 Q.ParamByName('id').AsLargeInt:=AIdCampanha; Q.Execute;
 Q.SQL.Text:='UPDATE plataforma_campanha SET situacao=''PROCESSANDO'',concluido_em=NULL WHERE id=:id AND situacao<>''CANCELADA''';
 Q.ParamByName('id').AsLargeInt:=AIdCampanha; Q.Execute;
 AtualizarTotaisCampanha(AConn,AIdCampanha);
 finally Q.Free; end; end;

class function TPlataformaCampanhaDAO.ProximoEnvio(
 const AConn:TUniConnection):TJSONObject;
var Q:TUniQuery;
begin
 Result:=nil; Q:=TUniQuery.Create(nil);
 try Q.Connection:=AConn;
 Q.SQL.Text:=
  'SELECT e.id,e.id_campanha,e.canal,e.destinatario,d.nome,d.empresa,c.assunto_email,c.corpo_email,c.mensagem_whatsapp, '+
  'c.whatsapp_modo_remetente,c.id_whatsapp_usuario,c.whatsapp_instancia '+
  'FROM plataforma_campanha_envio e JOIN plataforma_campanha c ON c.id=e.id_campanha '+
  'JOIN plataforma_campanha_destinatario d ON d.id=e.id_destinatario '+
  'WHERE c.situacao=''PROCESSANDO'' AND e.situacao=''PENDENTE'' '+
  'AND (e.proxima_tentativa_em IS NULL OR e.proxima_tentativa_em<=CURRENT_TIMESTAMP(3)) '+
  'ORDER BY e.id LIMIT 1 FOR UPDATE SKIP LOCKED';
 Q.Open; if Q.IsEmpty then Exit;
 Result:=TJSONObject.Create;
 Result.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
 Result.AddPair('id_campanha',TJSONNumber.Create(Q.FieldByName('id_campanha').AsLargeInt));
 Result.AddPair('canal',Q.FieldByName('canal').AsString); Result.AddPair('destinatario',Q.FieldByName('destinatario').AsString);
 Result.AddPair('nome',Q.FieldByName('nome').AsString); Result.AddPair('empresa',Q.FieldByName('empresa').AsString);
 Result.AddPair('assunto_email',Q.FieldByName('assunto_email').AsString); Result.AddPair('corpo_email',Q.FieldByName('corpo_email').AsString);
 Result.AddPair('mensagem_whatsapp',Q.FieldByName('mensagem_whatsapp').AsString);
 Result.AddPair('whatsapp_modo_remetente',Q.FieldByName('whatsapp_modo_remetente').AsString);
 if Q.FieldByName('id_whatsapp_usuario').IsNull then Result.AddPair('id_whatsapp_usuario',TJSONNull.Create)
 else Result.AddPair('id_whatsapp_usuario',TJSONNumber.Create(Q.FieldByName('id_whatsapp_usuario').AsLargeInt));
 Result.AddPair('whatsapp_instancia',Q.FieldByName('whatsapp_instancia').AsString);
 finally Q.Free; end;
end;

class procedure TPlataformaCampanhaDAO.MarcarProcessando(const AConn:TUniConnection; const AIdEnvio:Int64);
var Q:TUniQuery; begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
 Q.SQL.Text:='UPDATE plataforma_campanha_envio SET situacao=''PROCESSANDO'',processando_em=CURRENT_TIMESTAMP(3),tentativas=tentativas+1 WHERE id=:id AND situacao=''PENDENTE''';
 Q.ParamByName('id').AsLargeInt:=AIdEnvio; Q.Execute; finally Q.Free; end; end;

class procedure TPlataformaCampanhaDAO.MarcarEnviado(const AConn:TUniConnection; const AIdEnvio:Int64; const AProviderId:string);
var Q:TUniQuery; begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
 Q.SQL.Text:='UPDATE plataforma_campanha_envio SET situacao=''ENVIADO'',enviado_em=CURRENT_TIMESTAMP(3),ultimo_erro=NULL,provider_id=:provider WHERE id=:id';
 if AProviderId.IsEmpty then Q.ParamByName('provider').Clear else Q.ParamByName('provider').AsString:=Copy(AProviderId,1,255);
 Q.ParamByName('id').AsLargeInt:=AIdEnvio; Q.Execute; finally Q.Free; end; end;

class procedure TPlataformaCampanhaDAO.MarcarFalha(const AConn:TUniConnection; const AIdEnvio:Int64; const AErro:string);
var Q:TUniQuery; begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
 Q.SQL.Text:='UPDATE plataforma_campanha_envio SET situacao=''FALHA'',ultimo_erro=:erro,proxima_tentativa_em=NULL WHERE id=:id';
 Q.ParamByName('erro').AsString:=Copy(Trim(AErro),1,1000); Q.ParamByName('id').AsLargeInt:=AIdEnvio; Q.Execute; finally Q.Free; end; end;

class procedure TPlataformaCampanhaDAO.AtualizarTotaisCampanha(const AConn:TUniConnection; const AIdCampanha:Int64);
var Q:TUniQuery;
begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
 Q.SQL.Text:=
  'UPDATE plataforma_campanha c SET '+
  'total_destinatarios=(SELECT COUNT(*) FROM plataforma_campanha_destinatario d WHERE d.id_campanha=c.id), '+
  'total_envios=(SELECT COUNT(*) FROM plataforma_campanha_envio e WHERE e.id_campanha=c.id), '+
  'total_enviados=(SELECT COUNT(*) FROM plataforma_campanha_envio e WHERE e.id_campanha=c.id AND e.situacao=''ENVIADO''), '+
  'total_falhas=(SELECT COUNT(*) FROM plataforma_campanha_envio e WHERE e.id_campanha=c.id AND e.situacao=''FALHA'') '+
  'WHERE c.id=:id';
 Q.ParamByName('id').AsLargeInt:=AIdCampanha; Q.Execute;

 Q.SQL.Text:=
  'UPDATE plataforma_campanha c SET situacao=''CONCLUIDA'',concluido_em=CURRENT_TIMESTAMP(3) '+
  'WHERE c.id=:id AND c.situacao=''PROCESSANDO'' AND NOT EXISTS ('+
  'SELECT 1 FROM plataforma_campanha_envio e WHERE e.id_campanha=c.id AND e.situacao IN (''PENDENTE'',''PROCESSANDO''))';
 Q.ParamByName('id').AsLargeInt:=AIdCampanha; Q.Execute;
 finally Q.Free; end; end;

class procedure TPlataformaCampanhaDAO.RegistrarAuditoria(
 const AConn:TUniConnection; const AIdUsuario:Int64; const AAcao:string;
 const AIdCampanha:Int64; const AMensagem,AIP,AUserAgent:string);
var Q:TUniQuery;
begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
 Q.SQL.Text:='INSERT INTO auditoria_log (id_instituicao,id_usuario,id_usuario_instituicao,acao,entidade,registro_id,metodo_http,rota,ip,user_agent,sucesso,mensagem) '+
 'VALUES (NULL,:usuario,NULL,:acao,''plataforma_campanha'',:registro,''POST'',''/v1/certifica/plataforma/campanhas'',:ip,:ua,1,:msg)';
 Q.ParamByName('usuario').AsLargeInt:=AIdUsuario; Q.ParamByName('acao').AsString:=AAcao;
 Q.ParamByName('registro').AsString:=AIdCampanha.ToString; Q.ParamByName('ip').AsString:=Copy(Trim(AIP),1,45);
 Q.ParamByName('ua').AsString:=Copy(Trim(AUserAgent),1,1000); Q.ParamByName('msg').AsString:=Copy(Trim(AMensagem),1,1000); Q.Execute;
 finally Q.Free; end; end;

end.
