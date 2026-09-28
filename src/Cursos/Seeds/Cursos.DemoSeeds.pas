unit Cursos.DemoSeeds;

interface

type
  TCursosDemoSeeds = class
  private
    class function BuscarInstituicaoId(
      const AConn: TObject;
      const ASlug: string
    ): Int64; static;
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles,
  System.DateUtils,
  Uni,
  App.Config,
  Database.Connection;

type
  TDemoSeed = class
  private
    FConn: TUniConnection;
    FIdInstituicao: Int64;

    function BuscarId(
      const ASQL,
            AChave: string
    ): Int64;

    function GarantirCategoria(
      const ANome,
            ADescricao: string
    ): Int64;

    function GarantirModeloCertificado: Int64;

    function GarantirCurso(
      const AIdCategoria: Int64;
      const ACodigoPublico,
            ACodigoInterno,
            ASlug,
            ANome,
            ADescricao,
            AObjetivo,
            AModalidade: string;
      const ACargaHorariaMinutos: Integer;
      const AInscricaoPublica: Boolean
    ): Int64;

    function GarantirInstrutor(
      const ACodigoPublico,
            ANome,
            AEmail,
            ATelefone,
            ABiografia: string
    ): Int64;

    procedure VincularInstrutorCurso(
      const AIdCurso,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    );

    function GarantirTurma(
      const AIdCurso,
            AIdModelo: Int64;
      const ACodigoPublico,
            ACodigoInterno,
            ANome,
            AModalidade,
            ALocal,
            ASituacao: string;
      const AInicio,
            AFim,
            AInscricaoInicio,
            AInscricaoFim: TDateTime;
      const ALimite: Integer;
      const AInscricaoPublica: Boolean
    ): Int64;

    procedure VincularInstrutorTurma(
      const AIdTurma,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    );

    function GarantirEncontro(
      const AIdTurma: Int64;
      const ATitulo,
            ADescricao,
            ALocal,
            ASituacao: string;
      const AInicio,
            AFim: TDateTime;
      const ACargaHorariaMinutos: Integer
    ): Int64;

    procedure GarantirCriterioPresenca(
      const AIdTurma: Int64;
      const APercentualMinimo: Integer
    );

    function GarantirParticipante(
      const ACodigoPublico,
            ANome,
            AEmail,
            AMatricula,
            ATelefone,
            AOrgao,
            ACargo: string
    ): Int64;

    function GarantirInscricao(
      const AIdTurma,
            AIdParticipante: Int64;
      const ACodigoPublico,
            AOrigem,
            ASituacao: string;
      const APercentualPresenca,
            APercentualProgresso: Double;
      const AConcluida: Boolean
    ): Int64;

    procedure GarantirPresenca(
      const AIdTurma,
            AIdEncontro,
            AIdInscricao: Int64;
      const ASituacao: string;
      const ACheckin,
            ACheckout: TDateTime;
      const AMinutos: Integer
    );

  public
    constructor Create(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    );

    procedure Executar;
  end;

{ TCursosDemoSeeds }

class function TCursosDemoSeeds.BuscarInstituicaoId(
  const AConn: TObject;
  const ASlug: string
): Int64;
var
  Conn: TUniConnection;
  Qry: TUniQuery;
begin
  Result := 0;
  Conn := TUniConnection(AConn);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := Conn;
    Qry.SQL.Text :=
      'SELECT id ' +
      'FROM instituicao ' +
      'WHERE slug = :slug ' +
      '  AND situacao = ''ATIVA'' ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString := LowerCase(Trim(ASlug));
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TCursosDemoSeeds.Run;
var
  Ini: TIniFile;
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Seed: TDemoSeed;
  Executar: Boolean;
  Slug: string;
  IdInstituicao: Int64;
