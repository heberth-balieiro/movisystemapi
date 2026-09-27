unit InstituicaoInstrutor.DAO;

interface

uses
  Uni,
  InstituicaoInstrutor.Model;

type
  TInstituicaoInstrutorDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoInstrutorFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoInstrutorFiltro
    ); static;

    class function MapearItem(
      const AQry: TUniQuery
    ): TInstituicaoInstrutorItem; static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoInstrutorFiltro
    ): TInstituicaoInstrutorLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInstrutor: Int64
    ): TInstituicaoInstrutorItem; static;

    class function ExisteCodigoPublico(
      const AConn: TUniConnection;
      const ACodigoPublico: string
    ): Boolean; static;

    class function ExisteParticipanteAtivo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64
    ): Boolean; static;

    class function ParticipanteJaVinculado(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACodigoPublico: string;
      const ADados: TInstituicaoInstrutorCadastro
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInstrutor: Int64;
      const ADados: TInstituicaoInstrutorAlteracao
    ); static;

    class procedure AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInstrutor: Int64;
      const ASituacao: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoInstrutorDAO.MontarWhere(
  const AFiltro: TInstituicaoInstrutorFiltro
): string;
begin
  Result :=
    ' WHERE i.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    Result :=
      Result +
      ' AND (' +
      'i.nome LIKE :busca OR ' +
      'i.email LIKE :busca OR ' +
      'i.telefone LIKE :busca' +
      ') ';
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result :=
      Result +
      ' AND i.situacao = :situacao ';
end;

class procedure TInstituicaoInstrutorDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoInstrutorFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt :=
    AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString :=
      UpperCase(Trim(AFiltro.Situacao));
end;

class function TInstituicaoInstrutorDAO.MapearItem(
  const AQry: TUniQuery
): TInstituicaoInstrutorItem;
begin
  Result := TInstituicaoInstrutorItem.Create;

  Result.Id :=
    AQry.FieldByName('id').AsLargeInt;

  Result.TemParticipante :=
    not AQry.FieldByName('id_participante').IsNull;

  if Result.TemParticipante then
    Result.IdParticipante :=
      AQry.FieldByName('id_participante').AsLargeInt;

  Result.ParticipanteNome :=
    AQry.FieldByName('participante_nome').AsString;

  Result.CodigoPublico :=
    AQry.FieldByName('codigo_publico').AsString;

  Result.Nome :=
    AQry.FieldByName('nome').AsString;

  Result.Email :=
    AQry.FieldByName('email').AsString;

  Result.Telefone :=
    AQry.FieldByName('telefone').AsString;

  Result.Biografia :=
    AQry.FieldByName('biografia').AsString;

  Result.Situacao :=
    AQry.FieldByName('situacao').AsString;

  Result.CriadoEm :=
    AQry.FieldByName('criado_em').AsDateTime;

  Result.AtualizadoEm :=
    AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoInstrutorDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoInstrutorFiltro
): TInstituicaoInstrutorLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TInstituicaoInstrutorLista.Create;

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;

      WhereSQL := MontarWhere(AFiltro);
      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM instrutor i ' +
        WhereSQL;

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.Open;

      Result.Total :=
        Qry.FieldByName('total').AsInteger;

      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'i.id, ' +
        'i.id_participante, ' +
        'p.nome AS participante_nome, ' +
        'i.codigo_publico, ' +
        'i.nome, ' +
        'i.email, ' +
        'i.telefone, ' +
        'i.biografia, ' +
        'i.situacao, ' +
        'i.criado_em, ' +
        'i.atualizado_em ' +
        'FROM instrutor i ' +
        'LEFT JOIN participante p ' +
        '  ON p.id_instituicao = i.id_instituicao ' +
        ' AND p.id = i.id_participante ' +
        WhereSQL +
        'ORDER BY i.nome, i.id ' +
        'LIMIT :limite OFFSET :offset';

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.ParamByName('limite').AsInteger :=
        AFiltro.PorPagina;

      Qry.ParamByName('offset').AsInteger :=
        Offset;

      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Itens.Add(
          MapearItem(Qry)
        );

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

class function TInstituicaoInstrutorDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInstrutor: Int64
): TInstituicaoInstrutorItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'i.id, ' +
      'i.id_participante, ' +
      'p.nome AS participante_nome, ' +
      'i.codigo_publico, ' +
      'i.nome, ' +
      'i.email, ' +
      'i.telefone, ' +
      'i.biografia, ' +
      'i.situacao, ' +
      'i.criado_em, ' +
      'i.atualizado_em ' +
      'FROM instrutor i ' +
      'LEFT JOIN participante p ' +
      '  ON p.id_instituicao = i.id_instituicao ' +
      ' AND p.id = i.id_participante ' +
      'WHERE i.id_instituicao = :id_instituicao ' +
      'AND i.id = :id ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdInstrutor;

    Qry.Open;

    if not Qry.IsEmpty then
      Result := MapearItem(Qry);

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInstrutorDAO.ExisteCodigoPublico(
  const AConn: TUniConnection;
  const ACodigoPublico: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM instrutor ' +
      'WHERE codigo_publico = :codigo_publico ' +
      'LIMIT 1';

    Qry.ParamByName('codigo_publico').AsString :=
      ACodigoPublico;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInstrutorDAO.ExisteParticipanteAtivo(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     (AIdParticipante <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id_participante ' +
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_participante').AsLargeInt :=
      AIdParticipante;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInstrutorDAO.ParticipanteJaVinculado(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if AIdParticipante <= 0 then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM instrutor ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_participante = :id_participante ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add(
        'AND id <> :id_ignorar '
      );

    Qry.SQL.Add(
      'LIMIT 1'
    );

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_participante').AsLargeInt :=
      AIdParticipante;

    if AIdIgnorar > 0 then
      Qry.ParamByName('id_ignorar').AsLargeInt :=
        AIdIgnorar;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInstrutorDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACodigoPublico: string;
  const ADados: TInstituicaoInstrutorCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO instrutor (' +
      'id_instituicao, ' +
      'id_participante, ' +
      'codigo_publico, ' +
      'nome, ' +
      'email, ' +
      'telefone, ' +
      'biografia, ' +
      'situacao' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_participante, ' +
      ':codigo_publico, ' +
      ':nome, ' +
      ':email, ' +
      ':telefone, ' +
      ':biografia, ' +
      '''ATIVO''' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    if ADados.IdParticipante > 0 then
      Qry.ParamByName('id_participante').AsLargeInt :=
        ADados.IdParticipante
    else
      Qry.ParamByName('id_participante').Clear;

    Qry.ParamByName('codigo_publico').AsString :=
      ACodigoPublico;

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    if not ADados.Email.IsEmpty then
      Qry.ParamByName('email').AsString :=
        ADados.Email
    else
      Qry.ParamByName('email').Clear;

    if not ADados.Telefone.IsEmpty then
      Qry.ParamByName('telefone').AsString :=
        ADados.Telefone
    else
      Qry.ParamByName('telefone').Clear;

    if not ADados.Biografia.IsEmpty then
      Qry.ParamByName('biografia').AsString :=
        ADados.Biografia
    else
      Qry.ParamByName('biografia').Clear;

    Qry.ExecSQL;

    Qry.SQL.Text :=
      'SELECT LAST_INSERT_ID() AS id';

    Qry.Open;

    Result :=
      Qry.FieldByName('id').AsLargeInt;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoInstrutorDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInstrutor: Int64;
  const ADados: TInstituicaoInstrutorAlteracao
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE instrutor SET ' +
      'id_participante = :id_participante, ' +
      'nome = :nome, ' +
      'email = :email, ' +
      'telefone = :telefone, ' +
      'biografia = :biografia ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    if ADados.IdParticipante > 0 then
      Qry.ParamByName('id_participante').AsLargeInt :=
        ADados.IdParticipante
    else
      Qry.ParamByName('id_participante').Clear;

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    if not ADados.Email.IsEmpty then
      Qry.ParamByName('email').AsString :=
        ADados.Email
    else
      Qry.ParamByName('email').Clear;

    if not ADados.Telefone.IsEmpty then
      Qry.ParamByName('telefone').AsString :=
        ADados.Telefone
    else
      Qry.ParamByName('telefone').Clear;

    if not ADados.Biografia.IsEmpty then
      Qry.ParamByName('biografia').AsString :=
        ADados.Biografia
    else
      Qry.ParamByName('biografia').Clear;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdInstrutor;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoInstrutorDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInstrutor: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE instrutor SET ' +
      'situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName('situacao').AsString :=
      ASituacao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdInstrutor;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

end.
