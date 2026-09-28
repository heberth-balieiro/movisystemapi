unit AlunoPortal.Service;

interface

uses
  Uni,
  AlunoPortal.Model;

type
  TAlunoPortalService = class
  private
    class function NovaConexao: TUniConnection; static;
    class function ResolverAluno(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TAlunoContexto; static;

  public
    class function MeuPerfil(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TAlunoContexto; static;

    class function Dashboard(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TAlunoDashboard; static;

    class function ListarInscricoes(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TAlunoInscricaoLista; static;

    class function BuscarInscricao(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdInscricao: Int64
    ): TAlunoInscricaoItem; static;

    class function ListarPresencas(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdInscricao: Int64
    ): TAlunoPresencaLista; static;

    class function ListarAulas(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdInscricao: Int64
    ): TAlunoAulaLista; static;

    class function ListarCriterios(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdInscricao: Int64
    ): TAlunoCriterioLista; static;

    class function ListarCertificados(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TAlunoCertificadoLista; static;

    class function BuscarCertificado(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdCertificado: Int64
    ): TAlunoCertificadoItem; static;

    class function CaminhoPdf(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdCertificado: Int64
    ): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.IOUtils,
  App.Config,
  APP.Errors,
  Database.Connection,
  AlunoPortal.DAO,
  InstituicaoCertificadoDocumento.Service;

class function TAlunoPortalService.NovaConexao: TUniConnection;
var
  Config: TAppApiConfig;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Result := TDatabaseConnection.NewConnection(Config.Database);
end;

class function TAlunoPortalService.ResolverAluno(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TAlunoContexto;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AIdUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Usuário da instituição não identificado.');

  Result := TAlunoPortalDAO.BuscarContexto(
    AConn,
    AIdInstituicao,
    AIdUsuarioInstituicao
  );

  if Result = nil then
    TAppErrors.RaiseForbidden(
      'O usuário autenticado não possui participante ativo vinculado ao portal.'
    );
end;

class function TAlunoPortalService.MeuPerfil(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TAlunoContexto;
var
  Conn: TUniConnection;
begin
  Conn := NovaConexao;
  try
    Result := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
  finally
    Conn.Free;
  end;
end;

class function TAlunoPortalService.Dashboard(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TAlunoDashboard;
var
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
begin
  Conn := NovaConexao;
  try
    Aluno := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
    try
      Result := TAlunoPortalDAO.Dashboard(Conn, Aluno);
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoPortalService.ListarInscricoes(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ASituacao: string;
  const APagina,
        APorPagina: Integer
): TAlunoInscricaoLista;
var
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
  Pagina, PorPagina: Integer;
begin
  Pagina := APagina;
  PorPagina := APorPagina;

  if Pagina <= 0 then
    Pagina := 1;

  if PorPagina <= 0 then
    PorPagina := 20;

  if PorPagina > 100 then
    PorPagina := 100;

  if not Trim(ASituacao).IsEmpty and
     not MatchText(UpperCase(Trim(ASituacao)),
       ['INSCRITO','CONFIRMADO','EM_ANDAMENTO','CONCLUIDO','CANCELADO','REPROVADO','DESISTENTE']) then
    TAppErrors.RaiseBadRequest('Situação de inscrição inválida.');

  Conn := NovaConexao;
  try
    Aluno := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
    try
      Result := TAlunoPortalDAO.ListarInscricoes(
        Conn,
        Aluno,
        UpperCase(Trim(ASituacao)),
        Pagina,
        PorPagina
      );
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoPortalService.BuscarInscricao(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdInscricao: Int64
): TAlunoInscricaoItem;
var
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
begin
  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest('Inscrição inválida.');

  Conn := NovaConexao;
  try
    Aluno := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
    try
      Result := TAlunoPortalDAO.BuscarInscricao(Conn, Aluno, AIdInscricao);
      if Result = nil then
        TAppErrors.RaiseBadRequest('Inscrição não encontrada.');
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoPortalService.ListarPresencas(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdInscricao: Int64
): TAlunoPresencaLista;
var
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
  Inscricao: TAlunoInscricaoItem;
begin
  Conn := NovaConexao;
  try
    Aluno := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
    try
      Inscricao := TAlunoPortalDAO.BuscarInscricao(Conn, Aluno, AIdInscricao);
      try
        if Inscricao = nil then
          TAppErrors.RaiseBadRequest('Inscrição não encontrada.');

        Result := TAlunoPortalDAO.ListarPresencas(Conn, Aluno, AIdInscricao);
      finally
        Inscricao.Free;
      end;
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoPortalService.ListarAulas(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdInscricao: Int64
): TAlunoAulaLista;
var
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
  Inscricao: TAlunoInscricaoItem;
begin
  Conn := NovaConexao;
  try
    Aluno := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
    try
      Inscricao := TAlunoPortalDAO.BuscarInscricao(Conn, Aluno, AIdInscricao);
      try
        if Inscricao = nil then
          TAppErrors.RaiseBadRequest('Inscrição não encontrada.');

        Result := TAlunoPortalDAO.ListarAulas(Conn, Aluno, AIdInscricao);
      finally
        Inscricao.Free;
      end;
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoPortalService.ListarCriterios(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdInscricao: Int64
): TAlunoCriterioLista;
var
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
  Inscricao: TAlunoInscricaoItem;
begin
  Conn := NovaConexao;
  try
    Aluno := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
    try
      Inscricao := TAlunoPortalDAO.BuscarInscricao(Conn, Aluno, AIdInscricao);
      try
        if Inscricao = nil then
          TAppErrors.RaiseBadRequest('Inscrição não encontrada.');

        Result := TAlunoPortalDAO.ListarCriterios(Conn, Aluno, AIdInscricao);
      finally
        Inscricao.Free;
      end;
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoPortalService.ListarCertificados(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TAlunoCertificadoLista;
var
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
begin
  Conn := NovaConexao;
  try
    Aluno := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
    try
      Result := TAlunoPortalDAO.ListarCertificados(Conn, Aluno);
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoPortalService.BuscarCertificado(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdCertificado: Int64
): TAlunoCertificadoItem;
var
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
begin
  if AIdCertificado <= 0 then
    TAppErrors.RaiseBadRequest('Certificado inválido.');

  Conn := NovaConexao;
  try
    Aluno := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
    try
      Result := TAlunoPortalDAO.BuscarCertificado(Conn, Aluno, AIdCertificado);
      if Result = nil then
        TAppErrors.RaiseBadRequest('Certificado não encontrado.');
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoPortalService.CaminhoPdf(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdCertificado: Int64
): string;
var
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
  StorageKey: string;

begin
  if AIdCertificado <= 0 then
    TAppErrors.RaiseBadRequest('Certificado inválido.');

  Conn := NovaConexao;
  try
    Aluno := ResolverAluno(Conn, AIdInstituicao, AIdUsuarioInstituicao);
    try
      StorageKey := TAlunoPortalDAO.BuscarPdfStorageKey(
        Conn,
        Aluno,
        AIdCertificado
      );

      if Trim(StorageKey).IsEmpty then
        TAppErrors.RaiseBadRequest('PDF do certificado não está disponível.');
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;

  Result := TInstituicaoCertificadoDocumentoService.ResolverCaminhoPdf(
    AIdInstituicao, StorageKey);

end;

end.
