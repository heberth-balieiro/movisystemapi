unit Contrato.DAO;

interface

uses
  Uni,
  Contrato.Model;

type
  TContratoDAO = class
  private
    class function MontarWhere(const AFiltro: TContratoFiltro): string; static;
    class procedure AplicarFiltro(const AQry: TUniQuery; const AIdInstituicao: Int64; const AFiltro: TContratoFiltro); static;
    class function PreencherItem(const AQry: TUniQuery): TContratoItem; static;
  public
    class function GarantirEntidade(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADocumento, ANome: string
    ): Int64; static;

    class function ExisteNumero(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ANumero: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TContratoFiltro
    ): TContratoLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato: Int64
    ): TContratoItem; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdUsuario, AIdEntidade: Int64;
      const ACodigoPublico: string;
      const ADados: TContratoCadastro
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdUsuario, AIdEntidade: Int64;
      const ADados: TContratoCadastro
    ); static;

    class procedure InserirHistorico(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
      const AEvento, ADescricao: string
    ); static;

    class procedure AlterarSituacaoFinal(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
      const ASituacao, AMotivo: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TContratoDAO.GarantirEntidade(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADocumento, ANome: string
): Int64;
var
  Qry: TUniQuery;
  Documento: string;
begin
  Result := 0;
  Documento := Trim(ADocumento);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    if not Documento.IsEmpty then
    begin
      Qry.SQL.Text :=
        'SELECT id FROM contrato_entidade ' +
        'WHERE id_instituicao=:id_instituicao AND documento=:documento LIMIT 1';
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.ParamByName('documento').AsString := Documento;
      Qry.Open;
      if not Qry.IsEmpty then
      begin
        Result := Qry.FieldByName('id').AsLargeInt;
        Qry.Close;
        Qry.SQL.Text :=
          'UPDATE contrato_entidade SET nome=:nome,situacao=''ATIVA'' ' +
          'WHERE id_instituicao=:id_instituicao AND id=:id';
        Qry.ParamByName('nome').AsString := Trim(ANome);
        Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
        Qry.ParamByName('id').AsLargeInt := Result;
        Qry.ExecSQL;
        Exit;
      end;
      Qry.Close;
    end;

    Qry.SQL.Text :=
      'INSERT INTO contrato_entidade(id_instituicao,tipo_pessoa,documento,nome,situacao) ' +
      'VALUES(:id_instituicao,:tipo_pessoa,:documento,:nome,''ATIVA'')';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    if Length(Documento) = 11 then
      Qry.ParamByName('tipo_pessoa').AsString := 'FISICA'
    else
      Qry.ParamByName('tipo_pessoa').AsString := 'JURIDICA';

    if Documento.IsEmpty then
      Qry.ParamByName('documento').Clear
    else
      Qry.ParamByName('documento').AsString := Documento;

    Qry.ParamByName('nome').AsString := Trim(ANome);
    Qry.ExecSQL;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TContratoDAO.ExisteNumero(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ANumero: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM contrato WHERE id_instituicao=:id_instituicao AND numero=:numero ';
    if AIdIgnorar > 0 then
      Qry.SQL.Add('AND id<>:id_ignorar ');
    Qry.SQL.Add('LIMIT 1');

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('numero').AsString := Trim(ANumero);
    if AIdIgnorar > 0 then
      Qry.ParamByName('id_ignorar').AsLargeInt := AIdIgnorar;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TContratoDAO.MontarWhere(const AFiltro: TContratoFiltro): string;
begin
  Result := ' WHERE c.id_instituicao=:id_instituicao ';
  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      'AND (c.numero LIKE :busca OR c.titulo LIKE :busca OR e.nome LIKE :busca OR c.numero_processo LIKE :busca) ';
  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result + 'AND c.situacao=:situacao ';
end;

class procedure TContratoDAO.AplicarFiltro(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TContratoFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString := '%' + Trim(AFiltro.Busca) + '%';
  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));
end;

class function TContratoDAO.PreencherItem(const AQry: TUniQuery): TContratoItem;
begin
  Result := TContratoItem.Create;
  Result.Id := AQry.FieldByName('id').AsLargeInt;
  Result.CodigoPublico := AQry.FieldByName('codigo_publico').AsString;
  Result.IdEntidade := AQry.FieldByName('id_entidade').AsLargeInt;
  Result.DocumentoContratado := AQry.FieldByName('documento_contratado').AsString;
  Result.NomeContratado := AQry.FieldByName('nome_contratado').AsString;
  Result.Numero := AQry.FieldByName('numero').AsString;
  Result.NumeroExterno := AQry.FieldByName('numero_externo').AsString;
  Result.TipoGestao := AQry.FieldByName('tipo_gestao').AsString;
  Result.Tipo := AQry.FieldByName('tipo').AsString;
  Result.Titulo := AQry.FieldByName('titulo').AsString;
  Result.Objeto := AQry.FieldByName('objeto').AsString;
  Result.NumeroProcesso := AQry.FieldByName('numero_processo').AsString;
  if not AQry.FieldByName('ano_processo').IsNull then
    Result.AnoProcesso := AQry.FieldByName('ano_processo').AsInteger;
  Result.OrigemContratacao := AQry.FieldByName('origem_contratacao').AsString;
  Result.Modalidade := AQry.FieldByName('modalidade').AsString;
  Result.NumeroLicitacao := AQry.FieldByName('numero_licitacao').AsString;
  Result.IdentificadorPncp := AQry.FieldByName('identificador_pncp').AsString;
  Result.UrlPncp := AQry.FieldByName('url_pncp').AsString;
  if not AQry.FieldByName('data_assinatura').IsNull then
    Result.DataAssinatura := AQry.FieldByName('data_assinatura').AsDateTime;
  Result.DataInicio := AQry.FieldByName('data_inicio').AsDateTime;
  Result.DataFim := AQry.FieldByName('data_fim').AsDateTime;
  Result.ValorInicial := AQry.FieldByName('valor_inicial').AsFloat;
  Result.ValorAtual := AQry.FieldByName('valor_atual').AsFloat;
  Result.Periodicidade := AQry.FieldByName('periodicidade').AsString;
  Result.UnidadeResponsavel := AQry.FieldByName('unidade_responsavel').AsString;
  Result.Observacao := AQry.FieldByName('observacao').AsString;
  Result.Situacao := AQry.FieldByName('situacao').AsString;
end;

class function TContratoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TContratoFiltro
): TContratoLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TContratoLista.Create;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Result.Pagina := AFiltro.Pagina;
    Result.PorPagina := AFiltro.PorPagina;
    WhereSQL := MontarWhere(AFiltro);
    Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

    Qry.SQL.Text :=
      'SELECT COUNT(*) total FROM contrato c ' +
      'JOIN contrato_entidade e ON e.id_instituicao=c.id_instituicao AND e.id=c.id_entidade ' +
      WhereSQL;
    AplicarFiltro(Qry, AIdInstituicao, AFiltro);
    Qry.Open;
    Result.Total := Qry.FieldByName('total').AsInteger;
    Qry.Close;

    Qry.SQL.Text :=
      'SELECT c.*,e.documento documento_contratado,e.nome nome_contratado ' +
      'FROM contrato c ' +
      'JOIN contrato_entidade e ON e.id_instituicao=c.id_instituicao AND e.id=c.id_entidade ' +
      WhereSQL +
      'ORDER BY c.data_fim,c.id DESC LIMIT :limite OFFSET :offset';
    AplicarFiltro(Qry, AIdInstituicao, AFiltro);
    Qry.ParamByName('limite').AsInteger := AFiltro.PorPagina;
    Qry.ParamByName('offset').AsInteger := Offset;
    Qry.Open;
    while not Qry.Eof do
    begin
      Result.Itens.Add(PreencherItem(Qry));
      Qry.Next;
    end;
  except
    Result.Free;
    raise;
  finally
    Qry.Free;
  end;
