unit InstituicaoCursoInstrutor.Service;

interface

uses
  InstituicaoCursoInstrutor.Model;

type
  TInstituicaoCursoInstrutorService = class
  public
    class function Listar(
      const AIdInstituicao,
            AIdCurso: Int64
    ): TInstituicaoCursoInstrutorLista; static;

    class function Vincular(
      const AIdInstituicao,
            AIdCurso,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    ): TInstituicaoCursoInstrutorLista; static;

    class function AtualizarPrincipal(
      const AIdInstituicao,
            AIdCurso,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    ): TInstituicaoCursoInstrutorLista; static;

    class function Desvincular(
      const AIdInstituicao,
            AIdCurso,
            AIdInstrutor: Int64
    ): TInstituicaoCursoInstrutorLista; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoCursoInstrutor.DAO;

class function TInstituicaoCursoInstrutorService.Listar(
  const AIdInstituicao,
        AIdCurso: Int64
): TInstituicaoCursoInstrutorLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCurso <= 0 then
    TAppErrors.RaiseBadRequest(
      'Curso inválido.'
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
    if not TInstituicaoCursoInstrutorDAO.CursoExiste(
      Conn,
      AIdInstituicao,
      AIdCurso
    ) then
      TAppErrors.RaiseBadRequest(
        'Curso não encontrado.'
      );

    Result :=
      TInstituicaoCursoInstrutorDAO.Listar(
        Conn,
        AIdInstituicao,
        AIdCurso
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCursoInstrutorService.Vincular(
  const AIdInstituicao,
        AIdCurso,
        AIdInstrutor: Int64;
  const APrincipal: Boolean
): TInstituicaoCursoInstrutorLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCurso <= 0 then
    TAppErrors.RaiseBadRequest(
      'Curso inválido.'
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
    if not TInstituicaoCursoInstrutorDAO.CursoExiste(
      Conn,
      AIdInstituicao,
      AIdCurso
    ) then
      TAppErrors.RaiseBadRequest(
        'Curso não encontrado.'
      );

    if not TInstituicaoCursoInstrutorDAO.InstrutorAtivoExiste(
      Conn,
      AIdInstituicao,
      AIdInstrutor
    ) then
      TAppErrors.RaiseBadRequest(
        'Instrutor não encontrado, não pertence à instituição ou está inativo.'
      );

    if TInstituicaoCursoInstrutorDAO.VinculoExiste(
      Conn,
      AIdInstituicao,
      AIdCurso,
      AIdInstrutor
    ) then
      TAppErrors.RaiseBadRequest(
        'Este instrutor já está vinculado ao curso.'
      );

    Conn.StartTransaction;
    try
      TInstituicaoCursoInstrutorDAO.Inserir(
        Conn,
        AIdInstituicao,
        AIdCurso,
        AIdInstrutor,
        APrincipal
      );

      Result :=
        TInstituicaoCursoInstrutorDAO.Listar(
          Conn,
          AIdInstituicao,
          AIdCurso
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

class function TInstituicaoCursoInstrutorService.AtualizarPrincipal(
  const AIdInstituicao,
        AIdCurso,
        AIdInstrutor: Int64;
  const APrincipal: Boolean
): TInstituicaoCursoInstrutorLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if (AIdCurso <= 0) or
     (AIdInstrutor <= 0) then
    TAppErrors.RaiseBadRequest(
      'Vínculo de curso/instrutor inválido.'
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
    if not TInstituicaoCursoInstrutorDAO.VinculoExiste(
      Conn,
      AIdInstituicao,
      AIdCurso,
      AIdInstrutor
    ) then
      TAppErrors.RaiseBadRequest(
        'Vínculo entre curso e instrutor não encontrado.'
      );

    Conn.StartTransaction;
    try
      TInstituicaoCursoInstrutorDAO.AtualizarPrincipal(
        Conn,
        AIdInstituicao,
        AIdCurso,
        AIdInstrutor,
        APrincipal
      );

      Result :=
        TInstituicaoCursoInstrutorDAO.Listar(
          Conn,
          AIdInstituicao,
          AIdCurso
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

class function TInstituicaoCursoInstrutorService.Desvincular(
  const AIdInstituicao,
        AIdCurso,
        AIdInstrutor: Int64
): TInstituicaoCursoInstrutorLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if (AIdCurso <= 0) or
     (AIdInstrutor <= 0) then
    TAppErrors.RaiseBadRequest(
      'Vínculo de curso/instrutor inválido.'
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
    if not TInstituicaoCursoInstrutorDAO.VinculoExiste(
      Conn,
      AIdInstituicao,
      AIdCurso,
      AIdInstrutor
    ) then
      TAppErrors.RaiseBadRequest(
        'Vínculo entre curso e instrutor não encontrado.'
      );

    Conn.StartTransaction;
    try
      TInstituicaoCursoInstrutorDAO.Excluir(
        Conn,
        AIdInstituicao,
        AIdCurso,
        AIdInstrutor
      );

      Result :=
        TInstituicaoCursoInstrutorDAO.Listar(
          Conn,
          AIdInstituicao,
          AIdCurso
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

end.
