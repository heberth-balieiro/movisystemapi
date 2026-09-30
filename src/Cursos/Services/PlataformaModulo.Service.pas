unit PlataformaModulo.Service;

interface

uses
  Uni,
  System.Generics.Collections,
  PlataformaModulo.Model;

type
  TPlataformaModuloService = class
  private
    class procedure ValidarCodigos(
      const AConn: TUniConnection;
      const ACodigos: TList<string>
    ); static;

  public
    class function ListarCatalogo:
      TObjectList<TPlataformaModuloItem>; static;

    class function ListarInstituicao(
      const AIdInstituicao: Int64
    ): TList<string>; static;

    class procedure SalvarInstituicao(
      const AIdInstituicao,
            AIdUsuarioAcao: Int64;
      const ACodigos: TList<string>;
      const AIP,
            AUserAgent: string
    ); static;

    class function InstituicaoPossuiModulo(
      const AIdInstituicao: Int64;
      const ACodigo: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaModulo.DAO,
  PlataformaInstituicao.DAO,
  PlataformaInstituicao.Model;

function JoinStrings(
  const ALista: TList<string>
): string;
var
  Item: string;
begin
  Result := '';

  if ALista = nil then
    Exit;

  for Item in ALista do
  begin
    if not Result.IsEmpty then
      Result := Result + ',';

    Result := Result + Item;
  end;
end;

class procedure TPlataformaModuloService.ValidarCodigos(
  const AConn: TUniConnection;
  const ACodigos: TList<string>
);
var
  Codigo: string;
  Normalizados: TList<string>;
begin
  if (ACodigos = nil) or (ACodigos.Count = 0) then
    TAppErrors.RaiseBadRequest(
      'Selecione ao menos um módulo para a instituição.'
    );

  Normalizados := TList<string>.Create;
  try
    for Codigo in ACodigos do
    begin
      if Trim(Codigo).IsEmpty then
        Continue;

      if Normalizados.Contains(
        UpperCase(Trim(Codigo))
      ) then
        Continue;

      if not TPlataformaModuloDAO.CodigoAtivoExiste(
        AConn,
        Codigo
      ) then
        TAppErrors.RaiseBadRequest(
          'Módulo inválido ou inativo: ' +
          UpperCase(Trim(Codigo))
        );

      Normalizados.Add(
        UpperCase(Trim(Codigo))
      );
    end;

    if Normalizados.Count = 0 then
      TAppErrors.RaiseBadRequest(
        'Selecione ao menos um módulo para a instituição.'
      );

    ACodigos.Clear;
    for Codigo in Normalizados do
      ACodigos.Add(Codigo);
  finally
    Normalizados.Free;
  end;
end;

class function TPlataformaModuloService.ListarCatalogo:
  TObjectList<TPlataformaModuloItem>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
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
    Result :=
      TPlataformaModuloDAO.ListarCatalogo(
        Conn
      );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaModuloService.ListarInstituicao(
  const AIdInstituicao: Int64
): TList<string>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Instituicao: TPlataformaInstituicaoModel;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Instituição inválida.'
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
    Instituicao :=
      TPlataformaInstituicaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao
      );
    try
      if Instituicao = nil then
        TAppErrors.RaiseNotFound(
          'Instituição não encontrada.'
        );
    finally
      Instituicao.Free;
    end;

    Result :=
      TPlataformaModuloDAO.ListarCodigosInstituicao(
        Conn,
        AIdInstituicao
      );
  finally
    Conn.Free;
  end;
end;

class procedure TPlataformaModuloService.SalvarInstituicao(
  const AIdInstituicao,
        AIdUsuarioAcao: Int64;
  const ACodigos: TList<string>;
  const AIP,
        AUserAgent: string
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Instituicao: TPlataformaInstituicaoModel;
  Antes,
  Depois: TList<string>;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Instituição inválida.'
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
    Instituicao :=
      TPlataformaInstituicaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao
      );
    try
      if Instituicao = nil then
        TAppErrors.RaiseNotFound(
          'Instituição não encontrada.'
        );
    finally
      Instituicao.Free;
    end;

    ValidarCodigos(
      Conn,
      ACodigos
    );

    Antes :=
      TPlataformaModuloDAO.ListarCodigosInstituicao(
        Conn,
        AIdInstituicao
      );
    try
      Conn.StartTransaction;
      try
        TPlataformaModuloDAO.SalvarModulosInstituicao(
          Conn,
          AIdInstituicao,
          AIdUsuarioAcao,
          ACodigos
        );

        Depois :=
          TPlataformaModuloDAO.ListarCodigosInstituicao(
            Conn,
            AIdInstituicao
          );
        try
          TPlataformaInstituicaoDAO.RegistrarAuditoria(
            Conn,
            AIdInstituicao,
            AIdUsuarioAcao,
            'INSTITUICAO_MODULOS_ALTERADOS',
            'Módulos alterados. Antes: ' +
              JoinStrings(Antes) +
              '. Depois: ' +
              JoinStrings(Depois) +
              '.',
            'PUT',
            '/v1/certifica/plataforma/instituicoes/' +
              AIdInstituicao.ToString +
              '/modulos',
            AIP,
            AUserAgent
          );
        finally
          Depois.Free;
        end;

        Conn.Commit;
      except
        if Conn.InTransaction then
          Conn.Rollback;
        raise;
      end;
    finally
      Antes.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TPlataformaModuloService.InstituicaoPossuiModulo(
  const AIdInstituicao: Int64;
  const ACodigo: string
): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := False;

  if (AIdInstituicao <= 0) or Trim(ACodigo).IsEmpty then
    Exit;

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
      TPlataformaModuloDAO.InstituicaoPossuiModulo(
        Conn,
        AIdInstituicao,
        ACodigo
      );
  finally
    Conn.Free;
  end;
end;

end.
