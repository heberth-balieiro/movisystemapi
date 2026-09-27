unit InstituicaoPresenca.Service;

interface

uses
  System.Generics.Collections,
  InstituicaoPresenca.Model;

type
  TInstituicaoPresencaService = class
  private
    class procedure ValidarSituacao(
      const ASituacao: string
    ); static;

    class procedure ValidarRegistro(
      const ADados: TInstituicaoPresencaRegistro
    ); static;

  public
    class function ListarPorEncontro(
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro: Int64;
      const ABusca,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoPresencaLista; static;

    class function Salvar(
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro,
            ARegistradoPor: Int64;
      const ADados: TInstituicaoPresencaRegistro
    ): TInstituicaoPresencaItem; static;

    class procedure SalvarLote(
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro,
            ARegistradoPor: Int64;
      const AItens: TInstituicaoPresencaRegistroLista
    ); static;

    class function ListarPorInscricao(
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TObjectList<TInstituicaoPresencaItem>; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPresenca.DAO;

class procedure TInstituicaoPresencaService.ValidarSituacao(
  const ASituacao: string
);
begin
  if not MatchText(
    UpperCase(
      Trim(
        ASituacao
      )
    ),
    [
      'PRESENTE',
      'AUSENTE',
      'JUSTIFICADA',
      'PARCIAL'
    ]
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação de presença inválida.'
    );
end;

class procedure TInstituicaoPresencaService.ValidarRegistro(
  const ADados: TInstituicaoPresencaRegistro
);
begin
  if ADados.IdInscricao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Inscrição inválida.'
    );

  ValidarSituacao(
    ADados.Situacao
  );

  if
    ADados.TemCheckinEm and
    ADados.TemCheckoutEm and
    (ADados.CheckoutEm < ADados.CheckinEm)
  then
    TAppErrors.RaiseBadRequest(
      'O checkout não pode ser anterior ao check-in.'
    );

  if
    ADados.TemMinutosPresentes and
    (ADados.MinutosPresentes < 0)
  then
    TAppErrors.RaiseBadRequest(
      'Os minutos presentes não podem ser negativos.'
    );

  if Length(
    Trim(
      ADados.Justificativa
    )
  ) > 500 then
    TAppErrors.RaiseBadRequest(
      'A justificativa deve possuir no máximo 500 caracteres.'
    );
end;

class function TInstituicaoPresencaService.ListarPorEncontro(
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro: Int64;
  const ABusca,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoPresencaLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoPresencaFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if (AIdTurma <= 0) or
     (AIdEncontro <= 0) then
    TAppErrors.RaiseBadRequest(
      'Encontro inválido.'
    );

  Filtro :=
    Default(
      TInstituicaoPresencaFiltro
    );

  Filtro.Busca :=
    Trim(
      ABusca
    );

  Filtro.Situacao :=
    UpperCase(
      Trim(
        ASituacao
      )
    );

  Filtro.Pagina :=
    APagina;

  Filtro.PorPagina :=
    APorPagina;

  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 50;

  if Filtro.PorPagina > 200 then
    Filtro.PorPagina := 200;

  if not Filtro.Situacao.IsEmpty then
  begin
    if not SameText(
      Filtro.Situacao,
      'SEM_REGISTRO'
    ) then
      ValidarSituacao(
        Filtro.Situacao
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
    if not TInstituicaoPresencaDAO.EncontroExiste(
      Conn,
      AIdInstituicao,
      AIdTurma,
      AIdEncontro
    ) then
      TAppErrors.RaiseBadRequest(
        'Encontro não encontrado.'
      );

    Result :=
      TInstituicaoPresencaDAO.ListarPorEncontro(
        Conn,
        AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        Filtro
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoPresencaService.Salvar(
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        ARegistradoPor: Int64;
  const ADados: TInstituicaoPresencaRegistro
): TInstituicaoPresencaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoPresencaRegistro;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if ARegistradoPor <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if (AIdTurma <= 0) or
     (AIdEncontro <= 0) then
    TAppErrors.RaiseBadRequest(
      'Encontro inválido.'
    );

  Dados := ADados;

  Dados.Situacao :=
    UpperCase(
      Trim(
        Dados.Situacao
      )
    );

  Dados.Justificativa :=
    Trim(
      Dados.Justificativa
    );

  ValidarRegistro(
    Dados
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
    if not TInstituicaoPresencaDAO.EncontroExiste(
      Conn,
      AIdInstituicao,
      AIdTurma,
      AIdEncontro
    ) then
      TAppErrors.RaiseBadRequest(
        'Encontro não encontrado.'
      );

    if not TInstituicaoPresencaDAO.InscricaoExisteNaTurma(
      Conn,
      AIdInstituicao,
      AIdTurma,
      Dados.IdInscricao
    ) then
      TAppErrors.RaiseBadRequest(
        'Inscrição não encontrada nesta turma.'
      );

    Conn.StartTransaction;

    try
      TInstituicaoPresencaDAO.Salvar(
        Conn,
        AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        ARegistradoPor,
        Dados
      );

      Result :=
        TInstituicaoPresencaDAO.BuscarRegistro(
          Conn,
          AIdInstituicao,
          AIdTurma,
          AIdEncontro,
          Dados.IdInscricao
        );

      if Result = nil then
        raise Exception.Create(
          'Presença salva, mas não foi possível recuperar o registro.'
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

class procedure TInstituicaoPresencaService.SalvarLote(
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        ARegistradoPor: Int64;
  const AItens: TInstituicaoPresencaRegistroLista
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  I: Integer;
  Item: TInstituicaoPresencaRegistro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if ARegistradoPor <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if (AIdTurma <= 0) or
     (AIdEncontro <= 0) then
    TAppErrors.RaiseBadRequest(
      'Encontro inválido.'
    );

  if (AItens = nil) or
     (AItens.Count = 0) then
    TAppErrors.RaiseBadRequest(
      'Informe ao menos um registro de presença.'
    );

  for I := 0 to AItens.Count - 1 do
  begin
    Item :=
      AItens[I];

    Item.Situacao :=
      UpperCase(
        Trim(
          Item.Situacao
        )
      );

    Item.Justificativa :=
      Trim(
        Item.Justificativa
      );

    AItens[I] :=
      Item;

    ValidarRegistro(
      Item
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
    if not TInstituicaoPresencaDAO.EncontroExiste(
      Conn,
      AIdInstituicao,
      AIdTurma,
      AIdEncontro
    ) then
      TAppErrors.RaiseBadRequest(
        'Encontro não encontrado.'
      );

    for I := 0 to AItens.Count - 1 do
    begin
      if not TInstituicaoPresencaDAO.InscricaoExisteNaTurma(
        Conn,
        AIdInstituicao,
        AIdTurma,
        AItens[I].IdInscricao
      ) then
        TAppErrors.RaiseBadRequest(
          'Uma das inscrições informadas não pertence à turma.'
        );
    end;

    Conn.StartTransaction;

    try
      for I := 0 to AItens.Count - 1 do
      begin
        TInstituicaoPresencaDAO.Salvar(
          Conn,
          AIdInstituicao,
          AIdTurma,
          AIdEncontro,
          ARegistradoPor,
          AItens[I]
        );
      end;

      Conn.Commit;

    except
      if Conn.InTransaction then
        Conn.Rollback;

      raise;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoPresencaService.ListarPorInscricao(
  const AIdInstituicao,
        AIdInscricao: Int64
): TObjectList<TInstituicaoPresencaItem>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Inscrição inválida.'
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
      TInstituicaoPresencaDAO.ListarPorInscricao(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

  finally
    Conn.Free;
  end;
end;

end.
