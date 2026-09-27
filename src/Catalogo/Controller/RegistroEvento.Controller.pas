unit RegistroEvento.Controller;

interface

type
  TRegistroEventoController = class
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
  App.Token,
  RegistroEvento.Model,
  RegistroEvento.Service;


function RegistroToJson(const ARegistro: TRegistroEventoModel): TJSONObject;
var
  DadosValue: TJSONValue;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_registro', TJSONNumber.Create(ARegistro.IdRegistro));

  if ARegistro.IdEmpresa > 0 then
    Result.AddPair('id_empresa', TJSONNumber.Create(ARegistro.IdEmpresa))
  else
    Result.AddPair('id_empresa', TJSONNull.Create);

  if ARegistro.IdUsuario > 0 then
    Result.AddPair('id_usuario', TJSONNumber.Create(ARegistro.IdUsuario))
  else
    Result.AddPair('id_usuario', TJSONNull.Create);

  Result.AddPair('origem', ARegistro.Origem);
  Result.AddPair('tipo', ARegistro.Tipo);
  Result.AddPair('entidade', ARegistro.Entidade);

  if ARegistro.IdEntidade > 0 then
    Result.AddPair('id_entidade', TJSONNumber.Create(ARegistro.IdEntidade))
  else
    Result.AddPair('id_entidade', TJSONNull.Create);

  Result.AddPair('titulo', ARegistro.Titulo);
  Result.AddPair('mensagem', ARegistro.Mensagem);
  Result.AddPair('nivel', ARegistro.Nivel);
  Result.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', ARegistro.DataCriacao));

  if not Trim(ARegistro.DadosJson).IsEmpty then
  begin
    DadosValue := TJSONObject.ParseJSONValue(ARegistro.DadosJson);

    if DadosValue <> nil then
      Result.AddPair('dados_json', DadosValue)
    else
      Result.AddPair('dados_json', ARegistro.DadosJson);
  end
  else
    Result.AddPair('dados_json', TJSONNull.Create);
end;

class procedure TRegistroEventoController.Registry;
begin
  THorse.Get('/v1/registros',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TRegistroEventoModel>;
      Registro: TRegistroEventoModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Lista := TRegistroEventoService.ListarPorEmpresa(Claims.IdEmpresa);
        try
          Arr := TJSONArray.Create;

          for Registro in Lista do
            Arr.AddElement(RegistroToJson(Registro));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/registros/pedido/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdPedido: Int64;
      Lista: TObjectList<TRegistroEventoModel>;
      Registro: TRegistroEventoModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdPedido := StrToInt64Def(Req.Params['id'], 0);

        Lista := TRegistroEventoService.BuscarPorEntidade(
          Claims.IdEmpresa,
          'pedido',
          IdPedido
        );
        try
          Arr := TJSONArray.Create;

          for Registro in Lista do
            Arr.AddElement(RegistroToJson(Registro));

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
