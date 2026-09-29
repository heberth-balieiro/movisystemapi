unit LgpdSolicitacao.DAO;

interface

uses
  Uni,
  LgpdSolicitacao.Model;

type
  TLgpdSolicitacaoDAO = class
  private
    class function Mapear(
      const AQry: TUniQuery
    ): TLgpdSolicitacaoItem; static;

  public
    class function BuscarParticipantePorUsuario(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): Int64; static;

    class function ExisteProtocolo(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AProtocolo: string
    ): Boolean; static;

    class function ExistePendenteMesmoTipo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64;
      const ATipo: string
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64;
      const AProtocolo,
            ATipo,
            ADescricao: string
    ): Int64; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AId: Int64
    ): TLgpdSolicitacaoItem; static;

    class function ListarDoParticipante(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64
    ): TLgpdSolicitacaoResultado; static;

    class function ListarInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TLgpdSolicitacaoFiltro
    ): TLgpdSolicitacaoResultado; static;

    class procedure CancelarDoParticipante(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante,
            AId: Int64
    ); static;

    class procedure AtualizarAnalise(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AId,
            AResponsavel: Int64;
      const ASituacao,
            AResposta: string
    ); static;
  end;

implementation

uses
  System.SysUtils,
  APP.Errors;

class function TLgpdSolicitacaoDAO.Mapear(
  const AQry: TUniQuery
): TLgpdSolicitacaoItem;
begin
  Result := TLgpdSolicitacaoItem.Create;

  Result.Id := AQry.FieldByName('id').AsLargeInt;
  Result.IdParticipante := AQry.FieldByName('id_participante').AsLargeInt;
  Result.ParticipanteNome := AQry.FieldByName('participante_nome').AsString;
  Result.Protocolo := AQry.FieldByName('protocolo').AsString;
  Result.Tipo := AQry.FieldByName('tipo').AsString;
  Result.Situacao := AQry.FieldByName('situacao').AsString;
  Result.Descricao := AQry.FieldByName('descricao').AsString;
  Result.Resposta := AQry.FieldByName('resposta').AsString;
  Result.SolicitadoEm := AQry.FieldByName('solicitado_em').AsDateTime;
  Result.TemConcluidoEm := not AQry.FieldByName('concluido_em').IsNull;

  if Result.TemConcluidoEm then
    Result.ConcluidoEm := AQry.FieldByName('concluido_em').AsDateTime;

  Result.ResponsavelNome := AQry.FieldByName('responsavel_nome').AsString;
  Result.AtualizadoEm := AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TLgpdSolicitacaoDAO.BuscarParticipantePorUsuario(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_usuario_instituicao = :id_usuario_instituicao ' +
      'AND situacao <> ''ANONIMIZADO'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_usuario_instituicao').AsLargeInt := AIdUsuarioInstituicao;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TLgpdSolicitacaoDAO.ExisteProtocolo(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AProtocolo: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM lgpd_solicitacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND protocolo = :protocolo LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('protocolo').AsString := AProtocolo;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TLgpdSolicitacaoDAO.ExistePendenteMesmoTipo(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64;
  const ATipo: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM lgpd_solicitacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_participante = :id_participante ' +
      'AND tipo = :tipo ' +
      'AND situacao IN (''ABERTA'', ''EM_ANALISE'') LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AIdParticipante;
    Qry.ParamByName('tipo').AsString := ATipo;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TLgpdSolicitacaoDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64;
  const AProtocolo,
        ATipo,
        ADescricao: string
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO lgpd_solicitacao (' +
      'id_instituicao, id_participante, protocolo, tipo, situacao, descricao' +
      ') VALUES (' +
      ':id_instituicao, :id_participante, :protocolo, :tipo, ''ABERTA'', :descricao' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AIdParticipante;
    Qry.ParamByName('protocolo').AsString := AProtocolo;
    Qry.ParamByName('tipo').AsString := ATipo;

    if Trim(ADescricao).IsEmpty then
      Qry.ParamByName('descricao').Clear
    else
      Qry.ParamByName('descricao').AsString := Trim(ADescricao);

    Qry.Execute;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TLgpdSolicitacaoDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AId: Int64
): TLgpdSolicitacaoItem;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT s.*, p.nome AS participante_nome, u.nome AS responsavel_nome ' +
      'FROM lgpd_solicitacao s ' +
      'LEFT JOIN participante p ON p.id_instituicao = s.id_instituicao ' +
      ' AND p.id = s.id_participante ' +
      'LEFT JOIN usuario_instituicao ui ON ui.id_instituicao = s.id_instituicao ' +
      ' AND ui.id = s.responsavel ' +
      'LEFT JOIN usuario u ON u.id = ui.id_usuario ' +
      'WHERE s.id_instituicao = :id_instituicao AND s.id = :id LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Mapear(Qry);
  finally
    Qry.Free;
  end;
end;

class function TLgpdSolicitacaoDAO.ListarDoParticipante(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64
): TLgpdSolicitacaoResultado;
var
  Qry: TUniQuery;
begin
  Result := TLgpdSolicitacaoResultado.Create;
  Result.Pagina := 1;
  Result.PorPagina := 100;

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        'SELECT s.*, p.nome AS participante_nome, u.nome AS responsavel_nome ' +
        'FROM lgpd_solicitacao s ' +
        'LEFT JOIN participante p ON p.id_instituicao = s.id_instituicao ' +
        ' AND p.id = s.id_participante ' +
        'LEFT JOIN usuario_instituicao ui ON ui.id_instituicao = s.id_instituicao ' +
        ' AND ui.id = s.responsavel ' +
        'LEFT JOIN usuario u ON u.id = ui.id_usuario ' +
        'WHERE s.id_instituicao = :id_instituicao ' +
        'AND s.id_participante = :id_participante ' +
        'ORDER BY s.solicitado_em DESC, s.id DESC LIMIT 100';

      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.ParamByName('id_participante').AsLargeInt := AIdParticipante;
      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Itens.Add(Mapear(Qry));
        Qry.Next;
      end;

      Result.Total := Result.Itens.Count;
    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

class function TLgpdSolicitacaoDAO.ListarInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TLgpdSolicitacaoFiltro
): TLgpdSolicitacaoResultado;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;

  procedure AplicarParametros;
  begin
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

    if not Trim(AFiltro.Busca).IsEmpty then
      Qry.ParamByName('busca').AsString :=
        '%' + Trim(AFiltro.Busca) + '%';

    if not Trim(AFiltro.Tipo).IsEmpty then
      Qry.ParamByName('tipo').AsString := UpperCase(Trim(AFiltro.Tipo));

    if not Trim(AFiltro.Situacao).IsEmpty then
      Qry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));
  end;

