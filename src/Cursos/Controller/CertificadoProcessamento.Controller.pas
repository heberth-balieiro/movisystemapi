unit CertificadoProcessamento.Controller;

interface

type
  TCertificadoProcessamentoController = class
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
  CertificadoProcessamento.Model,
  CertificadoProcessamento.Service;

function DataHoraISO(const AData: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', AData);
end;

function ItemJson(const AItem: TCertificadoProcessamentoItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  Result.AddPair('id_certificado', TJSONNumber.Create(AItem.IdCertificado));
  Result.AddPair('numero_publico', AItem.NumeroPublico);
  Result.AddPair('participante_nome', AItem.ParticipanteNome);
  Result.AddPair('curso_nome', AItem.CursoNome);
  Result.AddPair('situacao', AItem.Situacao);
  Result.AddPair('certificado_situacao', AItem.CertificadoSituacao);
  Result.AddPair('tentativas', TJSONNumber.Create(AItem.Tentativas));

  if Trim(AItem.UltimoErro).IsEmpty then
    Result.AddPair('ultimo_erro', TJSONNull.Create)
  else
    Result.AddPair('ultimo_erro', AItem.UltimoErro);

  Result.AddPair('criado_em', DataHoraISO(AItem.CriadoEm));
  Result.AddPair('atualizado_em', DataHoraISO(AItem.AtualizadoEm));

  if AItem.TemProximaTentativaEm then
    Result.AddPair('proxima_tentativa_em', DataHoraISO(AItem.ProximaTentativaEm))
  else
    Result.AddPair('proxima_tentativa_em', TJSONNull.Create);

  if AItem.TemProcessandoEm then
    Result.AddPair('processando_em', DataHoraISO(AItem.ProcessandoEm))
  else
    Result.AddPair('processando_em', TJSONNull.Create);

  if AItem.TemConcluidoEm then
    Result.AddPair('concluido_em', DataHoraISO(AItem.ConcluidoEm))
  else
    Result.AddPair('concluido_em', TJSONNull.Create);
end;

class procedure TCertificadoProcessamentoController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/certificados/processamento',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TCertificadoProcessamentoLista;
      Item: TCertificadoProcessamentoItem;
      Itens: TJSONArray;
      Dados, Paginacao: TJSONObject;
      Pagina, PorPagina, TotalPaginas: Integer;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then Exit;

        Pagina := StrToIntDef(Req.Query.Items['page'], 1);
        PorPagina := StrToIntDef(Req.Query.Items['page_size'], 20);

        Lista := TCertificadoProcessamentoService.Listar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Req.Query.Items['busca'],
          Req.Query.Items['situacao'],
          Pagina,
          PorPagina
        );
        try
          Itens := TJSONArray.Create;
          for Item in Lista.Itens do
            Itens.AddElement(ItemJson(Item));

          if Lista.Total = 0 then TotalPaginas := 0
          else TotalPaginas := (Lista.Total + Lista.PorPagina - 1) div Lista.PorPagina;

          Paginacao := TJSONObject.Create;
          Paginacao.AddPair('pagina', TJSONNumber.Create(Lista.Pagina));
          Paginacao.AddPair('por_pagina', TJSONNumber.Create(Lista.PorPagina));
          Paginacao.AddPair('total', TJSONNumber.Create(Lista.Total));
          Paginacao.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', Itens);
          Dados.AddPair('paginacao', Paginacao);

          TAppResponse.Ok(Res, Dados, 'Processamentos de certificados carregados com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/instituicao/certificados/:id/reprocessar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TCertificadoProcessamentoItem;
      IdCertificado: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then Exit;

        IdCertificado := StrToInt64Def(Req.Params.Items['id'], 0);

        Item := TCertificadoProcessamentoService.Reprocessar(
          Claims.IdInstituicao,
          IdCertificado,
          Claims.IdUsuarioInstituicao
        );
        try
          TAppResponse.Ok(
            Res,
            ItemJson(Item),
            'Certificado reenfileirado para processamento.'
          );
        finally
          Item.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
