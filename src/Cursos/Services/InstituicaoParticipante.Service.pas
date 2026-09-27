unit InstituicaoParticipante.Service;

interface

uses
  InstituicaoParticipante.Model;

type
  TInstituicaoParticipanteService = class
  private
    class function GerarCodigoPublico: string; static;

    class procedure ValidarNome(
      const ANome: string
    ); static;

    class procedure ValidarEmail(
      const AEmail: string
    ); static;

    class procedure ValidarCampos(
      const AMatricula,
            ATelefone,
            AOrgaoEmpresa,
            ACargo: string
    ); static;

    class procedure ValidarSituacaoFiltro(
      const ASituacao: string
    ); static;

    class procedure ValidarSituacaoAlteracao(
      const ASituacao: string
    ); static;

  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoParticipanteLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdParticipante: Int64
    ): TInstituicaoParticipanteItem; static;

    class function Cadastrar(
      const AIdInstituicao,
            ACriadoPor: Int64;
      const ADados: TInstituicaoParticipanteCadastro
    ): TInstituicaoParticipanteItem; static;

    class function Atualizar(
      const AIdInstituicao,
            AIdParticipante: Int64;
      const ADados: TInstituicaoParticipanteAlteracao
    ): TInstituicaoParticipanteItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdParticipante: Int64;
      const ASituacao: string
    ): TInstituicaoParticipanteItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  App.ParticipanteSecurity,
  Database.Connection,
  InstituicaoParticipante.DAO;

class function TInstituicaoParticipanteService.GerarCodigoPublico: string;
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

class procedure TInstituicaoParticipanteService.ValidarNome(
  const ANome: string
);
begin
  if Trim(ANome).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome do participante.'
    );

  if Length(Trim(ANome)) > 180 then
    TAppErrors.RaiseBadRequest(
      'O nome deve possuir no máximo 180 caracteres.'
    );
end;

class procedure TInstituicaoParticipanteService.ValidarEmail(
  const AEmail: string
);
begin
  if Trim(AEmail).IsEmpty then
    Exit;

  if Length(Trim(AEmail)) > 254 then
    TAppErrors.RaiseBadRequest(
      'O e-mail deve possuir no máximo 254 caracteres.'
    );

  if Pos('@', Trim(AEmail)) <= 1 then
    TAppErrors.RaiseBadRequest(
      'Informe um e-mail válido.'
    );
end;

class procedure TInstituicaoParticipanteService.ValidarCampos(
  const AMatricula,
        ATelefone,
        AOrgaoEmpresa,
        ACargo: string
);
begin
  if Length(Trim(AMatricula)) > 80 then
    TAppErrors.RaiseBadRequest(
      'A matrícula deve possuir no máximo 80 caracteres.'
    );

  if Length(Trim(ATelefone)) > 30 then
    TAppErrors.RaiseBadRequest(
      'O telefone deve possuir no máximo 30 caracteres.'
    );

  if Length(Trim(AOrgaoEmpresa)) > 180 then
    TAppErrors.RaiseBadRequest(
      'O órgão/empresa deve possuir no máximo 180 caracteres.'
    );

  if Length(Trim(ACargo)) > 120 then
    TAppErrors.RaiseBadRequest(
      'O cargo deve possuir no máximo 120 caracteres.'
    );
end;

class procedure TInstituicaoParticipanteService.ValidarSituacaoFiltro(
  const ASituacao: string
);
begin
  if not MatchText(
    UpperCase(Trim(ASituacao)),
    ['ATIVO', 'INATIVO', 'ANONIMIZADO']
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação inválida.'
    );
end;

class procedure TInstituicaoParticipanteService.ValidarSituacaoAlteracao(
  const ASituacao: string
);
begin
  if not MatchText(
    UpperCase(Trim(ASituacao)),
    ['ATIVO', 'INATIVO']
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação inválida. Utilize ATIVO ou INATIVO.'
    );
end;

