unit LgpdSolicitacao.Controller;

interface

type
  TLgpdSolicitacaoController = class
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
  App.RateLimit,
  APP.Errors,
  InstituicaoPermissao.Service,
  LgpdSolicitacao.Model,
  LgpdSolicitacao.Service;

function AutorizarAluno(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(
    Req,
    Res,
    AClaims
  ) then
    Exit;

  if (AClaims.IdInstituicao <= 0) or
     (AClaims.IdUsuarioInstituicao <= 0) then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto válido da instituição.'
    );
    Exit;
  end;

  Result := True;
end;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  const APermissao: string;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not AutorizarAluno(
    Req,
    Res,
    AClaims
  ) then
    Exit;

  TInstituicaoPermissaoService.Exigir(
    AClaims.IdInstituicao,
    AClaims.IdUsuarioInstituicao,
    APermissao
  );

  Result := True;
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string
): string;
var
  Valor: TJSONValue;
begin
  Result := '';
  Valor := AObj.GetValue(ANome);

  if (Valor <> nil) and
     not (Valor is TJSONNull) then
    Result := Valor.Value;
end;

function ISODateTime(
  const AValue: TDateTime
): string;
begin
  Result :=
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AValue
    );
end;

function ItemJson(
  const AItem: TLgpdSolicitacaoItem;
  const AExibirParticipante: Boolean
): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  Result.AddPair('protocolo', AItem.Protocolo);
  Result.AddPair('tipo', AItem.Tipo);
  Result.AddPair('situacao', AItem.Situacao);

  if Trim(AItem.Descricao).IsEmpty then
    Result.AddPair('descricao', TJSONNull.Create)
  else
    Result.AddPair('descricao', AItem.Descricao);

  if Trim(AItem.Resposta).IsEmpty then
    Result.AddPair('resposta', TJSONNull.Create)
  else
    Result.AddPair('resposta', AItem.Resposta);

  Result.AddPair(
    'solicitado_em',
    ISODateTime(AItem.SolicitadoEm)
  );

  Result.AddPair(
    'atualizado_em',
    ISODateTime(AItem.AtualizadoEm)
  );

  if AItem.TemConcluidoEm then
    Result.AddPair(
      'concluido_em',
      ISODateTime(AItem.ConcluidoEm)
    )
  else
    Result.AddPair(
      'concluido_em',
      TJSONNull.Create
    );

  if Trim(AItem.ResponsavelNome).IsEmpty then
    Result.AddPair(
      'responsavel_nome',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'responsavel_nome',
      AItem.ResponsavelNome
    );

  if AExibirParticipante then
  begin
    Result.AddPair(
      'id_participante',
      TJSONNumber.Create(AItem.IdParticipante)
    );
    Result.AddPair(
      'participante_nome',
      AItem.ParticipanteNome
    );
  end;
end;

function ListaJson(
  const AResultado: TLgpdSolicitacaoResultado;
  const AExibirParticipante: Boolean
): TJSONObject;
var
  Arr: TJSONArray;
  Item: TLgpdSolicitacaoItem;
  Pag: TJSONObject;
  TotalPaginas: Integer;
begin
  Arr := TJSONArray.Create;

  for Item in AResultado.Itens do
    Arr.AddElement(
      ItemJson(
        Item,
        AExibirParticipante
      )
    );

  if AResultado.Total = 0 then
    TotalPaginas := 0
  else
    TotalPaginas :=
      (AResultado.Total + AResultado.PorPagina - 1)
      div AResultado.PorPagina;

  Pag := TJSONObject.Create;
  Pag.AddPair(
    'pagina',
    TJSONNumber.Create(AResultado.Pagina)
  );
  Pag.AddPair(
    'por_pagina',
    TJSONNumber.Create(AResultado.PorPagina)
  );
  Pag.AddPair(
    'total',
    TJSONNumber.Create(AResultado.Total)
  );
  Pag.AddPair(
    'total_paginas',
    TJSONNumber.Create(TotalPaginas)
  );

  Result := TJSONObject.Create;
  Result.AddPair('itens', Arr);
  Result.AddPair('paginacao', Pag);
end;

