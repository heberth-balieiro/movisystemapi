unit PlataformaAjuda.DAO;

interface

uses
  Uni,
  System.Generics.Collections,
  PlataformaAjuda.Model;

type
  TPlataformaAjudaDAO = class
  public
    class function Listar(
      const AConn: TUniConnection;
      const APesquisa,
            ASituacao: string;
      const ASomenteAtivos: Boolean
    ): TObjectList<TPlataformaAjudaModel>; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AId: Int64
    ): TPlataformaAjudaModel; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AModel: TPlataformaAjudaModel
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AModel: TPlataformaAjudaModel
    ); static;

    class procedure AtualizarSituacao(
      const AConn: TUniConnection;
      const AId: Int64;
      const ASituacao: string
    ); static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdUsuario,
            AIdAjuda: Int64;
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

function ModelFromQuery(const Qry: TUniQuery): TPlataformaAjudaModel;
begin
  Result := TPlataformaAjudaModel.Create;
  Result.Id := Qry.FieldByName('id').AsLargeInt;
  Result.UrlYoutube := Qry.FieldByName('url_youtube').AsString;
  Result.Assunto := Qry.FieldByName('assunto').AsString;
  Result.Descricao := Qry.FieldByName('descricao').AsString;
  Result.Situacao := Qry.FieldByName('situacao').AsString;
  Result.Ordem := Qry.FieldByName('ordem').AsInteger;
  Result.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;
  Result.AtualizadoEm := Qry.FieldByName('atualizado_em').AsDateTime;
end;

class function TPlataformaAjudaDAO.Listar(
  const AConn: TUniConnection;
  const APesquisa,
        ASituacao: string;
  const ASomenteAtivos: Boolean
): TObjectList<TPlataformaAjudaModel>;
var
  Qry: TUniQuery;
  Pesquisa: string;
begin
  Result := TObjectList<TPlataformaAjudaModel>.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id, url_youtube, assunto, descricao, situacao, ordem, criado_em, atualizado_em ' +
      'FROM plataforma_ajuda WHERE 1=1 ';

    if ASomenteAtivos then
      Qry.SQL.Add('AND situacao = ''ATIVO'' ')
    else if not Trim(ASituacao).IsEmpty then
      Qry.SQL.Add('AND situacao = :situacao ');

    Pesquisa := Trim(APesquisa);
    if not Pesquisa.IsEmpty then
      Qry.SQL.Add(
        'AND (LOWER(assunto) LIKE :pesquisa OR LOWER(descricao) LIKE :pesquisa) '
      );

    Qry.SQL.Add('ORDER BY ordem ASC, assunto ASC, id ASC');

    if not ASomenteAtivos and not Trim(ASituacao).IsEmpty then
      Qry.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));

    if not Pesquisa.IsEmpty then
      Qry.ParamByName('pesquisa').AsString := '%' + LowerCase(Pesquisa) + '%';

    Qry.Open;
    while not Qry.Eof do
    begin
      Result.Add(ModelFromQuery(Qry));
      Qry.Next;
    end;
  except
    Result.Free;
    raise;
  end;
  Qry.Free;
end;

class function TPlataformaAjudaDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AId: Int64
): TPlataformaAjudaModel;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id, url_youtube, assunto, descricao, situacao, ordem, criado_em, atualizado_em ' +
      'FROM plataforma_ajuda WHERE id = :id LIMIT 1';
    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := ModelFromQuery(Qry);
  finally
    Qry.Free;
  end;
end;

class function TPlataformaAjudaDAO.Inserir(
  const AConn: TUniConnection;
  const AModel: TPlataformaAjudaModel
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO plataforma_ajuda ' +
      '(url_youtube, assunto, descricao, situacao, ordem) ' +
      'VALUES (:url_youtube, :assunto, :descricao, :situacao, :ordem)';
    Qry.ParamByName('url_youtube').AsString := AModel.UrlYoutube;
    Qry.ParamByName('assunto').AsString := AModel.Assunto;
    Qry.ParamByName('descricao').AsString := AModel.Descricao;
    Qry.ParamByName('situacao').AsString := AModel.Situacao;
    Qry.ParamByName('ordem').AsInteger := AModel.Ordem;
    Qry.ExecSQL;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaAjudaDAO.Atualizar(
  const AConn: TUniConnection;
  const AModel: TPlataformaAjudaModel
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE plataforma_ajuda SET ' +
      'url_youtube = :url_youtube, assunto = :assunto, descricao = :descricao, ' +
      'situacao = :situacao, ordem = :ordem ' +
      'WHERE id = :id';
    Qry.ParamByName('url_youtube').AsString := AModel.UrlYoutube;
    Qry.ParamByName('assunto').AsString := AModel.Assunto;
    Qry.ParamByName('descricao').AsString := AModel.Descricao;
    Qry.ParamByName('situacao').AsString := AModel.Situacao;
    Qry.ParamByName('ordem').AsInteger := AModel.Ordem;
    Qry.ParamByName('id').AsLargeInt := AModel.Id;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaAjudaDAO.AtualizarSituacao(
  const AConn: TUniConnection;
  const AId: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE plataforma_ajuda SET situacao = :situacao WHERE id = :id';
    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaAjudaDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdUsuario,
        AIdAjuda: Int64;
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
      '(id_instituicao, id_usuario, id_usuario_instituicao, acao, entidade, registro_id, ' +
      'metodo_http, rota, ip, user_agent, sucesso, mensagem) ' +
      'VALUES (NULL, :id_usuario, NULL, :acao, ''PLATAFORMA_AJUDA'', :registro_id, ' +
      ':metodo, :rota, :ip, :user_agent, 1, :mensagem)';
    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('acao').AsString := AAcao;
    Qry.ParamByName('registro_id').AsString := AIdAjuda.ToString;
    Qry.ParamByName('metodo').AsString := AMetodo;
    Qry.ParamByName('rota').AsString := ARota;
    Qry.ParamByName('ip').AsString := Copy(AIP, 1, 45);
    Qry.ParamByName('user_agent').AsString := Copy(AUserAgent, 1, 1000);
    Qry.ParamByName('mensagem').AsString := Copy(AMensagem, 1, 1000);
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