class function TInstituicaoParticipanteService.Listar(
  const AIdInstituicao: Int64;
  const ABusca,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoParticipanteLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoParticipanteFiltro;
  BuscaCpf: string;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro :=
    Default(
      TInstituicaoParticipanteFiltro
    );

  Filtro.Busca :=
    Trim(ABusca);

  Filtro.Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

  Filtro.Pagina :=
    APagina;

  Filtro.PorPagina :=
    APorPagina;

  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 20;

  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  if not Filtro.Situacao.IsEmpty then
    ValidarSituacaoFiltro(
      Filtro.Situacao
    );

  BuscaCpf :=
    TParticipanteSecurity.NormalizarCpf(
      Filtro.Busca
    );

  if Length(BuscaCpf) = 11 then
  begin
    if TParticipanteSecurity.CpfValido(
      BuscaCpf
    ) then
      Filtro.CpfHashBusca :=
        TParticipanteSecurity.GerarCpfHashBusca(
          BuscaCpf
        );
  end;

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
      TInstituicaoParticipanteDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoParticipanteService.BuscarPorId(
  const AIdInstituicao,
        AIdParticipante: Int64
): TInstituicaoParticipanteItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest(
      'Participante inválido.'
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
      TInstituicaoParticipanteDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Participante não encontrado.'
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoParticipanteService.Cadastrar(
  const AIdInstituicao,
        ACriadoPor: Int64;
  const ADados: TInstituicaoParticipanteCadastro
): TInstituicaoParticipanteItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoParticipanteCadastro;
  CodigoPublico: string;
  CodigoDisponivel: Boolean;
  Tentativas: Integer;
  CpfNormalizado: string;
  CpfHashBusca: string;
  CpfMascarado: string;
  IdParticipante: Int64;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if ACriadoPor <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  Dados := ADados;

  Dados.Nome :=
    Trim(Dados.Nome);

  Dados.Cpf :=
    Trim(Dados.Cpf);

  Dados.Email :=
    Trim(Dados.Email);

  Dados.Matricula :=
    Trim(Dados.Matricula);

  Dados.Telefone :=
    Trim(Dados.Telefone);

  Dados.OrgaoEmpresa :=
    Trim(Dados.OrgaoEmpresa);

  Dados.Cargo :=
    Trim(Dados.Cargo);

  ValidarNome(
    Dados.Nome
  );

  ValidarEmail(
    Dados.Email
  );

  ValidarCampos(
    Dados.Matricula,
    Dados.Telefone,
    Dados.OrgaoEmpresa,
    Dados.Cargo
  );

  CpfHashBusca := '';
  CpfMascarado := '';

  if not Dados.Cpf.IsEmpty then
  begin
    CpfNormalizado :=
      TParticipanteSecurity.NormalizarCpf(
        Dados.Cpf
      );

    if not TParticipanteSecurity.CpfValido(
      CpfNormalizado
    ) then
      TAppErrors.RaiseBadRequest(
        'Informe um CPF válido.'
      );

    CpfHashBusca :=
      TParticipanteSecurity.GerarCpfHashBusca(
        CpfNormalizado
      );

    CpfMascarado :=
      TParticipanteSecurity.MascararCpf(
        CpfNormalizado
      );
  end;

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
    if Dados.IdUnidadeOrganizacional > 0 then
    begin
      if not TInstituicaoParticipanteDAO.UnidadeAtivaExiste(
        Conn,
        AIdInstituicao,
        Dados.IdUnidadeOrganizacional
      ) then
        TAppErrors.RaiseBadRequest(
          'Unidade organizacional não encontrada ou inativa.'
        );
    end;

    if Dados.IdUsuarioInstituicao > 0 then
    begin
      if not TInstituicaoParticipanteDAO.UsuarioInstituicaoAtivoExiste(
        Conn,
        AIdInstituicao,
        Dados.IdUsuarioInstituicao
      ) then
        TAppErrors.RaiseBadRequest(
          'Usuário da instituição não encontrado ou inativo.'
        );

      if TInstituicaoParticipanteDAO.UsuarioJaVinculado(
        Conn,
        AIdInstituicao,
        Dados.IdUsuarioInstituicao
      ) then
        TAppErrors.RaiseBadRequest(
          'Este usuário já está vinculado a outro participante.'
        );
    end;

    if not CpfHashBusca.IsEmpty then
    begin
      if TInstituicaoParticipanteDAO.ExisteCpfHash(
        Conn,
        AIdInstituicao,
        CpfHashBusca
      ) then
        TAppErrors.RaiseBadRequest(
          'Já existe participante cadastrado com este CPF.'
        );
    end;

    if not Dados.Matricula.IsEmpty then
    begin
      if TInstituicaoParticipanteDAO.ExisteMatricula(
        Conn,
        AIdInstituicao,
        Dados.Matricula
      ) then
        TAppErrors.RaiseBadRequest(
          'Já existe participante cadastrado com esta matrícula.'
        );
    end;

    Tentativas := 0;
    CodigoDisponivel := False;

    repeat
      Inc(Tentativas);

      CodigoPublico :=
        GerarCodigoPublico;

      CodigoDisponivel :=
        not TInstituicaoParticipanteDAO.ExisteCodigoPublico(
          Conn,
          CodigoPublico
        );

    until
      CodigoDisponivel or
      (Tentativas >= 5);

    if not CodigoDisponivel then
      raise Exception.Create(
        'Não foi possível gerar um código público único para o participante.'
      );

    Conn.StartTransaction;

    try
      IdParticipante :=
        TInstituicaoParticipanteDAO.Inserir(
          Conn,
          AIdInstituicao,
          ACriadoPor,
          CodigoPublico,
          CpfHashBusca,
          CpfMascarado,
          Dados
        );

      Result :=
        TInstituicaoParticipanteDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          IdParticipante
        );

      if Result = nil then
        raise Exception.Create(
          'Participante cadastrado, mas não foi possível recuperar os dados.'
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

class function TInstituicaoParticipanteService.Atualizar(
  const AIdInstituicao,
        AIdParticipante: Int64;
  const ADados: TInstituicaoParticipanteAlteracao
): TInstituicaoParticipanteItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoParticipanteAlteracao;
  Atual: TInstituicaoParticipanteItem;
  CpfNormalizado: string;
  CpfHashBusca: string;
  CpfMascarado: string;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest(
      'Participante inválido.'
    );

  Dados := ADados;

  Dados.Nome :=
    Trim(Dados.Nome);

  Dados.Cpf :=
    Trim(Dados.Cpf);

  Dados.Email :=
    Trim(Dados.Email);

  Dados.Matricula :=
    Trim(Dados.Matricula);

  Dados.Telefone :=
    Trim(Dados.Telefone);

  Dados.OrgaoEmpresa :=
    Trim(Dados.OrgaoEmpresa);

  Dados.Cargo :=
    Trim(Dados.Cargo);

  ValidarNome(
    Dados.Nome
  );

  ValidarEmail(
    Dados.Email
  );

  ValidarCampos(
    Dados.Matricula,
    Dados.Telefone,
    Dados.OrgaoEmpresa,
    Dados.Cargo
  );

  CpfHashBusca := '';
  CpfMascarado := '';

  if Dados.TemCpfInformado then
  begin
    CpfNormalizado :=
      TParticipanteSecurity.NormalizarCpf(
        Dados.Cpf
      );

    if not TParticipanteSecurity.CpfValido(
      CpfNormalizado
    ) then
      TAppErrors.RaiseBadRequest(
        'Informe um CPF válido.'
      );

    CpfHashBusca :=
      TParticipanteSecurity.GerarCpfHashBusca(
        CpfNormalizado
      );

    CpfMascarado :=
      TParticipanteSecurity.MascararCpf(
        CpfNormalizado
      );
  end;

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
    Atual :=
      TInstituicaoParticipanteDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest(
          'Participante não encontrado.'
        );

      if SameText(
        Atual.Situacao,
        'ANONIMIZADO'
      ) then
        TAppErrors.RaiseBadRequest(
          'Participante anonimizado não pode ser alterado.'
        );

      if Dados.IdUnidadeOrganizacional > 0 then
      begin
        if
          (not Atual.TemUnidadeOrganizacional) or
          (Atual.IdUnidadeOrganizacional <>
           Dados.IdUnidadeOrganizacional)
        then
        begin
          if not TInstituicaoParticipanteDAO.UnidadeAtivaExiste(
            Conn,
            AIdInstituicao,
            Dados.IdUnidadeOrganizacional
          ) then
            TAppErrors.RaiseBadRequest(
              'Unidade organizacional não encontrada ou inativa.'
            );
        end;
      end;

      if Dados.IdUsuarioInstituicao > 0 then
      begin
        if
          (not Atual.TemUsuarioInstituicao) or
          (Atual.IdUsuarioInstituicao <>
           Dados.IdUsuarioInstituicao)
        then
        begin
          if not TInstituicaoParticipanteDAO.UsuarioInstituicaoAtivoExiste(
            Conn,
            AIdInstituicao,
            Dados.IdUsuarioInstituicao
          ) then
            TAppErrors.RaiseBadRequest(
              'Usuário da instituição não encontrado ou inativo.'
            );
        end;

        if TInstituicaoParticipanteDAO.UsuarioJaVinculado(
          Conn,
          AIdInstituicao,
          Dados.IdUsuarioInstituicao,
          AIdParticipante
        ) then
          TAppErrors.RaiseBadRequest(
            'Este usuário já está vinculado a outro participante.'
          );
      end;

      if Dados.TemCpfInformado then
      begin
        if TInstituicaoParticipanteDAO.ExisteCpfHash(
          Conn,
          AIdInstituicao,
          CpfHashBusca,
          AIdParticipante
        ) then
          TAppErrors.RaiseBadRequest(
            'Já existe participante cadastrado com este CPF.'
          );
      end;

      if not Dados.Matricula.IsEmpty then
      begin
        if TInstituicaoParticipanteDAO.ExisteMatricula(
          Conn,
          AIdInstituicao,
          Dados.Matricula,
          AIdParticipante
        ) then
          TAppErrors.RaiseBadRequest(
            'Já existe participante cadastrado com esta matrícula.'
          );
      end;

      Conn.StartTransaction;

      try
        TInstituicaoParticipanteDAO.Atualizar(
          Conn,
          AIdInstituicao,
          AIdParticipante,
          Dados.TemCpfInformado,
          CpfHashBusca,
          CpfMascarado,
          Dados
        );

        Result :=
          TInstituicaoParticipanteDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdParticipante
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar o participante atualizado.'
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
      Atual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoParticipanteService.AlterarSituacao(
  const AIdInstituicao,
        AIdParticipante: Int64;
  const ASituacao: string
): TInstituicaoParticipanteItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  Atual: TInstituicaoParticipanteItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdParticipante <= 0 then
    TAppErrors.RaiseBadRequest(
      'Participante inválido.'
    );

  Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

  ValidarSituacaoAlteracao(
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
    Atual :=
      TInstituicaoParticipanteDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdParticipante
      );

    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest(
          'Participante não encontrado.'
        );

      if SameText(
        Atual.Situacao,
        'ANONIMIZADO'
      ) then
        TAppErrors.RaiseBadRequest(
          'Participante anonimizado não pode ter sua situação alterada.'
        );

      Conn.StartTransaction;

      try
        TInstituicaoParticipanteDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AIdParticipante,
          Situacao
        );

        Result :=
          TInstituicaoParticipanteDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdParticipante
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar o participante atualizado.'
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
      Atual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

end.
