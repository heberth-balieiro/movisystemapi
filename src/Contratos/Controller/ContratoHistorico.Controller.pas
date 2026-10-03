unit ContratoHistorico.Controller;

interface

type
  TContratoHistoricoController = class
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
  ContratoHistorico.Model,
  ContratoHistorico.Service;

class procedure TContratoHistoricoController.Registry;
begin
  THorse.Get('/v1/contratos/instituicao/contratos/:id/historico',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var
      Claims:TJWTClaims;
      Lista:TContratoHistoricoLista;
      Item:TContratoHistoricoItem;
      Arr:TJSONArray;
      Obj:TJSONObject;
      IdContrato:Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req,Res,Claims) then Exit;
        if (Claims.IdInstituicao<=0) or (Claims.IdUsuarioInstituicao<=0) then
        begin
          TAppResponse.Forbidden(Res,'Token sem contexto válido de instituição e usuário.');
          Exit;
        end;

        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        Lista:=TContratoHistoricoService.Listar(Claims.IdInstituicao,Claims.IdUsuarioInstituicao,IdContrato);
        try
          Arr:=TJSONArray.Create;
          for Item in Lista do
          begin
            Obj:=TJSONObject.Create;
            Obj.AddPair('id',TJSONNumber.Create(Item.Id));
            Obj.AddPair('evento',Item.Evento);
            Obj.AddPair('descricao',Item.Descricao);
            Obj.AddPair('referencia_tipo',Item.ReferenciaTipo);
            if Item.ReferenciaId>0 then Obj.AddPair('referencia_id',TJSONNumber.Create(Item.ReferenciaId)) else Obj.AddPair('referencia_id',TJSONNull.Create);
            if Item.DetalhesJson<>'' then Obj.AddPair('detalhes_json',Item.DetalhesJson) else Obj.AddPair('detalhes_json',TJSONNull.Create);
            if Item.Usuario>0 then Obj.AddPair('usuario',TJSONNumber.Create(Item.Usuario)) else Obj.AddPair('usuario',TJSONNull.Create);
            Obj.AddPair('usuario_nome',Item.UsuarioNome);
            Obj.AddPair('criado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Item.CriadoEm));
            Arr.AddElement(Obj);
          end;
          TAppResponse.Ok(Res,Arr,'Histórico carregado com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E:Exception do TAppErrors.HandleException(Res,E);
      end;
    end);
end;

end.
