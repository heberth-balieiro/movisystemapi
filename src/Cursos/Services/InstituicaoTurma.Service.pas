unit InstituicaoTurma.Service;

interface

uses
  InstituicaoTurma.Model;

type
  TInstituicaoTurmaService = class
  private
    class function GerarCodigoPublico: string; static;

    class procedure ValidarNome(
      const ANome: string
    ); static;

    class procedure ValidarModalidade(
      const AModalidade: string
    ); static;

    class procedure ValidarSituacao(
      const ASituacao: string
    ); static;

    class procedure ValidarFluxo(
      const AAprovacaoInscricao,
            AControlePresenca: string;
      const AExigirPresencaConclusao,
            AConclusaoAutomatica,
            ACertificadoAutomatico: Boolean
    ); static;

    class procedure ValidarPeriodos(
      const ADataHoraInicio,
            ADataHoraFim: TDateTime;
      const ATemInscricaoInicio: Boolean;
      const AInscricaoInicio: TDateTime;
      const ATemInscricaoFim: Boolean;
      const AInscricaoFim: TDateTime
    ); static;

    class procedure ValidarOpcionais(
      const ACodigoInterno,
            ALocal,
            AUrlOnline: string;
      const ATemLimiteParticipantes: Boolean;
      const ALimiteParticipantes: Integer;
      const ATemCargaHorariaMinutos: Boolean;
      const ACargaHorariaMinutos: Integer
    ); static;

  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca,
            ASituacao,
            AModalidade: string;
      const AIdCurso: Int64;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoTurmaLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdTurma: Int64
    ): TInstituicaoTurmaItem; static;

    class function Cadastrar(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoTurmaCadastro
    ): TInstituicaoTurmaItem; static;

    class function Atualizar(
      const AIdInstituicao,
            AIdTurma: Int64;
      const ADados: TInstituicaoTurmaAlteracao
    ): TInstituicaoTurmaItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdTurma: Int64;
      const ASituacao: string
    ): TInstituicaoTurmaItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoTurma.DAO;

class function TInstituicaoTurmaService.GerarCodigoPublico: string;
var
  Guid: TGUID;
  S: string;
begin
  CreateGUID(Guid);

  S :=
    GUIDToString(Guid);

  S :=
    StringReplace(
      S,
      '{',
      '',
      [rfReplaceAll]
    );

  S :=
    StringReplace(
      S,
      '}',
      '',
      [rfReplaceAll]
    );

  S :=
    StringReplace(
      S,
      '-',
      '',
      [rfReplaceAll]
    );

  Result :=
    Copy(
      UpperCase(S),
      1,
      26
    );
end;

class procedure TInstituicaoTurmaService.ValidarNome(
  const ANome: string
);
begin
  if Trim(ANome).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome da turma.'
    );

  if Length(Trim(ANome)) > 180 then
    TAppErrors.RaiseBadRequest(
      'O nome da turma deve possuir no máximo 180 caracteres.'
    );
end;

class procedure TInstituicaoTurmaService.ValidarModalidade(
  const AModalidade: string
);
begin
  if not MatchText(
    UpperCase(Trim(AModalidade)),
    ['PRESENCIAL', 'ONLINE', 'HIBRIDO']
  ) then
    TAppErrors.RaiseBadRequest(
      'Modalidade inválida.'
    );
end;

class procedure TInstituicaoTurmaService.ValidarSituacao(
  const ASituacao: string
);
begin
  if not MatchText(
    UpperCase(Trim(ASituacao)),
    [
      'PLANEJADA',
      'INSCRICOES_ABERTAS',
      'EM_ANDAMENTO',
      'ENCERRADA',
      'CANCELADA'
    ]
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação da turma inválida.'
    );
end;

class procedure TInstituicaoTurmaService.ValidarFluxo(
  const AAprovacaoInscricao,
        AControlePresenca: string;
  const AExigirPresencaConclusao,
        AConclusaoAutomatica,
        ACertificadoAutomatico: Boolean
);
begin
  if not MatchText(UpperCase(Trim(AAprovacaoInscricao)), ['MANUAL','AUTOMATICA']) then
    TAppErrors.RaiseBadRequest('Tipo de aprovação da inscrição inválido.');

  if not MatchText(UpperCase(Trim(AControlePresenca)), ['ENCONTRO','TURMA','SEM_CONTROLE']) then
    TAppErrors.RaiseBadRequest('Tipo de controle de presença inválido.');

  if AExigirPresencaConclusao and SameText(AControlePresenca, 'SEM_CONTROLE') then
    TAppErrors.RaiseBadRequest('Não é possível exigir presença em uma turma sem controle de presença.');

  if AConclusaoAutomatica and not SameText(AControlePresenca, 'TURMA') then
    TAppErrors.RaiseBadRequest('A conclusão automática está disponível no fluxo de presença por QR Code da turma.');

  if ACertificadoAutomatico and not AConclusaoAutomatica then
    TAppErrors.RaiseBadRequest('O certificado automático exige conclusão automática da turma.');
