unit EleicaoCodigoTemporarioAPI.Controller;

interface

type
  TEleicaoCodigoTemporarioAPIController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Token,
  App.JWT,
  App.Response,
  APP.Errors,
  App.RequestInfo,
  EleicaoCodigoTemporarioAPI.Dao,
  EleicaoCodigoTemporarioAPI.Service;

function MascararCPF(const ACPF: string): string;
var
  S: string;
begin
  S := Trim(ACPF);
  if Length(S) < 4 then
    Exit('***');
  Result := '***.***.***-' + Copy(S, Length(S)-1, 2);
end;

function MascararEmail(const AEmail: string): string;
var
  P: Integer;
  Local, Dominio: string;
begin
  Result := '';
  P := Pos('@', Trim(AEmail));
  if P <= 1 then Exit;
  Local := Copy(Trim(AEmail),1,P-1);
  Dominio := Copy(Trim(AEmail),P,MaxInt);
  Result := Copy(Local,1,1) + StringOfChar('*',5) + Dominio;
end;

class procedure TEleicaoCodigoTemporarioAPIController.Registry;
begin
  THorse.Get('/api/v1/eleicao/:slug/admin/contingencia/eleitores',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug, Termo: string;
      Lista: TEleicaoCodigoTemporarioEleitores;
      Dados: TJSONArray;
      ItemJson: TJSONObject;
      Item: TEleicaoCodigoTemporarioEleitor;
    begin
      try
        if not TAppToken.ValidarToken(Req,Res,Claims) then Exit;
        Slug := Trim(Req.Params['slug']);
        if Slug.IsEmpty then TAppErrors.RaiseBadRequest('Eleição não informada.');
        if not TAppToken.PodeAdministrarEleicao(Claims.Roles) then
          TAppErrors.RaiseUnauthorized('Usuário não autorizado.');
        if not TAppToken.PertenceEleicao(Claims,Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

        Termo := Trim(Req.Query['q']);
        Lista := TEleicaoCodigoTemporarioAPIService.BuscarEleitores(
          Slug, Claims.UserId, Claims.IdEmpresa, Termo
        );
        try
          Dados := TJSONArray.Create;
          for Item in Lista do
          begin
            ItemJson := TJSONObject.Create;
            ItemJson.AddPair('id_usuario',TJSONNumber.Create(Item.IdUsuario));
            ItemJson.AddPair('nome',Item.Nome);
            ItemJson.AddPair('cpf',MascararCPF(Item.CPF));
            ItemJson.AddPair('matricula',Item.Matricula);
            ItemJson.AddPair('email',MascararEmail(Item.Email));
            ItemJson.AddPair('tem_whatsapp',TJSONBool.Create(not Trim(Item.Whatsapp).IsEmpty));
            ItemJson.AddPair('ja_votou',TJSONBool.Create(Item.JaVotou));
            Dados.AddElement(ItemJson);
          end;
          TAppResponse.Ok(Res,Dados,'');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

  THorse.Post('/api/v1/eleicao/:slug/admin/contingencia/eleitores/:idusuario/codigo-temporario',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug: string;
      IdUsuario: Integer;
      Resultado: TEleicaoCodigoTemporarioGerado;
      Dados: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req,Res,Claims) then Exit;
        Slug := Trim(Req.Params['slug']);
        if Slug.IsEmpty then TAppErrors.RaiseBadRequest('Eleição não informada.');
        if not TAppToken.PodeAdministrarEleicao(Claims.Roles) then
          TAppErrors.RaiseUnauthorized('Usuário não autorizado.');
        if not TAppToken.PertenceEleicao(Claims,Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

        if not TryStrToInt(Trim(Req.Params['idusuario']),IdUsuario) or (IdUsuario <= 0) then
          TAppErrors.RaiseBadRequest('Eleitor inválido.');

        Resultado := TEleicaoCodigoTemporarioAPIService.Gerar(
          Slug,
          Claims.UserId,
          Claims.IdEmpresa,
          IdUsuario,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req)
        );

        Dados := TJSONObject.Create;
        Dados.AddPair('codigo',Resultado.Codigo);
        Dados.AddPair('validade_segundos',TJSONNumber.Create(Resultado.ValidadeSegundos));
        Dados.AddPair('expira_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss',Resultado.ExpiraEm));
        TAppResponse.Ok(Res,Dados,'Código temporário gerado com sucesso.');
      except
        on E: Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );
end;

end.
