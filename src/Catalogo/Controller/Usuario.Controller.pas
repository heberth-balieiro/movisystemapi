unit Usuario.Controller;

interface

type
  TUsuarioController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.JSON,
  APP.Response;

class procedure TUsuarioController.Registry;
begin
  THorse.Get('/v1/status',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LJson: TJSONObject;
    begin
      LJson         := TJSONObject.Create;
      LJson.AddPair('status', 'online');
      LJson.AddPair('message', 'API Delphi rodando com sucesso');
      LJson.AddPair('platform', 'Windows/Linux');

      //Res.Send<TJSONObject>(LJson);
      TAppResponse.Ok(Res, LJson);
    end);

  THorse.Get('/v1/usuarios',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LArray: TJSONArray;
      LItem: TJSONObject;
    begin
      LArray := TJSONArray.Create;

      LItem := TJSONObject.Create;
      LItem.AddPair('id', TJSONNumber.Create(1));
      LItem.AddPair('nome', 'Administrador');
      LItem.AddPair('email', 'admin@sistema.com.br');

      LArray.AddElement(LItem);

      //Res.Send<TJSONArray>(LArray);
      TAppResponse.Ok(Res, LArray);
    end);
end;

end.