end;

class procedure TInstituicaoTurmaService.ValidarPeriodos(
  const ADataHoraInicio,
        ADataHoraFim: TDateTime;
  const ATemInscricaoInicio: Boolean;
  const AInscricaoInicio: TDateTime;
  const ATemInscricaoFim: Boolean;
  const AInscricaoFim: TDateTime
);
begin
  if ADataHoraInicio <= 0 then
    TAppErrors.RaiseBadRequest(
      'Informe a data/hora de início da turma.'
    );

  if ADataHoraFim <= 0 then
    TAppErrors.RaiseBadRequest(
      'Informe a data/hora de término da turma.'
    );

  if ADataHoraFim < ADataHoraInicio then
    TAppErrors.RaiseBadRequest(
      'A data/hora de término não pode ser anterior ao início.'
    );

  if
    ATemInscricaoInicio and
    ATemInscricaoFim and
    (AInscricaoFim < AInscricaoInicio)
  then
    TAppErrors.RaiseBadRequest(
      'O término das inscrições não pode ser anterior ao início.'
    );
end;

class procedure TInstituicaoTurmaService.ValidarOpcionais(
  const ACodigoInterno,
        ALocal,
        AUrlOnline: string;
  const ATemLimiteParticipantes: Boolean;
  const ALimiteParticipantes: Integer;
  const ATemCargaHorariaMinutos: Boolean;
  const ACargaHorariaMinutos: Integer
);
begin
  if Length(Trim(ACodigoInterno)) > 50 then
    TAppErrors.RaiseBadRequest(
      'O código interno deve possuir no máximo 50 caracteres.'
    );

  if Length(Trim(ALocal)) > 255 then
    TAppErrors.RaiseBadRequest(
      'O local deve possuir no máximo 255 caracteres.'
    );

  if Length(Trim(AUrlOnline)) > 1000 then
    TAppErrors.RaiseBadRequest(
      'A URL online deve possuir no máximo 1000 caracteres.'
    );

  if
    ATemLimiteParticipantes and
    (ALimiteParticipantes <= 0)
  then
    TAppErrors.RaiseBadRequest(
      'O limite de participantes deve ser maior que zero.'
    );

  if
    ATemCargaHorariaMinutos and
    (ACargaHorariaMinutos <= 0)
  then
    TAppErrors.RaiseBadRequest(
      'A carga horária da turma deve ser maior que zero.'
    );
end;

