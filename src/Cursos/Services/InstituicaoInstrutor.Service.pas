unit InstituicaoInstrutor.Service;

interface

uses
  InstituicaoInstrutor.Model;

type
  TInstituicaoInstrutorService = class
  private
    class function GerarCodigoPublico: string; static;

    class procedure ValidarNome(
      const ANome: string
    ); static;

    class procedure ValidarEmail(
      const AEmail: string
    ); static;

    class procedure ValidarTelefone(
      const ATelefone: string
    ); static;

    class procedure ValidarSituacao(
      const ASituacao: string
    ); static;

  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoInstrutorLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdInstrutor: Int64
    ): TInstituicaoInstrutorItem; static;

    class function Cadastrar(
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoInstrutorCadastro
    ): TInstituicaoInstrutorItem; static;

    class function Atualizar(
      const AIdInstituicao,
            AIdInstrutor: Int64;
      const ADados: TInstituicaoInstrutorAlteracao
    ): TInstituicaoInstrutorItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdInstrutor: Int64;
      const ASituacao: string
    ): TInstituicaoInstrutorItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoInstrutor.DAO;

class function TInstituicaoInstrutorService.GerarCodigoPublico: string;
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

class procedure TInstituicaoInstrutorService.ValidarNome(
  const ANome: string
);
begin
  if Trim(ANome).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome do instrutor.'
    );

  if Length(Trim(ANome)) > 180 then
    TAppErrors.RaiseBadRequest(
      'O nome do instrutor deve possuir no máximo 180 caracteres.'
    );
end;

class procedure TInstituicaoInstrutorService.ValidarEmail(
  const AEmail: string
);
var
  Email: string;
begin
  Email := Trim(AEmail);

  if Email.IsEmpty then
    Exit;

  if Length(Email) > 254 then
    TAppErrors.RaiseBadRequest(
      'O e-mail deve possuir no máximo 254 caracteres.'
    );

  if Pos('@', Email) <= 1 then
    TAppErrors.RaiseBadRequest(
      'Informe um e-mail válido.'
    );
end;

class procedure TInstituicaoInstrutorService.ValidarTelefone(
  const ATelefone: string
);
begin
  if Length(Trim(ATelefone)) > 30 then
    TAppErrors.RaiseBadRequest(
      'O telefone deve possuir no máximo 30 caracteres.'
    );
end;

