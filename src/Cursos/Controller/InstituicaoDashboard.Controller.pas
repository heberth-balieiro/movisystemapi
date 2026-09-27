unit InstituicaoDashboard.Controller;

interface

type
  TInstituicaoDashboardController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  InstituicaoDashboard.DAO,
  InstituicaoDashboard.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(
    Req,
    Res,
    AClaims
  ) then
    Exit;

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto de instituição.'
    );
    Exit;
  end;

  Result := True;
end;

class procedure TInstituicaoDashboardController.Registry;
begin
  {$REGION 'Dashboard'}

  THorse.Get('/v1/certifica/instituicao/dashboard',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoDashboardDados;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Resultado :=
          TInstituicaoDashboardService.Buscar(
            Claims.IdInstituicao
          );

        Dados := TJSONObject.Create;

        Dados.AddPair(
          'cursos',
          TJSONNumber.Create(Resultado.Cursos)
        );

        Dados.AddPair(
          'participantes',
          TJSONNumber.Create(Resultado.Participantes)
        );

        Dados.AddPair(
          'turmas',
          TJSONNumber.Create(Resultado.Turmas)
        );

        Dados.AddPair(
          'certificados',
          TJSONNumber.Create(Resultado.Certificados)
        );

        Dados.AddPair(
          'em_andamento',
          TJSONNumber.Create(Resultado.EmAndamento)
        );

        Dados.AddPair(
          'concluidos',
          TJSONNumber.Create(Resultado.Concluidos)
        );

        Dados.AddPair(
          'horas_capacitacao',
          TJSONNumber.Create(
            Resultado.HorasCapacitacao
          )
        );

        TAppResponse.Ok(
          Res,
          Dados,
          'Dashboard carregado com sucesso.'
        );

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end);
  {$ENDREGION}

  {$REGION 'Curso'}


  {$ENDREGION}

end;

end.
