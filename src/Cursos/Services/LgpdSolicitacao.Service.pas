unit LgpdSolicitacao.Service;

interface

uses
  LgpdSolicitacao.Model;

type
  TLgpdSolicitacaoService = class
  private
    class procedure ValidarTipo(
      const ATipo: string
    ); static;

    class function GerarProtocolo(
      const AIdInstituicao: Int64
    ): string; static;

  public
    class function Solicitar(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ATipo,
            ADescricao: string
    ): TLgpdSolicitacaoItem; static;

    class function ListarMinhas(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TLgpdSolicitacaoResultado; static;

    class function CancelarMinha(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AId: Int64
    ): TLgpdSolicitacaoItem; static;

    class function ListarInstituicao(
      const AIdInstituicao: Int64;
      const ABusca,
            ATipo,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TLgpdSolicitacaoResultado; static;

    class function AtualizarInstituicao(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AId: Int64;
      const ASituacao,
            AResposta: string
    ): TLgpdSolicitacaoItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  LgpdSolicitacao.DAO;

class procedure TLgpdSolicitacaoService.ValidarTipo(
  const ATipo: string
);
begin
  if not MatchText(
    UpperCase(Trim(ATipo)),
    [
      'ACESSO',
      'CORRECAO',
      'ANONIMIZACAO',
      'EXCLUSAO',
      'PORTABILIDADE',
      'REVOGACAO',
      'OUTRO'
    ]
  ) then
    TAppErrors.RaiseBadRequest(
      'Tipo de solicitação LGPD inválido.'
    );
end;

class function TLgpdSolicitacaoService.GerarProtocolo(
  const AIdInstituicao: Int64
): string;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  G: TGUID;
  Raw: string;
  Tentativa: Integer;
begin
  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    for Tentativa := 1 to 10 do
    begin
      CreateGUID(G);
      Raw := GUIDToString(G);
      Raw := StringReplace(Raw, '{', '', [rfReplaceAll]);
      Raw := StringReplace(Raw, '}', '', [rfReplaceAll]);
      Raw := StringReplace(Raw, '-', '', [rfReplaceAll]);

      Result :=
        'LGPD-' +
        UpperCase(
          Copy(Raw, 1, 24)
        );

      if not TLgpdSolicitacaoDAO.ExisteProtocolo(
        Conn,
        AIdInstituicao,
        Result
      ) then
        Exit;
    end;
  finally
    Conn.Free;
  end;

  raise Exception.Create(
    'Não foi possível gerar o protocolo LGPD.'
  );
end;

class function TLgpdSolicitacaoService.Solicitar(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ATipo,
        ADescricao: string
): TLgpdSolicitacaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  IdParticipante: Int64;
  IdSolicitacao: Int64;
  Tipo: string;
  Protocolo: string;
begin
  Result := nil;

  if (AIdInstituicao <= 0) or
     (AIdUsuarioInstituicao <= 0) then
    TAppErrors.RaiseUnauthorized(
      'Participante não identificado.'
    );

  Tipo := UpperCase(Trim(ATipo));
  ValidarTipo(Tipo);

  if Length(Trim(ADescricao)) > 4000 then
    TAppErrors.RaiseBadRequest(
      'A descrição deve possuir no máximo 4000 caracteres.'
    );

  if (Tipo = 'OUTRO') and
     Trim(ADescricao).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Descreva a solicitação.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    IdParticipante :=
      TLgpdSolicitacaoDAO.BuscarParticipantePorUsuario(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao
      );

    if IdParticipante <= 0 then
      TAppErrors.RaiseForbidden(
        'Participante ativo não localizado para este usuário.'
      );

    if TLgpdSolicitacaoDAO.ExistePendenteMesmoTipo(
      Conn,
      AIdInstituicao,
      IdParticipante,
      Tipo
    ) then
      TAppErrors.RaiseBadRequest(
        'Já existe uma solicitação deste tipo em aberto ou em análise.'
      );

    Protocolo :=
      GerarProtocolo(
        AIdInstituicao
      );

    Conn.StartTransaction;
    try
      IdSolicitacao :=
        TLgpdSolicitacaoDAO.Inserir(
          Conn,
          AIdInstituicao,
          IdParticipante,
          Protocolo,
          Tipo,
          ADescricao
        );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Result :=
      TLgpdSolicitacaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        IdSolicitacao
      );
  finally
    Conn.Free;
  end;
end;

class function TLgpdSolicitacaoService.ListarMinhas(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TLgpdSolicitacaoResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  IdParticipante: Int64;
begin
  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    IdParticipante :=
      TLgpdSolicitacaoDAO.BuscarParticipantePorUsuario(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao
      );

    if IdParticipante <= 0 then
      TAppErrors.RaiseForbidden(
        'Participante ativo não localizado para este usuário.'
      );

    Result :=
      TLgpdSolicitacaoDAO.ListarDoParticipante(
        Conn,
        AIdInstituicao,
        IdParticipante
      );
  finally
    Conn.Free;
  end;
end;

class function TLgpdSolicitacaoService.CancelarMinha(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AId: Int64
): TLgpdSolicitacaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  IdParticipante: Int64;
begin
  if AId <= 0 then
    TAppErrors.RaiseBadRequest(
      'Solicitação inválida.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    IdParticipante :=
      TLgpdSolicitacaoDAO.BuscarParticipantePorUsuario(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao
      );

    if IdParticipante <= 0 then
      TAppErrors.RaiseForbidden(
        'Participante ativo não localizado para este usuário.'
      );

    TLgpdSolicitacaoDAO.CancelarDoParticipante(
      Conn,
      AIdInstituicao,
      IdParticipante,
      AId
    );

    Result :=
      TLgpdSolicitacaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AId
      );
  finally
    Conn.Free;
  end;
end;

class function TLgpdSolicitacaoService.ListarInstituicao(
  const AIdInstituicao: Int64;
  const ABusca,
        ATipo,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TLgpdSolicitacaoResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TLgpdSolicitacaoFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro := Default(TLgpdSolicitacaoFiltro);
  Filtro.Busca := Trim(ABusca);
  Filtro.Tipo := UpperCase(Trim(ATipo));
  Filtro.Situacao := UpperCase(Trim(ASituacao));

  if not Filtro.Tipo.IsEmpty then
    ValidarTipo(Filtro.Tipo);

  if not Filtro.Situacao.IsEmpty and
     not MatchText(
       Filtro.Situacao,
       ['ABERTA', 'EM_ANALISE', 'ATENDIDA', 'NEGADA', 'CANCELADA']
     ) then
    TAppErrors.RaiseBadRequest(
      'Situação LGPD inválida.'
    );

  Filtro.Pagina := APagina;
  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  Filtro.PorPagina := APorPagina;
  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 50;

  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Result :=
      TLgpdSolicitacaoDAO.ListarInstituicao(
        Conn,
        AIdInstituicao,
        Filtro
      );
  finally
    Conn.Free;
  end;
end;

class function TLgpdSolicitacaoService.AtualizarInstituicao(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AId: Int64;
  const ASituacao,
        AResposta: string
): TLgpdSolicitacaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  Atual: TLgpdSolicitacaoItem;
begin
  Result := nil;

  if (AIdInstituicao <= 0) or
     (AIdUsuarioInstituicao <= 0) then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if AId <= 0 then
    TAppErrors.RaiseBadRequest(
      'Solicitação inválida.'
    );

  Situacao := UpperCase(Trim(ASituacao));

  if not MatchText(
    Situacao,
    ['EM_ANALISE', 'ATENDIDA', 'NEGADA', 'CANCELADA']
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação de atendimento inválida.'
    );

  if Length(Trim(AResposta)) > 8000 then
    TAppErrors.RaiseBadRequest(
      'A resposta deve possuir no máximo 8000 caracteres.'
    );

  if MatchText(Situacao, ['ATENDIDA', 'NEGADA']) and
     Trim(AResposta).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe a resposta ao titular antes de concluir a solicitação.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Atual :=
      TLgpdSolicitacaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AId
      );
    try
      if Atual = nil then
        TAppErrors.RaiseNotFound(
          'Solicitação LGPD não encontrada.'
        );

      if MatchText(
        Atual.Situacao,
        ['ATENDIDA', 'NEGADA', 'CANCELADA']
      ) then
        TAppErrors.RaiseBadRequest(
          'A solicitação já está concluída.'
        );
    finally
      Atual.Free;
    end;

    Conn.StartTransaction;
    try
      TLgpdSolicitacaoDAO.AtualizarAnalise(
        Conn,
        AIdInstituicao,
        AId,
        AIdUsuarioInstituicao,
        Situacao,
        AResposta
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Result :=
      TLgpdSolicitacaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AId
      );
  finally
    Conn.Free;
  end;
end;

end.
