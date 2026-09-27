unit AlunoQrParticipante.Service;

interface

uses
  AlunoQrParticipante.Model;

type
  TAlunoQrParticipanteService = class
  public
    class function MeuQrCode(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TAlunoQrParticipante; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  AlunoPortal.Model,
  AlunoPortal.DAO;

class function TAlunoQrParticipanteService.MeuQrCode(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TAlunoQrParticipante;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
begin
  Result := nil;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Aluno := TAlunoPortalDAO.BuscarContexto(
      Conn,
      AIdInstituicao,
      AIdUsuarioInstituicao
    );
    try
      if Aluno = nil then
        TAppErrors.RaiseForbidden(
          'O usuário autenticado não possui participante ativo vinculado ao portal.'
        );

      Result := TAlunoQrParticipante.Create;
      Result.CodigoParticipante := Aluno.CodigoPublico;
      Result.ConteudoQr := 'CERTIFICA:P:' + Aluno.CodigoPublico;
      Result.Nome := Aluno.Nome;
      Result.Matricula := Aluno.Matricula;
      Result.CpfMascarado := Aluno.CpfMascarado;
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
