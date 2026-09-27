unit InstituicaoTurmaInstrutor.Service;

interface

uses
  InstituicaoTurmaInstrutor.Model;

type
  TInstituicaoTurmaInstrutorService = class
  public
    class function Listar(
      const AIdInstituicao,
            AIdTurma: Int64
    ): TInstituicaoTurmaInstrutorLista; static;

    class function Vincular(
      const AIdInstituicao,
            AIdTurma,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    ): TInstituicaoTurmaInstrutorLista; static;

    class function AtualizarPrincipal(
      const AIdInstituicao,
            AIdTurma,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    ): TInstituicaoTurmaInstrutorLista; static;

    class function Desvincular(
      const AIdInstituicao,
            AIdTurma,
            AIdInstrutor: Int64
    ): TInstituicaoTurmaInstrutorLista; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoTurmaInstrutor.DAO;

class function TInstituicaoTurmaInstrutorService.Listar(
  const AIdInstituicao,
        AIdTurma: Int64
): TInstituicaoTurmaInstrutorLista;
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
    if not TInstituicaoTurmaInstrutorDAO.TurmaExiste(
      Conn,
      AIdInstituicao,
      AIdTurma
    ) then
      TAppErrors.RaiseBadRequest(
        'Turma não encontrada.'
      );

    Result :=
      TInstituicaoTurmaInstrutorDAO.Listar(
        Conn,
        AIdInstituicao,
        AIdTurma
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaInstrutorService.Vincular(
  const AIdInstituicao,
        AIdTurma,
        AIdInstrutor: Int64;
  const APrincipal: Boolean
): TInstituicaoTurmaInstrutorLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
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
    if not TInstituicaoTurmaInstrutorDAO.TurmaExiste(
      Conn,
      AIdInstituicao,
      AIdTurma
    ) then
      TAppErrors.RaiseBadRequest(
        'Turma não encontrada.'
      );

    if not TInstituicaoTurmaInstrutorDAO.InstrutorAtivoExiste(
      Conn,
      AIdInstituicao,
      AIdInstrutor
    ) then
      TAppErrors.RaiseBadRequest(
        'Instrutor não encontrado, não pertence à instituição ou está inativo.'
      );

    if TInstituicaoTurmaInstrutorDAO.VinculoExiste(
      Conn,
      AIdInstituicao,
      AIdTurma,
      AIdInstrutor
    ) then
      TAppErrors.RaiseBadRequest(
        'Este instrutor já está vinculado à turma.'
      );

    Conn.StartTransaction;
    try
      TInstituicaoTurmaInstrutorDAO.Inserir(
        Conn,
        AIdInstituicao,
        AIdTurma,
        AIdInstrutor,
        APrincipal
      );

      Result :=
        TInstituicaoTurmaInstrutorDAO.Listar(
          Conn,
          AIdInstituicao,
          AIdTurma
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

class function TInstituicaoTurmaInstrutorService.AtualizarPrincipal(
  const AIdInstituicao,
        AIdTurma,
        AIdInstrutor: Int64;
  const APrincipal: Boolean
): TInstituicaoTurmaInstrutorLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if (AIdTurma <= 0) or
     (AIdInstrutor <= 0) then
    TAppErrors.RaiseBadRequest(
      'Vínculo de turma/instrutor inválido.'
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
    if not TInstituicaoTurmaInstrutorDAO.VinculoExiste(
      Conn,
      AIdInstituicao,
      AIdTurma,
      AIdInstrutor
    ) then
      TAppErrors.RaiseBadRequest(
        'Vínculo entre turma e instrutor não encontrado.'
      );

    Conn.StartTransaction;
    try
      TInstituicaoTurmaInstrutorDAO.AtualizarPrincipal(
        Conn,
        AIdInstituicao,
        AIdTurma,
        AIdInstrutor,
        APrincipal
      );

      Result :=
        TInstituicaoTurmaInstrutorDAO.Listar(
          Conn,
          AIdInstituicao,
          AIdTurma
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

class function TInstituicaoTurmaInstrutorService.Desvincular(
  const AIdInstituicao,
        AIdTurma,
        AIdInstrutor: Int64
): TInstituicaoTurmaInstrutorLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if (AIdTurma <= 0) or
     (AIdInstrutor <= 0) then
    TAppErrors.RaiseBadRequest(
      'Vínculo de turma/instrutor inválido.'
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
    if not TInstituicaoTurmaInstrutorDAO.VinculoExiste(
      Conn,
      AIdInstituicao,
      AIdTurma,
      AIdInstrutor
    ) then
      TAppErrors.RaiseBadRequest(
        'Vínculo entre turma e instrutor não encontrado.'
      );

    Conn.StartTransaction;
    try
      TInstituicaoTurmaInstrutorDAO.Excluir(
        Conn,
        AIdInstituicao,
        AIdTurma,
        AIdInstrutor
      );

      Result :=
        TInstituicaoTurmaInstrutorDAO.Listar(
          Conn,
          AIdInstituicao,
          AIdTurma
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