begin
  Ini := TIniFile.Create(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );
  try
    Executar :=
      Ini.ReadBool(
        'CERTIFICA_DEMO',
        'Executar',
        False
      );

    if not Executar then
      Exit;

    Slug :=
      LowerCase(
        Trim(
          Ini.ReadString(
            'CERTIFICA_DEMO',
            'SlugInstituicao',
            'horizonte-treinamentos'
          )
        )
      );
  finally
    Ini.Free;
  end;

  if Slug.IsEmpty then
    raise Exception.Create(
      'CERTIFICA_DEMO.SlugInstituicao nao configurado.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    IdInstituicao :=
      BuscarInstituicaoId(
        Conn,
        Slug
      );

    if IdInstituicao <= 0 then
    begin
      Writeln(
        'Seed demo ignorado: instituicao "' +
        Slug +
        '" nao encontrada ou inativa.'
      );
      Exit;
    end;

    Seed :=
      TDemoSeed.Create(
        Conn,
        IdInstituicao
      );
    try
      Conn.StartTransaction;
      try
        Seed.Executar;
        Conn.Commit;
      except
        if Conn.InTransaction then
          Conn.Rollback;
        raise;
      end;
    finally
      Seed.Free;
    end;

    Writeln(
      'Seed demo Certifica executado para a instituicao "' +
      Slug +
      '".'
    );
  finally
    Conn.Free;
  end;
end;

{ TDemoSeed }

constructor TDemoSeed.Create(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
);
begin
  inherited Create;
  FConn := AConn;
  FIdInstituicao := AIdInstituicao;
end;

function TDemoSeed.BuscarId(
  const ASQL,
        AChave: string
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := ASQL;
    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('chave').AsString := AChave;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

function TDemoSeed.GarantirCategoria(
  const ANome,
        ADescricao: string
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO curso_categoria ' +
      '(id_instituicao, nome, descricao, situacao) ' +
      'VALUES (:id_instituicao, :nome, :descricao, ''ATIVA'') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'descricao = VALUES(descricao), ' +
      'situacao = ''ATIVA''';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('descricao').AsString := ADescricao;
    Qry.Execute;
  finally
    Qry.Free;
  end;

  Result :=
    BuscarId(
      'SELECT id FROM curso_categoria ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND nome = :chave LIMIT 1',
      ANome
    );
end;

function TDemoSeed.GarantirModeloCertificado: Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO certificado_modelo ' +
      '(id_instituicao, nome, descricao, situacao) ' +
      'VALUES ' +
      '(:id_instituicao, :nome, :descricao, ''ATIVO'') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'descricao = VALUES(descricao), ' +
      'situacao = ''ATIVO''';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('nome').AsString := 'Certificado Padrao Institucional';
    Qry.ParamByName('descricao').AsString :=
      'Modelo de demonstracao para visualizacao das turmas.';
    Qry.Execute;
  finally
    Qry.Free;
  end;

  Result :=
    BuscarId(
      'SELECT id FROM certificado_modelo ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND nome = :chave LIMIT 1',
      'Certificado Padrao Institucional'
    );
end;

function TDemoSeed.GarantirCurso(
  const AIdCategoria: Int64;
  const ACodigoPublico,
        ACodigoInterno,
        ASlug,
        ANome,
        ADescricao,
        AObjetivo,
        AModalidade: string;
  const ACargaHorariaMinutos: Integer;
  const AInscricaoPublica: Boolean
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO curso ' +
      '(id_instituicao, id_categoria, codigo_publico, codigo_interno, ' +
      ' slug, nome, descricao, objetivo, carga_horaria_minutos, modalidade, ' +
      ' permitir_inscricao_publica, situacao) ' +
      'VALUES ' +
      '(:id_instituicao, :id_categoria, :codigo_publico, :codigo_interno, ' +
      ' :slug, :nome, :descricao, :objetivo, :carga, :modalidade, ' +
      ' :publica, ''ATIVO'') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'id_categoria = VALUES(id_categoria), ' +
      'nome = VALUES(nome), ' +
      'descricao = VALUES(descricao), ' +
      'objetivo = VALUES(objetivo), ' +
      'carga_horaria_minutos = VALUES(carga_horaria_minutos), ' +
      'modalidade = VALUES(modalidade), ' +
      'permitir_inscricao_publica = VALUES(permitir_inscricao_publica), ' +
      'situacao = ''ATIVO''';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_categoria').AsLargeInt := AIdCategoria;
    Qry.ParamByName('codigo_publico').AsString := ACodigoPublico;
    Qry.ParamByName('codigo_interno').AsString := ACodigoInterno;
    Qry.ParamByName('slug').AsString := ASlug;
    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('descricao').AsString := ADescricao;
    Qry.ParamByName('objetivo').AsString := AObjetivo;
    Qry.ParamByName('carga').AsInteger := ACargaHorariaMinutos;
    Qry.ParamByName('modalidade').AsString := AModalidade;
    Qry.ParamByName('publica').AsInteger := Ord(AInscricaoPublica);
    Qry.Execute;
  finally
    Qry.Free;
  end;

  Result :=
    BuscarId(
      'SELECT id FROM curso ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND codigo_interno = :chave LIMIT 1',
      ACodigoInterno
    );
end;

function TDemoSeed.GarantirInstrutor(
  const ACodigoPublico,
        ANome,
        AEmail,
        ATelefone,
        ABiografia: string
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO instrutor ' +
      '(id_instituicao, codigo_publico, nome, email, telefone, biografia, situacao) ' +
      'SELECT :id_instituicao, :codigo_publico, :nome, :email, :telefone, :biografia, ''ATIVO'' ' +
      'WHERE NOT EXISTS (' +
      '  SELECT 1 FROM instrutor ' +
      '  WHERE codigo_publico = :codigo_publico_check' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('codigo_publico').AsString := ACodigoPublico;
    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('email').AsString := AEmail;
    Qry.ParamByName('telefone').AsString := ATelefone;
    Qry.ParamByName('biografia').AsString := ABiografia;
    Qry.ParamByName('codigo_publico_check').AsString := ACodigoPublico;
    Qry.Execute;
  finally
    Qry.Free;
  end;

  Result :=
    BuscarId(
      'SELECT id FROM instrutor ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND codigo_publico = :chave LIMIT 1',
      ACodigoPublico
    );
end;

procedure TDemoSeed.VincularInstrutorCurso(
  const AIdCurso,
        AIdInstrutor: Int64;
  const APrincipal: Boolean
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO curso_instrutor ' +
      '(id_instituicao, id_curso, id_instrutor, principal) ' +
      'VALUES (:id_instituicao, :id_curso, :id_instrutor, :principal) ' +
      'ON DUPLICATE KEY UPDATE principal = VALUES(principal)';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_curso').AsLargeInt := AIdCurso;
    Qry.ParamByName('id_instrutor').AsLargeInt := AIdInstrutor;
    Qry.ParamByName('principal').AsInteger := Ord(APrincipal);
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

function TDemoSeed.GarantirTurma(
  const AIdCurso,
        AIdModelo: Int64;
  const ACodigoPublico,
        ACodigoInterno,
        ANome,
        AModalidade,
        ALocal,
        ASituacao: string;
  const AInicio,
        AFim,
        AInscricaoInicio,
        AInscricaoFim: TDateTime;
  const ALimite: Integer;
  const AInscricaoPublica: Boolean
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO turma ' +
      '(id_instituicao, id_curso, id_modelo_certificado, codigo_publico, ' +
      ' codigo_interno, nome, modalidade, data_hora_inicio, data_hora_fim, ' +
      ' inscricao_inicio, inscricao_fim, limite_participantes, local, ' +
      ' permitir_inscricao_publica, situacao) ' +
      'SELECT ' +
      ':id_instituicao, :id_curso, :id_modelo, :codigo_publico, ' +
      ':codigo_interno, :nome, :modalidade, :inicio, :fim, ' +
      ':inscricao_inicio, :inscricao_fim, :limite, :local, :publica, :situacao ' +
      'WHERE NOT EXISTS (' +
      '  SELECT 1 FROM turma ' +
      '  WHERE id_instituicao = :id_instituicao_check ' +
      '    AND codigo_interno = :codigo_interno_check' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_curso').AsLargeInt := AIdCurso;
    Qry.ParamByName('id_modelo').AsLargeInt := AIdModelo;
    Qry.ParamByName('codigo_publico').AsString := ACodigoPublico;
    Qry.ParamByName('codigo_interno').AsString := ACodigoInterno;
    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('modalidade').AsString := AModalidade;
    Qry.ParamByName('inicio').AsDateTime := AInicio;
    Qry.ParamByName('fim').AsDateTime := AFim;
    Qry.ParamByName('inscricao_inicio').AsDateTime := AInscricaoInicio;
    Qry.ParamByName('inscricao_fim').AsDateTime := AInscricaoFim;
    Qry.ParamByName('limite').AsInteger := ALimite;
    Qry.ParamByName('local').AsString := ALocal;
    Qry.ParamByName('publica').AsInteger := Ord(AInscricaoPublica);
    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.ParamByName('id_instituicao_check').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('codigo_interno_check').AsString := ACodigoInterno;
    Qry.Execute;
  finally
    Qry.Free;
  end;

  Result :=
    BuscarId(
      'SELECT id FROM turma ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND codigo_interno = :chave LIMIT 1',
      ACodigoInterno
    );
end;

procedure TDemoSeed.VincularInstrutorTurma(
  const AIdTurma,
        AIdInstrutor: Int64;
  const APrincipal: Boolean
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO turma_instrutor ' +
      '(id_instituicao, id_turma, id_instrutor, principal) ' +
      'VALUES (:id_instituicao, :id_turma, :id_instrutor, :principal) ' +
      'ON DUPLICATE KEY UPDATE principal = VALUES(principal)';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id_instrutor').AsLargeInt := AIdInstrutor;
    Qry.ParamByName('principal').AsInteger := Ord(APrincipal);
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

function TDemoSeed.GarantirEncontro(
  const AIdTurma: Int64;
  const ATitulo,
        ADescricao,
        ALocal,
        ASituacao: string;
  const AInicio,
        AFim: TDateTime;
  const ACargaHorariaMinutos: Integer
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'SELECT id FROM turma_encontro ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id_turma = :id_turma ' +
      '  AND titulo = :titulo ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('titulo').AsString := ATitulo;
    Qry.Open;

    if not Qry.IsEmpty then
      Exit(Qry.FieldByName('id').AsLargeInt);

    Qry.Close;
    Qry.SQL.Text :=
      'INSERT INTO turma_encontro ' +
      '(id_instituicao, id_turma, titulo, descricao, data_hora_inicio, ' +
      ' data_hora_fim, carga_horaria_minutos, local, obrigatorio, situacao) ' +
      'VALUES ' +
      '(:id_instituicao, :id_turma, :titulo, :descricao, :inicio, ' +
      ' :fim, :carga, :local, 1, :situacao)';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('titulo').AsString := ATitulo;
    Qry.ParamByName('descricao').AsString := ADescricao;
    Qry.ParamByName('inicio').AsDateTime := AInicio;
    Qry.ParamByName('fim').AsDateTime := AFim;
    Qry.ParamByName('carga').AsInteger := ACargaHorariaMinutos;
    Qry.ParamByName('local').AsString := ALocal;
    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.Execute;
  finally
    Qry.Free;
  end;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'SELECT id FROM turma_encontro ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id_turma = :id_turma ' +
      '  AND titulo = :titulo ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('titulo').AsString := ATitulo;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsLargeInt
    else
      Result := 0;
  finally
    Qry.Free;
  end;
end;

procedure TDemoSeed.GarantirCriterioPresenca(
  const AIdTurma: Int64;
  const APercentualMinimo: Integer
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO turma_criterio_conclusao ' +
      '(id_instituicao, id_turma, tipo, nome, obrigatorio, configuracao, ordem, situacao) ' +
      'SELECT :id_instituicao, :id_turma, ''PRESENCA_MINIMA'', ' +
      '       :nome, 1, :configuracao, 1, ''ATIVO'' ' +
      'WHERE NOT EXISTS (' +
      '  SELECT 1 FROM turma_criterio_conclusao ' +
      '  WHERE id_instituicao = :id_instituicao_check ' +
      '    AND id_turma = :id_turma_check ' +
      '    AND tipo = ''PRESENCA_MINIMA''' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('nome').AsString :=
      'Presenca minima de ' +
      APercentualMinimo.ToString +
      '%';
    Qry.ParamByName('configuracao').AsString :=
      '{"percentual_minimo":' +
      APercentualMinimo.ToString +
      '}';
    Qry.ParamByName('id_instituicao_check').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma_check').AsLargeInt := AIdTurma;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

function TDemoSeed.GarantirParticipante(
  const ACodigoPublico,
        ANome,
        AEmail,
        AMatricula,
        ATelefone,
        AOrgao,
        ACargo: string
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO participante ' +
      '(id_instituicao, codigo_publico, nome, email, matricula, telefone, ' +
      ' orgao_empresa, cargo, situacao) ' +
      'VALUES ' +
      '(:id_instituicao, :codigo_publico, :nome, :email, :matricula, :telefone, ' +
      ' :orgao, :cargo, ''ATIVO'') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'nome = VALUES(nome), ' +
      'email = VALUES(email), ' +
      'telefone = VALUES(telefone), ' +
      'orgao_empresa = VALUES(orgao_empresa), ' +
      'cargo = VALUES(cargo)';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('codigo_publico').AsString := ACodigoPublico;
    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('email').AsString := AEmail;
    Qry.ParamByName('matricula').AsString := AMatricula;
    Qry.ParamByName('telefone').AsString := ATelefone;
    Qry.ParamByName('orgao').AsString := AOrgao;
    Qry.ParamByName('cargo').AsString := ACargo;
    Qry.Execute;
  finally
    Qry.Free;
  end;

  Result :=
    BuscarId(
      'SELECT id FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND matricula = :chave LIMIT 1',
      AMatricula
    );
end;

function TDemoSeed.GarantirInscricao(
  const AIdTurma,
        AIdParticipante: Int64;
  const ACodigoPublico,
        AOrigem,
        ASituacao: string;
  const APercentualPresenca,
        APercentualProgresso: Double;
  const AConcluida: Boolean
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO inscricao ' +
      '(id_instituicao, id_turma, id_participante, codigo_publico, origem, situacao, ' +
      ' confirmado_em, iniciado_em, concluido_em, percentual_presenca, ' +
      ' percentual_progresso, elegivel_certificado) ' +
      'SELECT :id_instituicao, :id_turma, :id_participante, :codigo_publico, ' +
      '       :origem, :situacao, ' +
      '       CASE WHEN :situacao2 IN (''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'') ' +
      '            THEN CURRENT_TIMESTAMP(3) ELSE NULL END, ' +
      '       CASE WHEN :situacao3 IN (''EM_ANDAMENTO'',''CONCLUIDO'') ' +
      '            THEN CURRENT_TIMESTAMP(3) ELSE NULL END, ' +
      '       CASE WHEN :concluida = 1 THEN CURRENT_TIMESTAMP(3) ELSE NULL END, ' +
      '       :presenca, :progresso, :elegivel ' +
      'WHERE NOT EXISTS (' +
      '  SELECT 1 FROM inscricao ' +
      '  WHERE id_instituicao = :id_instituicao_check ' +
      '    AND id_turma = :id_turma_check ' +
      '    AND id_participante = :id_participante_check' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id_participante').AsLargeInt := AIdParticipante;
    Qry.ParamByName('codigo_publico').AsString := ACodigoPublico;
    Qry.ParamByName('origem').AsString := AOrigem;
    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.ParamByName('situacao2').AsString := ASituacao;
    Qry.ParamByName('situacao3').AsString := ASituacao;
    Qry.ParamByName('concluida').AsInteger := Ord(AConcluida);
    Qry.ParamByName('presenca').AsFloat := APercentualPresenca;
    Qry.ParamByName('progresso').AsFloat := APercentualProgresso;
    Qry.ParamByName('elegivel').AsInteger := Ord(AConcluida);
    Qry.ParamByName('id_instituicao_check').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma_check').AsLargeInt := AIdTurma;
    Qry.ParamByName('id_participante_check').AsLargeInt := AIdParticipante;
    Qry.Execute;
  finally
    Qry.Free;
  end;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'SELECT id FROM inscricao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id_turma = :id_turma ' +
      '  AND id_participante = :id_participante ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id_participante').AsLargeInt := AIdParticipante;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsLargeInt
    else
      Result := 0;
  finally
    Qry.Free;
  end;
end;

procedure TDemoSeed.GarantirPresenca(
  const AIdTurma,
        AIdEncontro,
        AIdInscricao: Int64;
  const ASituacao: string;
  const ACheckin,
        ACheckout: TDateTime;
  const AMinutos: Integer
);
var
  Qry: TUniQuery;
begin
  if (AIdEncontro <= 0) or
     (AIdInscricao <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      'INSERT INTO presenca ' +
      '(id_instituicao, id_turma, id_encontro, id_inscricao, situacao, ' +
      ' checkin_em, checkout_em, minutos_presentes) ' +
      'VALUES ' +
      '(:id_instituicao, :id_turma, :id_encontro, :id_inscricao, :situacao, ' +
      ' :checkin, :checkout, :minutos) ' +
      'ON DUPLICATE KEY UPDATE ' +
      'situacao = VALUES(situacao), ' +
      'checkin_em = VALUES(checkin_em), ' +
      'checkout_em = VALUES(checkout_em), ' +
      'minutos_presentes = VALUES(minutos_presentes)';

    Qry.ParamByName('id_instituicao').AsLargeInt := FIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id_encontro').AsLargeInt := AIdEncontro;
    Qry.ParamByName('id_inscricao').AsLargeInt := AIdInscricao;
    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.ParamByName('checkin').AsDateTime := ACheckin;
    Qry.ParamByName('checkout').AsDateTime := ACheckout;
    Qry.ParamByName('minutos').AsInteger := AMinutos;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

procedure TDemoSeed.Executar;
var
  CatSeguranca,
  CatTecnologia,
  CatGestao,
  CatAtendimento: Int64;

  Modelo: Int64;

  CursoNR10,
  CursoExcel,
  CursoLGPD,
  CursoLideranca,
  CursoAtendimento,
  CursoPrimeirosSocorros: Int64;

  InstrutorCarlos,
  InstrutoraFernanda,
  InstrutorRicardo,
  InstrutoraMariana: Int64;

  TurmaNR10,
  TurmaExcel,
  TurmaLGPD,
  TurmaLideranca,
  TurmaAtendimento,
  TurmaPrimeirosSocorros: Int64;

  EncontroNR10,
  EncontroPrimeirosSocorros,
  EncontroExcel: Int64;

  P: array[1..12] of Int64;
  I: Int64;

  Hoje: TDateTime;
begin
  Hoje := Date;

  CatSeguranca :=
    GarantirCategoria(
      'Seguranca e Normas',
      'Capacitacoes obrigatorias, seguranca do trabalho e normas regulamentadoras.'
    );

  CatTecnologia :=
    GarantirCategoria(
      'Tecnologia',
      'Ferramentas digitais, produtividade e transformacao digital.'
    );

  CatGestao :=
    GarantirCategoria(
      'Gestao e Lideranca',
      'Desenvolvimento de liderancas, equipes e processos.'
    );

  CatAtendimento :=
    GarantirCategoria(
      'Atendimento e Cidadania',
      'Capacitacoes voltadas ao atendimento, comunicacao e relacionamento.'
    );

  Modelo := GarantirModeloCertificado;

  CursoNR10 :=
    GarantirCurso(
      CatSeguranca,
      'DEMO-CURSO-NR10-001',
      'NR10-DEMO',
      'nr10-seguranca-eletrica-demo',
      'NR-10 - Seguranca em Instalacoes Eletricas',
      'Capacitacao presencial com foco em seguranca, prevencao e procedimentos em instalacoes eletricas.',
      'Preparar os participantes para reconhecer riscos e aplicar procedimentos seguros conforme a NR-10.',
      'PRESENCIAL',
      2400,
      True
    );

  CursoExcel :=
    GarantirCurso(
      CatTecnologia,
      'DEMO-CURSO-EXCEL-001',
      'EXCEL-DEMO',
      'excel-avancado-demo',
      'Excel Avancado para Gestao',
      'Capacitacao pratica para analise de dados, formulas, tabelas dinamicas e indicadores.',
      'Aumentar a produtividade das equipes na organizacao e analise de informacoes.',
      'PRESENCIAL',
      960,
      True
    );

  CursoLGPD :=
    GarantirCurso(
      CatTecnologia,
      'DEMO-CURSO-LGPD-001',
      'LGPD-DEMO',
      'lgpd-protecao-dados-demo',
      'LGPD e Protecao de Dados',
      'Fundamentos de privacidade, tratamento de dados pessoais e boas praticas de seguranca.',
      'Orientar equipes sobre responsabilidades no tratamento de dados pessoais.',
      'HIBRIDO',
      480,
      True
    );

  CursoLideranca :=
    GarantirCurso(
      CatGestao,
      'DEMO-CURSO-LIDER-001',
      'LIDER-DEMO',
      'lideranca-equipes-demo',
      'Lideranca e Gestao de Equipes',
      'Formacao para liderancas com foco em comunicacao, feedback e acompanhamento de resultados.',
      'Desenvolver competencias de lideranca e organizacao de equipes.',
      'PRESENCIAL',
      720,
      True
    );

  CursoAtendimento :=
    GarantirCurso(
      CatAtendimento,
      'DEMO-CURSO-ATEND-001',
      'ATEND-DEMO',
      'excelencia-atendimento-demo',
      'Excelencia no Atendimento ao Publico',
      'Tecnicas de comunicacao, acolhimento, postura profissional e tratamento de situacoes dificeis.',
      'Melhorar a experiencia do cidadao e do cliente nos canais de atendimento.',
      'PRESENCIAL',
      480,
      True
    );

  CursoPrimeirosSocorros :=
    GarantirCurso(
      CatSeguranca,
      'DEMO-CURSO-PSOC-001',
      'PSOC-DEMO',
      'primeiros-socorros-demo',
      'Primeiros Socorros no Ambiente de Trabalho',
      'Capacitacao pratica para resposta inicial a emergencias ate a chegada do atendimento especializado.',
      'Capacitar equipes para agir de forma segura em situacoes de emergencia.',
      'PRESENCIAL',
      480,
      True
    );

  InstrutorCarlos :=
    GarantirInstrutor(
      'DEMO-INSTRUTOR-001',
      'Carlos Henrique Almeida',
      'carlos.almeida@example.com',
      '(11) 90000-1001',
      'Engenheiro de seguranca do trabalho e instrutor de normas regulamentadoras.'
    );

  InstrutoraFernanda :=
    GarantirInstrutor(
      'DEMO-INSTRUTOR-002',
      'Fernanda Souza Martins',
      'fernanda.martins@example.com',
      '(11) 90000-1002',
      'Especialista em produtividade, tecnologia e capacitacao corporativa.'
    );

  InstrutorRicardo :=
    GarantirInstrutor(
      'DEMO-INSTRUTOR-003',
      'Ricardo Oliveira Santos',
      'ricardo.santos@example.com',
      '(11) 90000-1003',
      'Consultor em gestao de equipes, comunicacao e desenvolvimento de liderancas.'
    );

  InstrutoraMariana :=
    GarantirInstrutor(
      'DEMO-INSTRUTOR-004',
      'Mariana Lima Costa',
      'mariana.lima@example.com',
      '(11) 90000-1004',
      'Instrutora de atendimento, cidadania e primeiros socorros.'
    );

  VincularInstrutorCurso(CursoNR10, InstrutorCarlos, True);
  VincularInstrutorCurso(CursoExcel, InstrutoraFernanda, True);
  VincularInstrutorCurso(CursoLGPD, InstrutoraFernanda, True);
  VincularInstrutorCurso(CursoLideranca, InstrutorRicardo, True);
  VincularInstrutorCurso(CursoAtendimento, InstrutoraMariana, True);
  VincularInstrutorCurso(CursoPrimeirosSocorros, InstrutoraMariana, True);

  TurmaNR10 :=
    GarantirTurma(
      CursoNR10,
      Modelo,
      'DEMO-TURMA-NR10-001',
      'T-NR10-DEMO',
      'Turma NR-10 - Setembro',
      'PRESENCIAL',
      'Centro de Treinamento - Sala 1',
      'EM_ANDAMENTO',
      IncDay(Hoje, -2) + EncodeTime(8, 0, 0, 0),
      IncDay(Hoje, 2) + EncodeTime(17, 0, 0, 0),
      IncDay(Hoje, -20),
      IncDay(Hoje, -3) + EncodeTime(23, 59, 0, 0),
      25,
      True
    );

  TurmaExcel :=
    GarantirTurma(
      CursoExcel,
      Modelo,
      'DEMO-TURMA-EXCEL-001',
      'T-EXCEL-DEMO',
      'Excel Avancado - Turma Setembro',
      'PRESENCIAL',
      'Laboratorio de Informatica',
      'ENCERRADA',
      IncDay(Hoje, -30) + EncodeTime(8, 0, 0, 0),
      IncDay(Hoje, -29) + EncodeTime(17, 0, 0, 0),
      IncDay(Hoje, -50),
      IncDay(Hoje, -32) + EncodeTime(23, 59, 0, 0),
      20,
      True
    );

  TurmaLGPD :=
    GarantirTurma(
      CursoLGPD,
      Modelo,
      'DEMO-TURMA-LGPD-001',
      'T-LGPD-DEMO',
      'LGPD - Turma Novembro',
      'HIBRIDO',
      'Auditorio Principal',
      'PLANEJADA',
      IncDay(Hoje, 25) + EncodeTime(9, 0, 0, 0),
      IncDay(Hoje, 25) + EncodeTime(17, 0, 0, 0),
      IncDay(Hoje, 5),
      IncDay(Hoje, 22) + EncodeTime(23, 59, 0, 0),
      60,
      True
    );

  TurmaLideranca :=
    GarantirTurma(
      CursoLideranca,
      Modelo,
      'DEMO-TURMA-LIDER-001',
      'T-LIDER-DEMO',
      'Lideranca - Turma Outubro',
      'PRESENCIAL',
      'Sala de Capacitacao 2',
      'INSCRICOES_ABERTAS',
      IncDay(Hoje, 15) + EncodeTime(8, 30, 0, 0),
      IncDay(Hoje, 16) + EncodeTime(16, 30, 0, 0),
      IncDay(Hoje, -5),
      IncDay(Hoje, 12) + EncodeTime(23, 59, 0, 0),
      30,
      True
    );

  TurmaAtendimento :=
    GarantirTurma(
      CursoAtendimento,
      Modelo,
      'DEMO-TURMA-ATEND-001',
      'T-ATEND-DEMO',
      'Atendimento ao Publico - Outubro',
      'PRESENCIAL',
      'Auditorio Principal',
      'INSCRICOES_ABERTAS',
      IncDay(Hoje, 10) + EncodeTime(8, 0, 0, 0),
      IncDay(Hoje, 10) + EncodeTime(17, 0, 0, 0),
      IncDay(Hoje, -7),
      IncDay(Hoje, 8) + EncodeTime(23, 59, 0, 0),
      40,
      True
    );

  TurmaPrimeirosSocorros :=
    GarantirTurma(
      CursoPrimeirosSocorros,
      Modelo,
      'DEMO-TURMA-PSOC-001',
      'T-PSOC-DEMO',
      'Primeiros Socorros - Setembro',
      'PRESENCIAL',
      'Centro de Treinamento - Sala 3',
      'EM_ANDAMENTO',
      IncDay(Hoje, -1) + EncodeTime(8, 0, 0, 0),
      IncDay(Hoje, 1) + EncodeTime(17, 0, 0, 0),
      IncDay(Hoje, -15),
      IncDay(Hoje, -2) + EncodeTime(23, 59, 0, 0),
      25,
      True
    );

  VincularInstrutorTurma(TurmaNR10, InstrutorCarlos, True);
  VincularInstrutorTurma(TurmaExcel, InstrutoraFernanda, True);
  VincularInstrutorTurma(TurmaLGPD, InstrutoraFernanda, True);
  VincularInstrutorTurma(TurmaLideranca, InstrutorRicardo, True);
  VincularInstrutorTurma(TurmaAtendimento, InstrutoraMariana, True);
  VincularInstrutorTurma(TurmaPrimeirosSocorros, InstrutoraMariana, True);

  GarantirCriterioPresenca(TurmaNR10, 75);
  GarantirCriterioPresenca(TurmaExcel, 75);
  GarantirCriterioPresenca(TurmaLGPD, 75);
  GarantirCriterioPresenca(TurmaLideranca, 75);
  GarantirCriterioPresenca(TurmaAtendimento, 75);
  GarantirCriterioPresenca(TurmaPrimeirosSocorros, 75);

  EncontroNR10 :=
    GarantirEncontro(
      TurmaNR10,
      'Pratica de Seguranca Eletrica',
      'Atividade presencial com demonstracao de procedimentos de seguranca.',
      'Centro de Treinamento - Sala 1',
      'REALIZADO',
      IncDay(Hoje, -1) + EncodeTime(8, 0, 0, 0),
      IncDay(Hoje, -1) + EncodeTime(12, 0, 0, 0),
      240
    );

  EncontroPrimeirosSocorros :=
    GarantirEncontro(
      TurmaPrimeirosSocorros,
      'Atendimento Inicial de Emergencias',
      'Simulacoes praticas de atendimento inicial.',
      'Centro de Treinamento - Sala 3',
      'REALIZADO',
      Hoje + EncodeTime(8, 0, 0, 0),
      Hoje + EncodeTime(12, 0, 0, 0),
      240
    );

  EncontroExcel :=
    GarantirEncontro(
      TurmaExcel,
      'Oficina de Indicadores e Tabelas Dinamicas',
      'Exercicios praticos com planilhas e indicadores.',
      'Laboratorio de Informatica',
      'REALIZADO',
      IncDay(Hoje, -30) + EncodeTime(8, 0, 0, 0),
      IncDay(Hoje, -30) + EncodeTime(17, 0, 0, 0),
      480
    );

  P[1] := GarantirParticipante('DEMO-PART-0001', 'Ana Paula Ribeiro', 'ana.ribeiro@example.com', 'DEMO-0001', '(11) 91000-0001', 'Secretaria de Administracao', 'Analista Administrativo');
  P[2] := GarantirParticipante('DEMO-PART-0002', 'Bruno Henrique Souza', 'bruno.souza@example.com', 'DEMO-0002', '(11) 91000-0002', 'Secretaria de Financas', 'Assistente Administrativo');
  P[3] := GarantirParticipante('DEMO-PART-0003', 'Camila Fernandes Lima', 'camila.lima@example.com', 'DEMO-0003', '(11) 91000-0003', 'Recursos Humanos', 'Analista de RH');
  P[4] := GarantirParticipante('DEMO-PART-0004', 'Daniel Costa Pereira', 'daniel.pereira@example.com', 'DEMO-0004', '(11) 91000-0004', 'Tecnologia da Informacao', 'Tecnico de Suporte');
  P[5] := GarantirParticipante('DEMO-PART-0005', 'Elaine Martins Rocha', 'elaine.rocha@example.com', 'DEMO-0005', '(11) 91000-0005', 'Atendimento ao Cidadao', 'Agente de Atendimento');
  P[6] := GarantirParticipante('DEMO-PART-0006', 'Fabio Almeida Santos', 'fabio.santos@example.com', 'DEMO-0006', '(11) 91000-0006', 'Manutencao', 'Eletricista');
  P[7] := GarantirParticipante('DEMO-PART-0007', 'Gabriela Oliveira Melo', 'gabriela.melo@example.com', 'DEMO-0007', '(11) 91000-0007', 'Secretaria de Educacao', 'Coordenadora');
  P[8] := GarantirParticipante('DEMO-PART-0008', 'Henrique Batista Gomes', 'henrique.gomes@example.com', 'DEMO-0008', '(11) 91000-0008', 'Operacoes', 'Supervisor');
  P[9] := GarantirParticipante('DEMO-PART-0009', 'Isabela Nunes Carvalho', 'isabela.carvalho@example.com', 'DEMO-0009', '(11) 91000-0009', 'Controladoria', 'Analista');
  P[10] := GarantirParticipante('DEMO-PART-0010', 'Joao Pedro Martins', 'joao.martins@example.com', 'DEMO-0010', '(11) 91000-0010', 'Compras', 'Comprador');
  P[11] := GarantirParticipante('DEMO-PART-0011', 'Larissa Mendes Silva', 'larissa.silva@example.com', 'DEMO-0011', '(11) 91000-0011', 'Secretaria de Saude', 'Assistente');
  P[12] := GarantirParticipante('DEMO-PART-0012', 'Marcos Vinicius Freitas', 'marcos.freitas@example.com', 'DEMO-0012', '(11) 91000-0012', 'Seguranca do Trabalho', 'Tecnico de Seguranca');

  I := GarantirInscricao(TurmaNR10, P[1], 'DEMO-INSC-NR10-001', 'ADMIN', 'EM_ANDAMENTO', 100, 60, False);
  GarantirPresenca(TurmaNR10, EncontroNR10, I, 'PRESENTE', IncDay(Hoje, -1) + EncodeTime(7, 55, 0, 0), IncDay(Hoje, -1) + EncodeTime(12, 0, 0, 0), 245);

  I := GarantirInscricao(TurmaNR10, P[2], 'DEMO-INSC-NR10-002', 'PUBLICA', 'EM_ANDAMENTO', 100, 60, False);
  GarantirPresenca(TurmaNR10, EncontroNR10, I, 'PRESENTE', IncDay(Hoje, -1) + EncodeTime(7, 58, 0, 0), IncDay(Hoje, -1) + EncodeTime(12, 0, 0, 0), 242);

  I := GarantirInscricao(TurmaNR10, P[6], 'DEMO-INSC-NR10-003', 'ADMIN', 'EM_ANDAMENTO', 75, 50, False);
  GarantirPresenca(TurmaNR10, EncontroNR10, I, 'PARCIAL', IncDay(Hoje, -1) + EncodeTime(8, 15, 0, 0), IncDay(Hoje, -1) + EncodeTime(11, 15, 0, 0), 180);

  GarantirInscricao(TurmaNR10, P[8], 'DEMO-INSC-NR10-004', 'PUBLICA', 'CONFIRMADO', 0, 0, False);
  GarantirInscricao(TurmaNR10, P[12], 'DEMO-INSC-NR10-005', 'ADMIN', 'CONFIRMADO', 0, 0, False);

  I := GarantirInscricao(TurmaPrimeirosSocorros, P[3], 'DEMO-INSC-PSOC-001', 'ADMIN', 'EM_ANDAMENTO', 100, 50, False);
  GarantirPresenca(TurmaPrimeirosSocorros, EncontroPrimeirosSocorros, I, 'PRESENTE', Hoje + EncodeTime(7, 57, 0, 0), Hoje + EncodeTime(12, 0, 0, 0), 243);

  I := GarantirInscricao(TurmaPrimeirosSocorros, P[5], 'DEMO-INSC-PSOC-002', 'PUBLICA', 'EM_ANDAMENTO', 100, 50, False);
  GarantirPresenca(TurmaPrimeirosSocorros, EncontroPrimeirosSocorros, I, 'PRESENTE', Hoje + EncodeTime(8, 0, 0, 0), Hoje + EncodeTime(12, 0, 0, 0), 240);

  GarantirInscricao(TurmaPrimeirosSocorros, P[7], 'DEMO-INSC-PSOC-003', 'ADMIN', 'CONFIRMADO', 0, 0, False);
  GarantirInscricao(TurmaPrimeirosSocorros, P[11], 'DEMO-INSC-PSOC-004', 'ADMIN', 'CONFIRMADO', 0, 0, False);

  GarantirInscricao(TurmaAtendimento, P[1], 'DEMO-INSC-ATEND-001', 'PUBLICA', 'INSCRITO', 0, 0, False);
  GarantirInscricao(TurmaAtendimento, P[5], 'DEMO-INSC-ATEND-002', 'PUBLICA', 'INSCRITO', 0, 0, False);
  GarantirInscricao(TurmaAtendimento, P[9], 'DEMO-INSC-ATEND-003', 'ADMIN', 'CONFIRMADO', 0, 0, False);
  GarantirInscricao(TurmaAtendimento, P[10], 'DEMO-INSC-ATEND-004', 'PUBLICA', 'INSCRITO', 0, 0, False);

  GarantirInscricao(TurmaLideranca, P[3], 'DEMO-INSC-LIDER-001', 'PUBLICA', 'INSCRITO', 0, 0, False);
  GarantirInscricao(TurmaLideranca, P[7], 'DEMO-INSC-LIDER-002', 'ADMIN', 'CONFIRMADO', 0, 0, False);
  GarantirInscricao(TurmaLideranca, P[8], 'DEMO-INSC-LIDER-003', 'PUBLICA', 'INSCRITO', 0, 0, False);

  GarantirInscricao(TurmaLGPD, P[4], 'DEMO-INSC-LGPD-001', 'ADMIN', 'CONFIRMADO', 0, 0, False);
  GarantirInscricao(TurmaLGPD, P[9], 'DEMO-INSC-LGPD-002', 'PUBLICA', 'INSCRITO', 0, 0, False);

  I := GarantirInscricao(TurmaExcel, P[2], 'DEMO-INSC-EXCEL-001', 'ADMIN', 'CONCLUIDO', 100, 100, True);
  GarantirPresenca(TurmaExcel, EncontroExcel, I, 'PRESENTE', IncDay(Hoje, -30) + EncodeTime(7, 55, 0, 0), IncDay(Hoje, -30) + EncodeTime(17, 0, 0, 0), 545);

  I := GarantirInscricao(TurmaExcel, P[4], 'DEMO-INSC-EXCEL-002', 'ADMIN', 'CONCLUIDO', 100, 100, True);
  GarantirPresenca(TurmaExcel, EncontroExcel, I, 'PRESENTE', IncDay(Hoje, -30) + EncodeTime(7, 58, 0, 0), IncDay(Hoje, -30) + EncodeTime(17, 0, 0, 0), 542);

  I := GarantirInscricao(TurmaExcel, P[10], 'DEMO-INSC-EXCEL-003', 'ADMIN', 'REPROVADO', 50, 100, False);
  GarantirPresenca(TurmaExcel, EncontroExcel, I, 'PARCIAL', IncDay(Hoje, -30) + EncodeTime(8, 0, 0, 0), IncDay(Hoje, -30) + EncodeTime(12, 0, 0, 0), 240);
end;

end.
