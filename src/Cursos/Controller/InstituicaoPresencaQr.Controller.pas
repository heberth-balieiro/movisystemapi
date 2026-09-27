unit InstituicaoPresencaQr.Controller;

interface

type
  TInstituicaoPresencaQrController = class
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
  InstituicaoPresenca.Model,
  InstituicaoPresencaQr.Service;

function PresencaJson(const AItem: TInstituicaoPresencaItem): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  Result.AddPair('id_turma', TJSONNumber.Create(AItem.IdTurma));
  Result.AddPair('id_encontro', TJSONNumber.Create(AItem.IdEncontro));
  Result.AddPair('encontro_titulo', AItem.EncontroTitulo);
  Result.AddPair('id_inscricao', TJSONNumber.Create(AItem.IdInscricao));
  Result.AddPair('id_participante', TJSONNumber.Create(AItem.IdParticipante));
  Result.AddPair('participante_nome', AItem.ParticipanteNome);
  Result.AddPair('participante_cpf_mascarado', AItem.ParticipanteCpfMascarado);
  Result.AddPair('participante_matricula', AItem.ParticipanteMatricula);
  Result.AddPair('situacao', AItem.Situacao);

  if AItem.TemCheckinEm then
    Result.AddPair(
      'checkin_em',
      FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', AItem.CheckinEm)
    )
  else
    Result.AddPair('checkin_em', TJSONNull.Create);
end;

class procedure TInstituicaoPresencaQrController.Registry;
begin
  THorse.Post(
    '/v1/certifica/instituicao/turmas/:id_turma/encontros/:id_encontro/presencas/qrcode',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      BodyValue: TJSONValue;
      Body: TJSONObject;
      V: TJSONValue;
      ConteudoQr: string;
      Item: TInstituicaoPresencaItem;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if (Claims.IdInstituicao <= 0) or
           (Claims.IdUsuarioInstituicao <= 0) then
        begin
          TAppResponse.Forbidden(Res, 'Token sem contexto válido da instituição.');
          Exit;
        end;

        BodyValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (BodyValue is TJSONObject) then
        begin
          BodyValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := BodyValue as TJSONObject;
        try
          ConteudoQr := '';

          V := Body.GetValue('conteudo_qr');
          if (V <> nil) and not (V is TJSONNull) then
            ConteudoQr := V.Value;

          if ConteudoQr.IsEmpty then
          begin
            V := Body.GetValue('codigo_participante');
            if (V <> nil) and not (V is TJSONNull) then
              ConteudoQr := V.Value;
          end;
        finally
          Body.Free;
        end;

        Item := TInstituicaoPresencaQrService.Registrar(
          Claims.IdInstituicao,
          StrToInt64Def(Req.Params.Items['id_turma'], 0),
          StrToInt64Def(Req.Params.Items['id_encontro'], 0),
          Claims.IdUsuarioInstituicao,
          ConteudoQr
        );
        try
          TAppResponse.Ok(
            Res,
            PresencaJson(Item),
            'Presença registrada pelo QR Code com sucesso.'
          );
        finally
          Item.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