class procedure TInstituicaoInstrutorService.ValidarSituacao(
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

class function TInstituicaoInstrutorService.Listar(
  const AIdInstituicao: Int64;
  const ABusca,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoInstrutorLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoInstrutorFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro :=
    Default(
      TInstituicaoInstrutorFiltro
    );

  Filtro.Busca :=
    Trim(ABusca);

  Filtro.Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

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
      TInstituicaoInstrutorDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoInstrutorService.BuscarPorId(
  const AIdInstituicao,
        AIdInstrutor: Int64
): TInstituicaoInstrutorItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdInstrutor <= 0 then
    TAppErrors.RaiseBadRequest(
      'Instrutor inválido.'
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
      TInstituicaoInstrutorDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdInstrutor
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Instrutor não encontrado.'
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoInstrutorService.Cadastrar(
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoInstrutorCadastro
): TInstituicaoInstrutorItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoInstrutorCadastro;
  CodigoPublico: string;
  IdInstrutor: Int64;
  Tentativas: Integer;
  CodigoDisponivel: Boolean;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Dados := ADados;

  Dados.Nome :=
    Trim(Dados.Nome);

  Dados.Email :=
    LowerCase(
      Trim(Dados.Email)
    );

  Dados.Telefone :=
    Trim(Dados.Telefone);

  Dados.Biografia :=
    Trim(Dados.Biografia);

  ValidarNome(
    Dados.Nome
  );

  ValidarEmail(
    Dados.Email
  );

  ValidarTelefone(
    Dados.Telefone
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
    if Dados.IdParticipante > 0 then
    begin
      if not TInstituicaoInstrutorDAO.ExisteParticipanteAtivo(
        Conn,
        AIdInstituicao,
        Dados.IdParticipante
      ) then
        TAppErrors.RaiseBadRequest(
          'Participante não encontrado, não pertence à instituição ou está inativo.'
        );

      if TInstituicaoInstrutorDAO.ParticipanteJaVinculado(
        Conn,
        AIdInstituicao,
        Dados.IdParticipante
      ) then
        TAppErrors.RaiseBadRequest(
          'Este participante já está vinculado a outro instrutor.'
        );
    end;

    Tentativas := 0;
    CodigoDisponivel := False;

    repeat
      Inc(Tentativas);

      CodigoPublico :=
        GerarCodigoPublico;

      CodigoDisponivel :=
        not TInstituicaoInstrutorDAO.ExisteCodigoPublico(
          Conn,
          CodigoPublico
        );

    until
      CodigoDisponivel or
      (Tentativas >= 5);

    if not CodigoDisponivel then
      raise Exception.Create(
        'Não foi possível gerar um código público único para o instrutor.'
      );

    Conn.StartTransaction;
    try
      IdInstrutor :=
        TInstituicaoInstrutorDAO.Inserir(
          Conn,
          AIdInstituicao,
          CodigoPublico,
          Dados
        );

      Result :=
        TInstituicaoInstrutorDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          IdInstrutor
        );

      if Result = nil then
        raise Exception.Create(
          'Instrutor cadastrado, mas não foi possível recuperar os dados.'
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

class function TInstituicaoInstrutorService.Atualizar(
  const AIdInstituicao,
        AIdInstrutor: Int64;
  const ADados: TInstituicaoInstrutorAlteracao
): TInstituicaoInstrutorItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoInstrutorAlteracao;
  InstrutorAtual: TInstituicaoInstrutorItem;
  MudouParticipante: Boolean;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdInstrutor <= 0 then
    TAppErrors.RaiseBadRequest(
      'Instrutor inválido.'
    );

  Dados := ADados;

  Dados.Nome :=
    Trim(Dados.Nome);

  Dados.Email :=
    LowerCase(
      Trim(Dados.Email)
    );

  Dados.Telefone :=
    Trim(Dados.Telefone);

  Dados.Biografia :=
    Trim(Dados.Biografia);

  ValidarNome(
    Dados.Nome
  );

  ValidarEmail(
    Dados.Email
  );

  ValidarTelefone(
    Dados.Telefone
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
    InstrutorAtual :=
      TInstituicaoInstrutorDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdInstrutor
      );

    try
      if InstrutorAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Instrutor não encontrado.'
        );

      MudouParticipante :=
        (Dados.IdParticipante <> InstrutorAtual.IdParticipante) or
        ((Dados.IdParticipante > 0) <> InstrutorAtual.TemParticipante);

      if
        MudouParticipante and
        (Dados.IdParticipante > 0)
      then
      begin
        if not TInstituicaoInstrutorDAO.ExisteParticipanteAtivo(
          Conn,
          AIdInstituicao,
          Dados.IdParticipante
        ) then
          TAppErrors.RaiseBadRequest(
            'Participante não encontrado, não pertence à instituição ou está inativo.'
          );

        if TInstituicaoInstrutorDAO.ParticipanteJaVinculado(
          Conn,
          AIdInstituicao,
          Dados.IdParticipante,
          AIdInstrutor
        ) then
          TAppErrors.RaiseBadRequest(
            'Este participante já está vinculado a outro instrutor.'
          );
      end;

      Conn.StartTransaction;
      try
        TInstituicaoInstrutorDAO.Atualizar(
          Conn,
          AIdInstituicao,
          AIdInstrutor,
          Dados
        );

        Result :=
          TInstituicaoInstrutorDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdInstrutor
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar o instrutor atualizado.'
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
      InstrutorAtual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoInstrutorService.AlterarSituacao(
  const AIdInstituicao,
        AIdInstrutor: Int64;
  const ASituacao: string
): TInstituicaoInstrutorItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  InstrutorAtual: TInstituicaoInstrutorItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdInstrutor <= 0 then
    TAppErrors.RaiseBadRequest(
      'Instrutor inválido.'
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
    InstrutorAtual :=
      TInstituicaoInstrutorDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdInstrutor
      );

    try
      if InstrutorAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Instrutor não encontrado.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoInstrutorDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AIdInstrutor,
          Situacao
        );

        Result :=
          TInstituicaoInstrutorDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdInstrutor
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar o instrutor atualizado.'
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
      InstrutorAtual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

end.
