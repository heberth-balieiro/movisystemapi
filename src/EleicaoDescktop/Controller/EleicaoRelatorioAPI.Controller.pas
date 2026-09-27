unit EleicaoRelatorioAPI.Controller;

interface

type
  TEleicaoRelatorioAPIController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Errors,
  App.JWT,
  App.Response,
  App.Token,
  EleicaoRelatorioAPI.Dao,
  EleicaoRelatorioAPI.Service;

{ TEleicaoRelatorioAPIController }

class procedure TEleicaoRelatorioAPIController.Registry;
begin

  {$REGION 'RELATORIO ELEITORES'}

  THorse.Get('/api/v1/eleicao/:slug/admin/relatorio/eleitores',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims  : TJWTClaims;
      Slug    : string;
      Situacao: string;
      Lista   : TEleicaoRelatorioListaEleitores;
      Dados   : TJSONArray;
      Json    : TJSONObject;
      Item    : TEleicaoRelatorioEleitor;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Slug := Trim(Req.Params['slug']);
        Situacao := UpperCase(Trim(Req.Query['situacao']));

        if not TAppToken.PossuiRole(Claims.Roles, 'ADMIN') then
        TAppErrors.RaiseUnauthorized('Usuário não autorizado.');

        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');



        Lista := TEleicaoRelatorioAPIService.BuscarEleitores(
          Slug,
          Claims.UserId,
          Claims.IdEmpresa,
          Situacao
        );

        try
          Dados := TJSONArray.Create;

          for Item in Lista do
          begin
            Json := TJSONObject.Create;

            Json.AddPair('usuario_id', TJSONNumber.Create(Item.IdUsuario));
            Json.AddPair('pessoa_id', TJSONNumber.Create(Item.IdPessoa));
            Json.AddPair('matricula', TJSONNumber.Create(Item.Matricula));
            Json.AddPair('nome', Item.Nome);
            Json.AddPair('cpf', Item.CPF);
            Json.AddPair('email', Item.Email);
            Json.AddPair('whatsapp', Item.Whatsapp);
            Json.AddPair('votou', Item.Votou);

            if Item.TemVotadoEm then
              Json.AddPair('votado_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Item.VotadoEm))
            else
              Json.AddPair('votado_em', TJSONNull.Create);

            Dados.AddElement(Json);
          end;

          TAppResponse.Ok(Res, Dados, '');

        finally
          Lista.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  {$ENDREGION}

end;

end.
