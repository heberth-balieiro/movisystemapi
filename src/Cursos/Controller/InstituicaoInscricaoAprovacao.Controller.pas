unit InstituicaoInscricaoAprovacao.Controller;

interface

type
  TInstituicaoInscricaoAprovacaoController = class
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
  InstituicaoInscricao.Model,
  InstituicaoInscricaoAprovacao.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if (AClaims.IdInstituicao <= 0) or
     (AClaims.IdUsuarioInstituicao <= 0) then
  begin
    TAppResponse.Forbidden(Res, 'Token sem contexto válido da instituição.');
    Exit;
  end;

  Result := True;
end;

function ISODateTime(const AValue: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', AValue);
end;

function InscricaoJson(const AItem: TInstituicaoInscricaoItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  Result.AddPair('codigo_publico', AItem.CodigoPublico);
  Result.AddPair('id_turma', TJSONNumber.Create(AItem.IdTurma));
  Result.AddPair('turma_nome', AItem.TurmaNome);
  Result.AddPair('id_curso', TJSONNumber.Create(AItem.IdCurso));
  Result.AddPair('curso_nome', AItem.CursoNome);
  Result.AddPair('id_participante', TJSONNumber.Create(AItem.IdParticipante));
  Result.AddPair('participante_nome', AItem.ParticipanteNome);
  Result.AddPair('origem', AItem.Origem);
  Result.AddPair('situacao', AItem.Situacao);
  Result.AddPair('inscrito_em', ISODateTime(AItem.InscritoEm));

  if AItem.TemConfirmadoEm then
    Result.AddPair('confirmado_em', ISODateTime(AItem.ConfirmadoEm))
  else
    Result.AddPair('confirmado_em', TJSONNull.Create);

  if AItem.TemCanceladoEm then
    Result.AddPair('cancelado_em', ISODateTime(AItem.CanceladoEm))
  else
    Result.AddPair('cancelado_em', TJSONNull.Create);

  if Trim(AItem.MotivoCancelamento).IsEmpty then
    Result.AddPair('motivo_cancelamento', TJSONNull.Create)
  else
    Result.AddPair('motivo_cancelamento', AItem.MotivoCancelamento);
end;

class procedure TInstituicaoInscricaoAprovacaoController.Registry;
begin
  THorse.Post(
    '/v1/certifica/instituicao/inscricoes/:id/aprovar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TInstituicaoInscricaoItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        Item := TInstituicaoInscricaoAprovacaoService.Aprovar(
          Claims.IdInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0),
          Claims.IdUsuarioInstituicao
        );
        try
          TAppResponse.Ok(Res, InscricaoJson(Item), 'Inscrição aprovada com sucesso.');
        finally
          Item.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/instituicao/inscricoes/:id/rejeitar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      BodyValue: TJSONValue;
      Body: TJSONObject;
      Motivo: string;
      V: TJSONValue;
      Item: TInstituicaoInscricaoItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        BodyValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (BodyValue is TJSONObject) then
        begin
          BodyValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := BodyValue as TJSONObject;
        try
          Motivo := '';
          V := Body.GetValue('motivo');
          if (V <> nil) and not (V is TJSONNull) then
            Motivo := V.Value;
        finally
          Body.Free;
        end;

        Item := TInstituicaoInscricaoAprovacaoService.Rejeitar(
          Claims.IdInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0),
          Claims.IdUsuarioInstituicao,
          Motivo
        );
        try
          TAppResponse.Ok(Res, InscricaoJson(Item), 'Inscrição rejeitada com sucesso.');
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
