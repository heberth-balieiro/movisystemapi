unit Unidade.Controller;

interface

type
  TUnidadeController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.Config,
  App.JWT,
  App.Response,
  APP.Errors,
  APP.Token,
  Unidade.Model,
  Unidade.Service;


function UnidadeToJson(const AUnidade: TUnidadeModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_unidade', TJSONNumber.Create(AUnidade.IdUnidade));
  Result.AddPair('sigla', AUnidade.Sigla);
  Result.AddPair('descricao', AUnidade.Descricao);
  Result.AddPair('ativo', AUnidade.Ativo);

  if AUnidade.DataCriacao > 0 then
    Result.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', AUnidade.DataCriacao))
  else
    Result.AddPair('data_criacao', TJSONNull.Create);

  if AUnidade.DataAlteracao > 0 then
    Result.AddPair('data_alteracao', FormatDateTime('yyyy-mm-dd hh:nn:ss', AUnidade.DataAlteracao))
  else
    Result.AddPair('data_alteracao', TJSONNull.Create);
end;

class procedure TUnidadeController.Registry;
begin
  THorse.Get('/v1/unidades',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TUnidadeModel>;
      Unidade: TUnidadeModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Lista := TUnidadeService.ListarUnidades;
        try
          Arr := TJSONArray.Create;

          for Unidade in Lista do
            Arr.AddElement(UnidadeToJson(Unidade));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