begin
  Result := TLgpdSolicitacaoResultado.Create;
  Result.Pagina := AFiltro.Pagina;
  Result.PorPagina := AFiltro.PorPagina;
  Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

  WhereSQL := ' WHERE s.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    WhereSQL := WhereSQL +
      'AND (s.protocolo LIKE :busca OR p.nome LIKE :busca) ';

  if not Trim(AFiltro.Tipo).IsEmpty then
    WhereSQL := WhereSQL + 'AND s.tipo = :tipo ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    WhereSQL := WhereSQL + 'AND s.situacao = :situacao ';

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM lgpd_solicitacao s ' +
        'LEFT JOIN participante p ON p.id_instituicao = s.id_instituicao ' +
        ' AND p.id = s.id_participante ' +
        WhereSQL;

      AplicarParametros;
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;

      Qry.Close;
      Qry.SQL.Clear;

      Qry.SQL.Text :=
        'SELECT s.*, p.nome AS participante_nome, u.nome AS responsavel_nome ' +
        'FROM lgpd_solicitacao s ' +
        'LEFT JOIN participante p ON p.id_instituicao = s.id_instituicao ' +
        ' AND p.id = s.id_participante ' +
        'LEFT JOIN usuario_instituicao ui ON ui.id_instituicao = s.id_instituicao ' +
        ' AND ui.id = s.responsavel ' +
        'LEFT JOIN usuario u ON u.id = ui.id_usuario ' +
        WhereSQL +
        'ORDER BY s.solicitado_em DESC, s.id DESC ' +
        'LIMIT :limite OFFSET :offset';

      AplicarParametros;
      Qry.ParamByName('limite').AsInteger := AFiltro.PorPagina;
      Qry.ParamByName('offset').AsInteger := Offset;
      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Itens.Add(Mapear(Qry));
        Qry.Next;
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TLgpdSolicitacaoDAO.CancelarDoParticipante(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante,
        AId: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE lgpd_solicitacao SET ' +
      'situacao = ''CANCELADA'', ' +
      'concluido_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_participante = :id_participante ' +
      'AND id = :id ' +
      'AND situacao IN (''ABERTA'', ''EM_ANALISE'')';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AIdParticipante;
    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.Execute;

    if Qry.RowsAffected <> 1 then
      TAppErrors.RaiseBadRequest(
        'A solicitação não pode mais ser cancelada.'
      );
  finally
    Qry.Free;
  end;
end;

class procedure TLgpdSolicitacaoDAO.AtualizarAnalise(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AId,
        AResponsavel: Int64;
  const ASituacao,
        AResposta: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE lgpd_solicitacao SET ' +
      'situacao = :situacao, ' +
      'resposta = :resposta, ' +
      'responsavel = :responsavel, ' +
      'concluido_em = :concluido_em ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id ' +
      'AND situacao IN (''ABERTA'', ''EM_ANALISE'')';

    Qry.ParamByName('situacao').AsString := ASituacao;

    if Trim(AResposta).IsEmpty then
      Qry.ParamByName('resposta').Clear
    else
      Qry.ParamByName('resposta').AsString := Trim(AResposta);

    Qry.ParamByName('responsavel').AsLargeInt := AResponsavel;

    if ASituacao = 'EM_ANALISE' then
      Qry.ParamByName('concluido_em').Clear
    else
      Qry.ParamByName('concluido_em').AsDateTime := Now;

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.Execute;

    if Qry.RowsAffected <> 1 then
      TAppErrors.RaiseBadRequest(
        'A solicitação já foi concluída ou alterada por outro usuário.'
      );
  finally
    Qry.Free;
  end;
end;

end.
