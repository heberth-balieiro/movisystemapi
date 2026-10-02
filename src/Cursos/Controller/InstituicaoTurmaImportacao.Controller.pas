unit InstituicaoTurmaImportacao.Controller;

interface

type
  TInstituicaoTurmaImportacaoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.Classes,
  System.JSON,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  InstituicaoTurmaImportacao.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto de instituição.'
    );
    Exit;
  end;

  if AClaims.IdUsuarioInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem vínculo de usuário com a instituição.'
    );
    Exit;
  end;

  Result := True;
end;

function ObterArquivo(
  const Req: THorseRequest
): TStream;
begin
  Result := nil;

  if Req.ContentFields.Field('arquivo') = nil then
    TAppErrors.RaiseBadRequest(
      'Arquivo CSV não informado.'
    );

  Result :=
    Req.ContentFields
       .Field('arquivo')
       .AsStream;

  if Result = nil then
    TAppErrors.RaiseBadRequest(
      'Arquivo CSV inválido.'
    );
end;

class procedure TInstituicaoTurmaImportacaoController.Registry;
begin
  THorse.Post(
    '/v1/certifica/instituicao/turmas/:id/importacoes/validar',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id'], 0);

        Retorno :=
          TInstituicaoTurmaImportacaoService.Validar(
            Claims.IdInstituicao,
            IdTurma,
            Claims.IdUsuarioInstituicao,
            'importacao.csv',
            ObterArquivo(Req)
          );

        TAppResponse.Ok(
          Res,
          Retorno,
          'Arquivo CSV validado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/instituicao/turmas/:id/importacoes',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id'], 0);

        Retorno :=
          TInstituicaoTurmaImportacaoService.Importar(
            Claims.IdInstituicao,
            IdTurma,
            Claims.IdUsuarioInstituicao,
            'importacao.csv',
            ObterArquivo(Req)
          );

        TAppResponse.Ok(
          Res,
          Retorno,
          'Importação CSV concluída.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