class function TInstituicaoTurmaService.Listar(
  const AIdInstituicao: Int64;
  const ABusca,
        ASituacao,
        AModalidade: string;
  const AIdCurso: Int64;
  const APagina,
        APorPagina: Integer
): TInstituicaoTurmaLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoTurmaFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro :=
    Default(
      TInstituicaoTurmaFiltro
    );

  Filtro.Busca :=
    Trim(ABusca);

  Filtro.Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

  Filtro.Modalidade :=
    UpperCase(
      Trim(AModalidade)
    );

  Filtro.IdCurso :=
    AIdCurso;

  Filtro.Pagina :=
    APagina;

  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  Filtro.PorPagina :=
    APorPagina;

  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 20;

  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  if not Filtro.Situacao.IsEmpty then
    ValidarSituacao(
      Filtro.Situacao
    );

  if not Filtro.Modalidade.IsEmpty then
    ValidarModalidade(
      Filtro.Modalidade
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
    Result :=
      TInstituicaoTurmaDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaService.BuscarPorId(
  const AIdInstituicao,
        AIdTurma: Int64
): TInstituicaoTurmaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest(
      'Turma inválida.'
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
    Result :=
      TInstituicaoTurmaDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdTurma
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Turma não encontrada.'
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaService.Cadastrar(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoTurmaCadastro
): TInstituicaoTurmaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoTurmaCadastro;
  IdTurma: Int64;
  Tentativas: Integer;
  CodigoDisponivel: Boolean;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Vínculo do usuário com a instituição não identificado.'
    );

  Dados := ADados;

  Dados.CodigoInterno :=
    Trim(Dados.CodigoInterno);

  Dados.Nome :=
    Trim(Dados.Nome);

  Dados.Modalidade :=
    UpperCase(
      Trim(Dados.Modalidade)
    );

  Dados.Local :=
    Trim(Dados.Local);

  Dados.UrlOnline :=
    Trim(Dados.UrlOnline);

  Dados.Situacao :=
    UpperCase(
      Trim(Dados.Situacao)
    );

  Dados.AprovacaoInscricao := UpperCase(Trim(Dados.AprovacaoInscricao));
  if Dados.AprovacaoInscricao.IsEmpty then Dados.AprovacaoInscricao := 'MANUAL';
  Dados.ControlePresenca := UpperCase(Trim(Dados.ControlePresenca));
  if Dados.ControlePresenca.IsEmpty then Dados.ControlePresenca := 'ENCONTRO';

  if Dados.Situacao.IsEmpty then
    Dados.Situacao :=
      'PLANEJADA';

  Dados.CriadoPor :=
    AIdUsuarioInstituicao;

  if Dados.IdCurso <= 0 then
    TAppErrors.RaiseBadRequest(
      'Informe o curso da turma.'
    );

  ValidarNome(
    Dados.Nome
  );

  ValidarModalidade(
    Dados.Modalidade
  );

  ValidarSituacao(
    Dados.Situacao
  );

  ValidarFluxo(
    Dados.AprovacaoInscricao,
    Dados.ControlePresenca,
    Dados.ExigirPresencaConclusao,
    Dados.ConclusaoAutomatica,
    Dados.CertificadoAutomatico
  );

  ValidarPeriodos(
    Dados.DataHoraInicio,
    Dados.DataHoraFim,
    Dados.TemInscricaoInicio,
    Dados.InscricaoInicio,
    Dados.TemInscricaoFim,
    Dados.InscricaoFim
  );

  ValidarOpcionais(
    Dados.CodigoInterno,
    Dados.Local,
    Dados.UrlOnline,
    Dados.TemLimiteParticipantes,
    Dados.LimiteParticipantes,
    Dados.TemCargaHorariaMinutos,
    Dados.CargaHorariaMinutos
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
    if not TInstituicaoTurmaDAO.ExisteCursoAtivo(
      Conn,
      AIdInstituicao,
      Dados.IdCurso
    ) then
      TAppErrors.RaiseBadRequest(
        'Curso não encontrado, não pertence à instituição ou está inativo.'
      );

    if Dados.IdModeloCertificado > 0 then
    begin
      if not TInstituicaoTurmaDAO.ExisteModeloCertificadoAtivo(
        Conn,
        AIdInstituicao,
        Dados.IdModeloCertificado
      ) then
        TAppErrors.RaiseBadRequest(
          'Modelo de certificado não encontrado, não pertence à instituição ou está inativo.'
        );
    end;

    if TInstituicaoTurmaDAO.ExisteCodigoInterno(
      Conn,
      AIdInstituicao,
      Dados.CodigoInterno
    ) then
      TAppErrors.RaiseBadRequest(
        'Já existe uma turma com este código interno.'
      );

    Tentativas := 0;
    CodigoDisponivel := False;

    repeat
      Inc(Tentativas);

      Dados.CodigoPublico :=
        GerarCodigoPublico;

      CodigoDisponivel :=
        not TInstituicaoTurmaDAO.ExisteCodigoPublico(
          Conn,
          Dados.CodigoPublico
        );

    until
      CodigoDisponivel or
      (Tentativas >= 5);

    if not CodigoDisponivel then
      raise Exception.Create(
        'Não foi possível gerar um código público único para a turma.'
      );

    Conn.StartTransaction;
    try
      IdTurma :=
        TInstituicaoTurmaDAO.Inserir(
          Conn,
          AIdInstituicao,
          Dados
        );

      Result :=
        TInstituicaoTurmaDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          IdTurma
        );

      if Result = nil then
        raise Exception.Create(
          'Turma cadastrada, mas não foi possível recuperar os dados.'
        );

      Conn.Commit;

    except
      if Conn.InTransaction then
        Conn.Rollback;

      Result.Free;
      Result := nil;

      raise;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaService.Atualizar(
  const AIdInstituicao,
        AIdTurma: Int64;
  const ADados: TInstituicaoTurmaAlteracao
): TInstituicaoTurmaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoTurmaAlteracao;
  TurmaAtual: TInstituicaoTurmaItem;
  MudouModelo: Boolean;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest(
      'Turma inválida.'
    );

  Dados := ADados;

  Dados.CodigoInterno :=
    Trim(Dados.CodigoInterno);

  Dados.Nome :=
    Trim(Dados.Nome);

  Dados.Modalidade :=
    UpperCase(
      Trim(Dados.Modalidade)
    );

  Dados.Local :=
    Trim(Dados.Local);

  Dados.UrlOnline :=
    Trim(Dados.UrlOnline);

  Dados.Situacao :=
    UpperCase(
      Trim(Dados.Situacao)
    );

  Dados.AprovacaoInscricao := UpperCase(Trim(Dados.AprovacaoInscricao));
  if Dados.AprovacaoInscricao.IsEmpty then Dados.AprovacaoInscricao := 'MANUAL';
  Dados.ControlePresenca := UpperCase(Trim(Dados.ControlePresenca));
  if Dados.ControlePresenca.IsEmpty then Dados.ControlePresenca := 'ENCONTRO';

  if Dados.IdCurso <= 0 then
    TAppErrors.RaiseBadRequest(
      'Informe o curso da turma.'
    );

  ValidarNome(
    Dados.Nome
  );

  ValidarModalidade(
    Dados.Modalidade
  );

  ValidarSituacao(
    Dados.Situacao
  );

  ValidarFluxo(
    Dados.AprovacaoInscricao,
    Dados.ControlePresenca,
    Dados.ExigirPresencaConclusao,
    Dados.ConclusaoAutomatica,
    Dados.CertificadoAutomatico
  );

  ValidarPeriodos(
    Dados.DataHoraInicio,
    Dados.DataHoraFim,
    Dados.TemInscricaoInicio,
    Dados.InscricaoInicio,
    Dados.TemInscricaoFim,
    Dados.InscricaoFim
  );

  ValidarOpcionais(
    Dados.CodigoInterno,
    Dados.Local,
    Dados.UrlOnline,
    Dados.TemLimiteParticipantes,
    Dados.LimiteParticipantes,
    Dados.TemCargaHorariaMinutos,
    Dados.CargaHorariaMinutos
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
    TurmaAtual :=
      TInstituicaoTurmaDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdTurma
      );

    try
      if TurmaAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Turma não encontrada.'
        );

      if Dados.IdCurso <> TurmaAtual.IdCurso then
      begin
        if not TInstituicaoTurmaDAO.ExisteCursoAtivo(
          Conn,
          AIdInstituicao,
          Dados.IdCurso
        ) then
          TAppErrors.RaiseBadRequest(
            'Curso não encontrado, não pertence à instituição ou está inativo.'
          );
      end;

      MudouModelo :=
        (Dados.IdModeloCertificado <> TurmaAtual.IdModeloCertificado) or
        ((Dados.IdModeloCertificado > 0) <> TurmaAtual.TemModeloCertificado);

      if
        MudouModelo and
        (Dados.IdModeloCertificado > 0)
      then
      begin
        if not TInstituicaoTurmaDAO.ExisteModeloCertificadoAtivo(
          Conn,
          AIdInstituicao,
          Dados.IdModeloCertificado
        ) then
          TAppErrors.RaiseBadRequest(
            'Modelo de certificado não encontrado, não pertence à instituição ou está inativo.'
          );
      end;

      if TInstituicaoTurmaDAO.ExisteCodigoInterno(
        Conn,
        AIdInstituicao,
        Dados.CodigoInterno,
        AIdTurma
      ) then
        TAppErrors.RaiseBadRequest(
          'Já existe uma turma com este código interno.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoTurmaDAO.Atualizar(
          Conn,
          AIdInstituicao,
          AIdTurma,
          Dados
        );

        Result :=
          TInstituicaoTurmaDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdTurma
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar a turma atualizada.'
          );

        Conn.Commit;

      except
        if Conn.InTransaction then
          Conn.Rollback;

        Result.Free;
        Result := nil;

        raise;
      end;

    finally
      TurmaAtual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaService.AlterarSituacao(
  const AIdInstituicao,
        AIdTurma: Int64;
  const ASituacao: string
): TInstituicaoTurmaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  TurmaAtual: TInstituicaoTurmaItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest(
      'Turma inválida.'
    );

  Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

  ValidarSituacao(
    Situacao
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
    TurmaAtual :=
      TInstituicaoTurmaDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdTurma
      );

    try
      if TurmaAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Turma não encontrada.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoTurmaDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AIdTurma,
          Situacao
        );

        Result :=
          TInstituicaoTurmaDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdTurma
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar a turma atualizada.'
          );

        Conn.Commit;

      except
        if Conn.InTransaction then
          Conn.Rollback;

        Result.Free;
        Result := nil;

        raise;
      end;

    finally
      TurmaAtual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

end.
