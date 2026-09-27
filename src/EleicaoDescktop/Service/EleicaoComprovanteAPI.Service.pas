unit EleicaoComprovanteAPI.Service;

interface

uses
  System.SysUtils;

type
  TValidarComprovanteResult = record
    Valido: string;
    Eleicao: string;
    RegistradoEm: TDateTime;
  end;

  TEleicaoComprovanteAPIService = class
  public
    class function ValidarComprovante(
      const ASlug: string;
      const AComprovante: string
    ): TValidarComprovanteResult; static;
  end;

implementation

uses
  Uni,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoComprovanteAPI.Dao;

{ TEleicaoComprovanteAPIService }

class function TEleicaoComprovanteAPIService.ValidarComprovante(
  const ASlug: string;
  const AComprovante: string
): TValidarComprovanteResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
  Comprovante: string;
  ResultadoDao: TEleicaoComprovante;
begin
  Result := Default(TValidarComprovanteResult);

  Result.Valido := 'N';

  //
  // 1. Validar slug
  //
  Slug := Trim(ASlug);

  if Slug.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Eleição não informada.'
    );

  //
  // 2. Validar comprovante
  //
  Comprovante :=
    UpperCase(
      Trim(AComprovante)
    );

  if Comprovante.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Comprovante não informado.'
    );

  //
  // 3. Abrir conexão
  //
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

    //
    // 4. Buscar comprovante
    //
    if not TEleicaoComprovanteAPIDao.BuscarComprovante(
      Conn,
      Slug,
      Comprovante,
      ResultadoDao
    ) then
    begin
      Result.Valido := 'N';
      Exit;
    end;

    //
    // 5. Comprovante válido
    //
    Result.Valido := 'S';

    Result.Eleicao :=
      ResultadoDao.NomeEleicao;

    Result.RegistradoEm :=
      ResultadoDao.RegistradoEm;

  finally
    Conn.Free;
  end;
end;

end.