end;

class function TContratoDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato: Int64
): TContratoItem;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT c.*,e.documento documento_contratado,e.nome nome_contratado ' +
      'FROM contrato c ' +
      'JOIN contrato_entidade e ON e.id_instituicao=c.id_instituicao AND e.id=c.id_entidade ' +
      'WHERE c.id_instituicao=:id_instituicao AND c.id=:id LIMIT 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdContrato;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := PreencherItem(Qry);
  finally
    Qry.Free;
  end;
end;

class function TContratoDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdUsuario, AIdEntidade: Int64;
  const ACodigoPublico: string;
  const ADados: TContratoCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO contrato(' +
      'id_instituicao,id_entidade,codigo_publico,numero,numero_externo,tipo_gestao,tipo,titulo,objeto,' +
      'numero_processo,ano_processo,origem_contratacao,modalidade,numero_licitacao,identificador_pncp,url_pncp,' +
      'data_assinatura,data_inicio,data_fim,valor_inicial,valor_atual,periodicidade,unidade_responsavel,observacao,situacao,criado_por) ' +
      'VALUES(' +
      ':id_instituicao,:id_entidade,:codigo_publico,:numero,:numero_externo,:tipo_gestao,:tipo,:titulo,:objeto,' +
      ':numero_processo,:ano_processo,:origem_contratacao,:modalidade,:numero_licitacao,:identificador_pncp,:url_pncp,' +
      ':data_assinatura,:data_inicio,:data_fim,:valor_inicial,:valor_atual,:periodicidade,:unidade_responsavel,:observacao,:situacao,:criado_por)';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_entidade').AsLargeInt := AIdEntidade;
    Qry.ParamByName('codigo_publico').AsString := ACodigoPublico;
    Qry.ParamByName('numero').AsString := Trim(ADados.Numero);
    if Trim(ADados.NumeroExterno).IsEmpty then Qry.ParamByName('numero_externo').Clear else Qry.ParamByName('numero_externo').AsString := Trim(ADados.NumeroExterno);
    Qry.ParamByName('tipo_gestao').AsString := ADados.TipoGestao;
    Qry.ParamByName('tipo').AsString := ADados.Tipo;
    Qry.ParamByName('titulo').AsString := Trim(ADados.Titulo);
    Qry.ParamByName('objeto').AsString := Trim(ADados.Objeto);
    if Trim(ADados.NumeroProcesso).IsEmpty then Qry.ParamByName('numero_processo').Clear else Qry.ParamByName('numero_processo').AsString := Trim(ADados.NumeroProcesso);
    if ADados.AnoProcesso > 0 then Qry.ParamByName('ano_processo').AsInteger := ADados.AnoProcesso else Qry.ParamByName('ano_processo').Clear;
    if Trim(ADados.OrigemContratacao).IsEmpty then Qry.ParamByName('origem_contratacao').Clear else Qry.ParamByName('origem_contratacao').AsString := ADados.OrigemContratacao;
    if Trim(ADados.Modalidade).IsEmpty then Qry.ParamByName('modalidade').Clear else Qry.ParamByName('modalidade').AsString := ADados.Modalidade;
    if Trim(ADados.NumeroLicitacao).IsEmpty then Qry.ParamByName('numero_licitacao').Clear else Qry.ParamByName('numero_licitacao').AsString := ADados.NumeroLicitacao;
    if Trim(ADados.IdentificadorPncp).IsEmpty then Qry.ParamByName('identificador_pncp').Clear else Qry.ParamByName('identificador_pncp').AsString := ADados.IdentificadorPncp;
    if Trim(ADados.UrlPncp).IsEmpty then Qry.ParamByName('url_pncp').Clear else Qry.ParamByName('url_pncp').AsString := ADados.UrlPncp;
    if ADados.DataAssinatura > 0 then Qry.ParamByName('data_assinatura').AsDateTime := ADados.DataAssinatura else Qry.ParamByName('data_assinatura').Clear;
    Qry.ParamByName('data_inicio').AsDateTime := ADados.DataInicio;
    Qry.ParamByName('data_fim').AsDateTime := ADados.DataFim;
    Qry.ParamByName('valor_inicial').AsFloat := ADados.ValorInicial;
    Qry.ParamByName('valor_atual').AsFloat := ADados.ValorAtual;
    if Trim(ADados.Periodicidade).IsEmpty then Qry.ParamByName('periodicidade').Clear else Qry.ParamByName('periodicidade').AsString := ADados.Periodicidade;
    if Trim(ADados.UnidadeResponsavel).IsEmpty then Qry.ParamByName('unidade_responsavel').Clear else Qry.ParamByName('unidade_responsavel').AsString := ADados.UnidadeResponsavel;
    if Trim(ADados.Observacao).IsEmpty then Qry.ParamByName('observacao').Clear else Qry.ParamByName('observacao').AsString := ADados.Observacao;
    Qry.ParamByName('situacao').AsString := ADados.Situacao;
    Qry.ParamByName('criado_por').AsLargeInt := AIdUsuario;
    Qry.ExecSQL;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TContratoDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdUsuario, AIdEntidade: Int64;
  const ADados: TContratoCadastro
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE contrato SET id_entidade=:id_entidade,numero=:numero,numero_externo=:numero_externo,' +
      'tipo_gestao=:tipo_gestao,tipo=:tipo,titulo=:titulo,objeto=:objeto,numero_processo=:numero_processo,' +
      'ano_processo=:ano_processo,origem_contratacao=:origem_contratacao,modalidade=:modalidade,' +
      'numero_licitacao=:numero_licitacao,identificador_pncp=:identificador_pncp,url_pncp=:url_pncp,' +
      'data_assinatura=:data_assinatura,data_inicio=:data_inicio,data_fim=:data_fim,' +
      'valor_inicial=:valor_inicial,valor_atual=:valor_atual,periodicidade=:periodicidade,' +
      'unidade_responsavel=:unidade_responsavel,observacao=:observacao,situacao=:situacao,atualizado_por=:atualizado_por ' +
      'WHERE id_instituicao=:id_instituicao AND id=:id';

    Qry.ParamByName('id_entidade').AsLargeInt := AIdEntidade;
    Qry.ParamByName('numero').AsString := Trim(ADados.Numero);
    if Trim(ADados.NumeroExterno).IsEmpty then Qry.ParamByName('numero_externo').Clear else Qry.ParamByName('numero_externo').AsString := Trim(ADados.NumeroExterno);
    Qry.ParamByName('tipo_gestao').AsString := ADados.TipoGestao;
    Qry.ParamByName('tipo').AsString := ADados.Tipo;
    Qry.ParamByName('titulo').AsString := Trim(ADados.Titulo);
    Qry.ParamByName('objeto').AsString := Trim(ADados.Objeto);
    if Trim(ADados.NumeroProcesso).IsEmpty then Qry.ParamByName('numero_processo').Clear else Qry.ParamByName('numero_processo').AsString := Trim(ADados.NumeroProcesso);
    if ADados.AnoProcesso > 0 then Qry.ParamByName('ano_processo').AsInteger := ADados.AnoProcesso else Qry.ParamByName('ano_processo').Clear;
    if Trim(ADados.OrigemContratacao).IsEmpty then Qry.ParamByName('origem_contratacao').Clear else Qry.ParamByName('origem_contratacao').AsString := ADados.OrigemContratacao;
    if Trim(ADados.Modalidade).IsEmpty then Qry.ParamByName('modalidade').Clear else Qry.ParamByName('modalidade').AsString := ADados.Modalidade;
    if Trim(ADados.NumeroLicitacao).IsEmpty then Qry.ParamByName('numero_licitacao').Clear else Qry.ParamByName('numero_licitacao').AsString := ADados.NumeroLicitacao;
    if Trim(ADados.IdentificadorPncp).IsEmpty then Qry.ParamByName('identificador_pncp').Clear else Qry.ParamByName('identificador_pncp').AsString := ADados.IdentificadorPncp;
    if Trim(ADados.UrlPncp).IsEmpty then Qry.ParamByName('url_pncp').Clear else Qry.ParamByName('url_pncp').AsString := ADados.UrlPncp;
    if ADados.DataAssinatura > 0 then Qry.ParamByName('data_assinatura').AsDateTime := ADados.DataAssinatura else Qry.ParamByName('data_assinatura').Clear;
    Qry.ParamByName('data_inicio').AsDateTime := ADados.DataInicio;
    Qry.ParamByName('data_fim').AsDateTime := ADados.DataFim;
    Qry.ParamByName('valor_inicial').AsFloat := ADados.ValorInicial;
    Qry.ParamByName('valor_atual').AsFloat := ADados.ValorAtual;
    if Trim(ADados.Periodicidade).IsEmpty then Qry.ParamByName('periodicidade').Clear else Qry.ParamByName('periodicidade').AsString := ADados.Periodicidade;
    if Trim(ADados.UnidadeResponsavel).IsEmpty then Qry.ParamByName('unidade_responsavel').Clear else Qry.ParamByName('unidade_responsavel').AsString := ADados.UnidadeResponsavel;
    if Trim(ADados.Observacao).IsEmpty then Qry.ParamByName('observacao').Clear else Qry.ParamByName('observacao').AsString := ADados.Observacao;
    Qry.ParamByName('situacao').AsString := ADados.Situacao;
    Qry.ParamByName('atualizado_por').AsLargeInt := AIdUsuario;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdContrato;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;


class procedure TContratoDAO.AlterarSituacaoFinal(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
  const ASituacao, AMotivo: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    if SameText(ASituacao,'ENCERRADO') then
      Qry.SQL.Text :=
        'UPDATE contrato SET situacao=''ENCERRADO'',encerrado_em=CURRENT_TIMESTAMP(3),' +
        'motivo_encerramento=:motivo,atualizado_por=:usuario ' +
        'WHERE id_instituicao=:id_instituicao AND id=:id ' +
        'AND situacao NOT IN (''ENCERRADO'',''CANCELADO'')'
    else
      Qry.SQL.Text :=
        'UPDATE contrato SET situacao=''CANCELADO'',cancelado_em=CURRENT_TIMESTAMP(3),' +
        'motivo_cancelamento=:motivo,atualizado_por=:usuario ' +
        'WHERE id_instituicao=:id_instituicao AND id=:id ' +
        'AND situacao NOT IN (''ENCERRADO'',''CANCELADO'')';

    Qry.ParamByName('motivo').AsString := Copy(Trim(AMotivo),1,1000);
    Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdContrato;
    Qry.ExecSQL;

    if Qry.RowsAffected=0 then
      raise Exception.Create('Contrato não encontrado ou já finalizado.');
  finally
    Qry.Free;
  end;
end;

class procedure TContratoDAO.InserirHistorico(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
  const AEvento, ADescricao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO contrato_historico(id_instituicao,id_contrato,evento,descricao,usuario) ' +
      'VALUES(:id_instituicao,:id_contrato,:evento,:descricao,:usuario)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ParamByName('evento').AsString := AEvento;
    Qry.ParamByName('descricao').AsString := Copy(ADescricao,1,1000);
    if AIdUsuario > 0 then Qry.ParamByName('usuario').AsLargeInt := AIdUsuario else Qry.ParamByName('usuario').Clear;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
