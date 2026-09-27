unit AlunoQrParticipante.Controller;

interface

type
  TAlunoQrParticipanteController = class
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
  AlunoQrParticipante.Model,
  AlunoQrParticipante.Service;

class procedure TAlunoQrParticipanteController.Registry;
begin
  THorse.Get(
    '/v1/certifica/aluno/me/qrcode',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TAlunoQrParticipante;
      Json: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if (Claims.IdInstituicao <= 0) or
           (Claims.IdUsuarioInstituicao <= 0) then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem contexto válido da instituição.'
          );
          Exit;
        end;

        Item :=
          TAlunoQrParticipanteService.MeuQrCode(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao
          );

        try
          Json := TJSONObject.Create;

          Json.AddPair(
            'codigo_participante',
            Item.CodigoParticipante
          );

          Json.AddPair(
            'conteudo_qr',
            Item.ConteudoQr
          );

          Json.AddPair(
            'nome',
            Item.Nome
          );

          if Trim(Item.Matricula) = '' then
            Json.AddPair(
              'matricula',
              TJSONNull.Create
            )
          else
            Json.AddPair(
              'matricula',
              Item.Matricula
            );

          if Trim(Item.CpfMascarado) = '' then
            Json.AddPair(
              'cpf_mascarado',
              TJSONNull.Create
            )
          else
            Json.AddPair(
              'cpf_mascarado',
              Item.CpfMascarado
            );

          TAppResponse.Ok(
            Res,
            Json,
            'QR Code do participante carregado com sucesso.'
          );

        finally
          Item.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );
end;

end.