class procedure TLgpdSolicitacaoController.Registry;
begin
  THorse.Get(
    '/v1/certifica/aluno/lgpd/solicitacoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Resultado: TLgpdSolicitacaoResultado;
    begin
      Res.RawWebResponse.SetCustomHeader(
        'Cache-Control',
        'private, no-store'
      );

      try
        if not AutorizarAluno(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Resultado :=
          TLgpdSolicitacaoService.ListarMinhas(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao
          );
        try
          TAppResponse.Ok(
            Res,
            ListaJson(Resultado, False),
            'Solicitações LGPD carregadas com sucesso.'
          );
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/aluno/lgpd/solicitacoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Tipo, Descricao: string;
      Item: TLgpdSolicitacaoItem;
    begin
      Res.RawWebResponse.SetCustomHeader(
        'Cache-Control',
        'private, no-store'
      );

      try
        if not AutorizarAluno(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if not TAppRateLimit.EnforceIdentity(
          Req,
          Res,
          'aluno-lgpd-solicitar',
          IntToStr(Claims.IdInstituicao) + '|' +
          IntToStr(Claims.IdUsuarioInstituicao),
          10,
          3600
        ) then
          Exit;

        if Length(Req.Body) > 8192 then
          TAppErrors.RaiseBadRequest(
            'Requisição inválida.'
          );

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body := JsonValue as TJSONObject;
        try
          Tipo := JsonString(Body, 'tipo');
          Descricao := JsonString(Body, 'descricao');
        finally
          Body.Free;
        end;

        Item :=
          TLgpdSolicitacaoService.Solicitar(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            Tipo,
            Descricao
          );
        try
          TAppResponse.Created(
            Res,
            ItemJson(Item, False),
            'Solicitação LGPD registrada com sucesso.'
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

  THorse.Patch(
    '/v1/certifica/aluno/lgpd/solicitacoes/:id/cancelar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TLgpdSolicitacaoItem;
    begin
      try
        if not AutorizarAluno(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Item :=
          TLgpdSolicitacaoService.CancelarMinha(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            StrToInt64Def(
              Req.Params.Items['id'],
              0
            )
          );
        try
          TAppResponse.Ok(
            Res,
            ItemJson(Item, False),
            'Solicitação cancelada com sucesso.'
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

  THorse.Get(
    '/v1/certifica/instituicao/lgpd/solicitacoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Resultado: TLgpdSolicitacaoResultado;
    begin
      Res.RawWebResponse.SetCustomHeader(
        'Cache-Control',
        'private, no-store'
      );

      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'lgpd.visualizar',
          Claims
        ) then
          Exit;

        Resultado :=
          TLgpdSolicitacaoService.ListarInstituicao(
            Claims.IdInstituicao,
            Req.Query.Items['busca'],
            Req.Query.Items['tipo'],
            Req.Query.Items['situacao'],
            StrToIntDef(
              Req.Query.Items['page'],
              1
            ),
            StrToIntDef(
              Req.Query.Items['page_size'],
              50
            )
          );
        try
          TAppResponse.Ok(
            Res,
            ListaJson(Resultado, True),
            'Solicitações LGPD carregadas com sucesso.'
          );
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Patch(
    '/v1/certifica/instituicao/lgpd/solicitacoes/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao, Resposta: string;
      Item: TLgpdSolicitacaoItem;
    begin
      Res.RawWebResponse.SetCustomHeader(
        'Cache-Control',
        'private, no-store'
      );

      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'lgpd.gerenciar',
          Claims
        ) then
          Exit;

        if Length(Req.Body) > 16384 then
          TAppErrors.RaiseBadRequest(
            'Requisição inválida.'
          );

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body := JsonValue as TJSONObject;
        try
          Situacao := JsonString(Body, 'situacao');
          Resposta := JsonString(Body, 'resposta');
        finally
          Body.Free;
        end;

        Item :=
          TLgpdSolicitacaoService.AtualizarInstituicao(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            StrToInt64Def(
              Req.Params.Items['id'],
              0
            ),
            Situacao,
            Resposta
          );
        try
          TAppResponse.Ok(
            Res,
            ItemJson(Item, True),
            'Solicitação LGPD atualizada com sucesso.'
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
