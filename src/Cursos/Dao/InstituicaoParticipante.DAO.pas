unit InstituicaoParticipante.DAO;

interface

uses
  Uni,
  InstituicaoParticipante.Model;

type
  TInstituicaoParticipanteDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoParticipanteFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoParticipanteFiltro
    ); static;

    class function MapearItem(
      const AQry: TUniQuery
    ): TInstituicaoParticipanteItem; static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoParticipanteFiltro
    ): TInstituicaoParticipanteLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64
    ): TInstituicaoParticipanteItem; static;

    class function ExisteCodigoPublico(
      const AConn: TUniConnection;
      const ACodigoPublico: string
    ): Boolean; static;

    class function ExisteCpfHash(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACpfHashBusca: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function ExisteMatricula(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AMatricula: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function UnidadeAtivaExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUnidadeOrganizacional: Int64
    ): Boolean; static;

    class function UsuarioInstituicaoAtivoExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): Boolean; static;

    class function UsuarioJaVinculado(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao,
            ACriadoPor: Int64;
      const ACodigoPublico,
            ACpfHashBusca,
            ACpfMascarado: string;
      const ADados: TInstituicaoParticipanteCadastro
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64;
      const AAlterarCpf: Boolean;
      const ACpfHashBusca,
            ACpfMascarado: string;
      const ADados: TInstituicaoParticipanteAlteracao
    ); static;

    class procedure AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64;
      const ASituacao: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoParticipanteDAO.MontarWhere(
  const AFiltro: TInstituicaoParticipanteFiltro
): string;
begin
  Result :=
    ' WHERE p.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    Result :=
      Result +
      ' AND (' +
      'p.nome LIKE :busca ' +
      'OR p.email LIKE :busca ' +
      'OR p.matricula LIKE :busca ' +
      'OR p.telefone LIKE :busca ' +
      'OR p.orgao_empresa LIKE :busca ' +
      'OR p.cargo LIKE :busca ';

    if not Trim(AFiltro.CpfHashBusca).IsEmpty then
      Result :=
        Result +
        'OR p.cpf_hash_busca = :cpf_hash_busca ';

    Result :=
      Result +
      ') ';
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result :=
      Result +
      ' AND p.situacao = :situacao ';
end;

class procedure TInstituicaoParticipanteDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoParticipanteFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt :=
    AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

    if not Trim(AFiltro.CpfHashBusca).IsEmpty then
      AQry.ParamByName('cpf_hash_busca').AsString :=
        AFiltro.CpfHashBusca;
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString :=
      UpperCase(
        Trim(AFiltro.Situacao)
      );
end;

class function TInstituicaoParticipanteDAO.MapearItem(
  const AQry: TUniQuery
): TInstituicaoParticipanteItem;
begin
  Result :=
    TInstituicaoParticipanteItem.Create;

  Result.Id :=
    AQry.FieldByName('id').AsLargeInt;

  Result.TemUnidadeOrganizacional :=
    not AQry.FieldByName(
      'id_unidade_organizacional'
    ).IsNull;

  if Result.TemUnidadeOrganizacional then
    Result.IdUnidadeOrganizacional :=
      AQry.FieldByName(
        'id_unidade_organizacional'
      ).AsLargeInt;

  Result.UnidadeOrganizacionalNome :=
    AQry.FieldByName(
      'unidade_organizacional_nome'
    ).AsString;

  Result.TemUsuarioInstituicao :=
    not AQry.FieldByName(
      'id_usuario_instituicao'
    ).IsNull;

  if Result.TemUsuarioInstituicao then
    Result.IdUsuarioInstituicao :=
      AQry.FieldByName(
        'id_usuario_instituicao'
      ).AsLargeInt;

  Result.UsuarioNome :=
    AQry.FieldByName(
      'usuario_nome'
    ).AsString;

  Result.UsuarioEmail :=
    AQry.FieldByName(
      'usuario_email'
    ).AsString;

  Result.CodigoPublico :=
    AQry.FieldByName(
      'codigo_publico'
    ).AsString;

  Result.Nome :=
    AQry.FieldByName(
      'nome'
    ).AsString;

  Result.CpfMascarado :=
    AQry.FieldByName(
      'cpf_mascarado'
    ).AsString;

  Result.Email :=
    AQry.FieldByName(
      'email'
    ).AsString;

  Result.Matricula :=
    AQry.FieldByName(
      'matricula'
    ).AsString;

  Result.Telefone :=
    AQry.FieldByName(
      'telefone'
    ).AsString;

  Result.OrgaoEmpresa :=
    AQry.FieldByName(
      'orgao_empresa'
    ).AsString;

  Result.Cargo :=
    AQry.FieldByName(
      'cargo'
    ).AsString;

  Result.Situacao :=
    AQry.FieldByName(
      'situacao'
    ).AsString;

  Result.TemAnonimizadoEm :=
    not AQry.FieldByName(
      'anonimizado_em'
    ).IsNull;

  if Result.TemAnonimizadoEm then
    Result.AnonimizadoEm :=
      AQry.FieldByName(
        'anonimizado_em'
      ).AsDateTime;

  Result.MotivoAnonimizacao :=
    AQry.FieldByName(
      'motivo_anonimizacao'
    ).AsString;

  Result.CriadoEm :=
    AQry.FieldByName(
      'criado_em'
    ).AsDateTime;

  Result.AtualizadoEm :=
    AQry.FieldByName(
      'atualizado_em'
    ).AsDateTime;
end;

class function TInstituicaoParticipanteDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoParticipanteFiltro
): TInstituicaoParticipanteLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result :=
    TInstituicaoParticipanteLista.Create;

  Qry :=
    TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Result.Pagina :=
        AFiltro.Pagina;

      Result.PorPagina :=
        AFiltro.PorPagina;

      WhereSQL :=
        MontarWhere(
          AFiltro
        );

      Offset :=
        (AFiltro.Pagina - 1) *
        AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM participante p ' +
        WhereSQL;

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.Open;

      Result.Total :=
        Qry.FieldByName(
          'total'
        ).AsInteger;

      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'p.id, ' +
        'p.id_unidade_organizacional, ' +
        'uo.nome AS unidade_organizacional_nome, ' +
        'p.id_usuario_instituicao, ' +
        'u.nome AS usuario_nome, ' +
        'u.email AS usuario_email, ' +
        'p.codigo_publico, ' +
        'p.nome, ' +
        'p.cpf_mascarado, ' +
        'p.email, ' +
        'p.matricula, ' +
        'p.telefone, ' +
        'p.orgao_empresa, ' +
        'p.cargo, ' +
        'p.situacao, ' +
        'p.anonimizado_em, ' +
        'p.motivo_anonimizacao, ' +
        'p.criado_em, ' +
        'p.atualizado_em ' +
        'FROM participante p ' +
        'LEFT JOIN unidade_organizacional uo ' +
        '  ON uo.id_instituicao = p.id_instituicao ' +
        ' AND uo.id = p.id_unidade_organizacional ' +
        'LEFT JOIN usuario_instituicao ui ' +
        '  ON ui.id_instituicao = p.id_instituicao ' +
        ' AND ui.id = p.id_usuario_instituicao ' +
        'LEFT JOIN usuario u ' +
        '  ON u.id = ui.id_usuario ' +
        WhereSQL +
        'ORDER BY p.nome, p.id ' +
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

class function TInstituicaoParticipanteDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64
): TInstituicaoParticipanteItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'p.id, ' +
      'p.id_unidade_organizacional, ' +
      'uo.nome AS unidade_organizacional_nome, ' +
      'p.id_usuario_instituicao, ' +
      'u.nome AS usuario_nome, ' +
      'u.email AS usuario_email, ' +
      'p.codigo_publico, ' +
      'p.nome, ' +
      'p.cpf_mascarado, ' +
      'p.email, ' +
      'p.matricula, ' +
      'p.telefone, ' +
      'p.orgao_empresa, ' +
      'p.cargo, ' +
      'p.situacao, ' +
      'p.anonimizado_em, ' +
      'p.motivo_anonimizacao, ' +
      'p.criado_em, ' +
      'p.atualizado_em ' +
      'FROM participante p ' +
      'LEFT JOIN unidade_organizacional uo ' +
      '  ON uo.id_instituicao = p.id_instituicao ' +
      ' AND uo.id = p.id_unidade_organizacional ' +
      'LEFT JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = p.id_instituicao ' +
      ' AND ui.id = p.id_usuario_instituicao ' +
      'LEFT JOIN usuario u ' +
      '  ON u.id = ui.id_usuario ' +
      'WHERE p.id_instituicao = :id_instituicao ' +
      'AND p.id = :id ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id'
    ).AsLargeInt :=
      AIdParticipante;

    Qry.Open;

    if not Qry.IsEmpty then
      Result :=
        MapearItem(Qry);

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteDAO.ExisteCodigoPublico(
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
      'FROM participante ' +
      'WHERE codigo_publico = :codigo_publico ' +
      'LIMIT 1';

    Qry.ParamByName(
      'codigo_publico'
    ).AsString :=
      ACodigoPublico;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteDAO.ExisteCpfHash(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACpfHashBusca: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if Trim(ACpfHashBusca).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND cpf_hash_busca = :cpf_hash_busca ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add(
        'AND id <> :id_ignorar '
      );

    Qry.SQL.Add(
      'LIMIT 1'
    );

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'cpf_hash_busca'
    ).AsString :=
      ACpfHashBusca;

    if AIdIgnorar > 0 then
      Qry.ParamByName(
        'id_ignorar'
      ).AsLargeInt :=
        AIdIgnorar;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteDAO.ExisteMatricula(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AMatricula: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if Trim(AMatricula).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND matricula = :matricula ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add(
        'AND id <> :id_ignorar '
      );

    Qry.SQL.Add(
      'LIMIT 1'
    );

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'matricula'
    ).AsString :=
      Trim(AMatricula);

    if AIdIgnorar > 0 then
      Qry.ParamByName(
        'id_ignorar'
      ).AsLargeInt :=
        AIdIgnorar;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteDAO.UnidadeAtivaExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUnidadeOrganizacional: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if AIdUnidadeOrganizacional <= 0 then
    Exit;

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM unidade_organizacional ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id ' +
      'AND situacao = ''ATIVA'' ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id'
    ).AsLargeInt :=
      AIdUnidadeOrganizacional;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteDAO.UsuarioInstituicaoAtivoExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if AIdUsuarioInstituicao <= 0 then
    Exit;

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM usuario_instituicao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id ' +
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id'
    ).AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteDAO.UsuarioJaVinculado(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if AIdUsuarioInstituicao <= 0 then
    Exit;

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_usuario_instituicao = :id_usuario_instituicao ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add(
        'AND id <> :id_ignorar '
      );

    Qry.SQL.Add(
      'LIMIT 1'
    );

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_usuario_instituicao'
    ).AsLargeInt :=
      AIdUsuarioInstituicao;

    if AIdIgnorar > 0 then
      Qry.ParamByName(
        'id_ignorar'
      ).AsLargeInt :=
        AIdIgnorar;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao,
        ACriadoPor: Int64;
  const ACodigoPublico,
        ACpfHashBusca,
        ACpfMascarado: string;
  const ADados: TInstituicaoParticipanteCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO participante (' +
      'id_instituicao, ' +
      'id_unidade_organizacional, ' +
      'id_usuario_instituicao, ' +
      'codigo_publico, ' +
      'nome, ' +
      'cpf_criptografado, ' +
      'cpf_hash_busca, ' +
      'cpf_mascarado, ' +
      'email, ' +
      'matricula, ' +
      'telefone, ' +
      'orgao_empresa, ' +
      'cargo, ' +
      'situacao, ' +
      'criado_por' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_unidade_organizacional, ' +
      ':id_usuario_instituicao, ' +
      ':codigo_publico, ' +
      ':nome, ' +
      'NULL, ' +
      ':cpf_hash_busca, ' +
      ':cpf_mascarado, ' +
      ':email, ' +
      ':matricula, ' +
      ':telefone, ' +
      ':orgao_empresa, ' +
      ':cargo, ' +
      '''ATIVO'', ' +
      ':criado_por' +
      ')';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    if ADados.IdUnidadeOrganizacional > 0 then
      Qry.ParamByName(
        'id_unidade_organizacional'
      ).AsLargeInt :=
        ADados.IdUnidadeOrganizacional
    else
      Qry.ParamByName(
        'id_unidade_organizacional'
      ).Clear;

    if ADados.IdUsuarioInstituicao > 0 then
      Qry.ParamByName(
        'id_usuario_instituicao'
      ).AsLargeInt :=
        ADados.IdUsuarioInstituicao
    else
      Qry.ParamByName(
        'id_usuario_instituicao'
      ).Clear;

    Qry.ParamByName(
      'codigo_publico'
    ).AsString :=
      ACodigoPublico;

    Qry.ParamByName(
      'nome'
    ).AsString :=
      ADados.Nome;

    if Trim(ACpfHashBusca).IsEmpty then
      Qry.ParamByName(
        'cpf_hash_busca'
      ).Clear
    else
      Qry.ParamByName(
        'cpf_hash_busca'
      ).AsString :=
        ACpfHashBusca;

    if Trim(ACpfMascarado).IsEmpty then
      Qry.ParamByName(
        'cpf_mascarado'
      ).Clear
    else
      Qry.ParamByName(
        'cpf_mascarado'
      ).AsString :=
        ACpfMascarado;

    if ADados.Email.IsEmpty then
      Qry.ParamByName('email').Clear
    else
      Qry.ParamByName('email').AsString :=
        ADados.Email;

    if ADados.Matricula.IsEmpty then
      Qry.ParamByName('matricula').Clear
    else
      Qry.ParamByName('matricula').AsString :=
        ADados.Matricula;

    if ADados.Telefone.IsEmpty then
      Qry.ParamByName('telefone').Clear
    else
      Qry.ParamByName('telefone').AsString :=
        ADados.Telefone;

    if ADados.OrgaoEmpresa.IsEmpty then
      Qry.ParamByName('orgao_empresa').Clear
    else
      Qry.ParamByName('orgao_empresa').AsString :=
        ADados.OrgaoEmpresa;

    if ADados.Cargo.IsEmpty then
      Qry.ParamByName('cargo').Clear
    else
      Qry.ParamByName('cargo').AsString :=
        ADados.Cargo;

    Qry.ParamByName(
      'criado_por'
    ).AsLargeInt :=
      ACriadoPor;

    Qry.ExecSQL;

    Qry.SQL.Text :=
      'SELECT LAST_INSERT_ID() AS id';

    Qry.Open;

    Result :=
      Qry.FieldByName(
        'id'
      ).AsLargeInt;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoParticipanteDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64;
  const AAlterarCpf: Boolean;
  const ACpfHashBusca,
        ACpfMascarado: string;
  const ADados: TInstituicaoParticipanteAlteracao
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE participante SET ' +
      'id_unidade_organizacional = :id_unidade_organizacional, ' +
      'id_usuario_instituicao = :id_usuario_instituicao, ' +
      'nome = :nome, ' +
      'email = :email, ' +
      'matricula = :matricula, ' +
      'telefone = :telefone, ' +
      'orgao_empresa = :orgao_empresa, ' +
      'cargo = :cargo ';

    if AAlterarCpf then
      Qry.SQL.Add(
        ', cpf_criptografado = NULL ' +
        ', cpf_hash_busca = :cpf_hash_busca ' +
        ', cpf_mascarado = :cpf_mascarado '
      );

    Qry.SQL.Add(
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id'
    );

    if ADados.IdUnidadeOrganizacional > 0 then
      Qry.ParamByName(
        'id_unidade_organizacional'
      ).AsLargeInt :=
        ADados.IdUnidadeOrganizacional
    else
      Qry.ParamByName(
        'id_unidade_organizacional'
      ).Clear;

    if ADados.IdUsuarioInstituicao > 0 then
      Qry.ParamByName(
        'id_usuario_instituicao'
      ).AsLargeInt :=
        ADados.IdUsuarioInstituicao
    else
      Qry.ParamByName(
        'id_usuario_instituicao'
      ).Clear;

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    if ADados.Email.IsEmpty then
      Qry.ParamByName('email').Clear
    else
      Qry.ParamByName('email').AsString :=
        ADados.Email;

    if ADados.Matricula.IsEmpty then
      Qry.ParamByName('matricula').Clear
    else
      Qry.ParamByName('matricula').AsString :=
        ADados.Matricula;

    if ADados.Telefone.IsEmpty then
      Qry.ParamByName('telefone').Clear
    else
      Qry.ParamByName('telefone').AsString :=
        ADados.Telefone;

    if ADados.OrgaoEmpresa.IsEmpty then
      Qry.ParamByName('orgao_empresa').Clear
    else
      Qry.ParamByName('orgao_empresa').AsString :=
        ADados.OrgaoEmpresa;

    if ADados.Cargo.IsEmpty then
      Qry.ParamByName('cargo').Clear
    else
      Qry.ParamByName('cargo').AsString :=
        ADados.Cargo;

    if AAlterarCpf then
    begin
      Qry.ParamByName(
        'cpf_hash_busca'
      ).AsString :=
        ACpfHashBusca;

      Qry.ParamByName(
        'cpf_mascarado'
      ).AsString :=
        ACpfMascarado;
    end;

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id'
    ).AsLargeInt :=
      AIdParticipante;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoParticipanteDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE participante SET ' +
      'situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName(
      'situacao'
    ).AsString :=
      ASituacao;

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id'
    ).AsLargeInt :=
      AIdParticipante;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

end.
