unit InstituicaoCertificado.Controller;

interface

type
  TInstituicaoCertificadoController = class
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
  App.RequestInfo,
  App.RateLimit,
  InstituicaoPermissao.Service,
  InstituicaoCertificado.Model,
  InstituicaoCertificado.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  const APermissao: string;
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

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto de instituição.'
    );

    Exit;
  end;

  TInstituicaoPermissaoService.Exigir(AClaims.IdInstituicao,
    AClaims.IdUsuarioInstituicao, APermissao);
  Result := True;
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: string = ''
): string;
var
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    Valor.Value;
end;

function JsonInt64(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Int64 = 0
): Int64;
var
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    StrToInt64Def(
      Valor.Value,
      ADefault
    );
end;

function JsonInteger(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Integer = 0
): Integer;
begin
  Result :=
    Integer(
      JsonInt64(
        AObj,
        ANome,
        ADefault
      )
    );
end;

function JsonBoolean(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Boolean
): Boolean;
var
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    SameText(
      Valor.Value,
      'true'
    ) or
    SameText(
      Valor.Value,
      '1'
    );
end;

function TemJsonValor(
  const AObj: TJSONObject;
  const ANome: string
): Boolean;
var
  Valor: TJSONValue;
begin
  Valor :=
    AObj.GetValue(
      ANome
    );

  Result :=
    (Valor <> nil) and
    not (Valor is TJSONNull);
end;

function DataHoraISO(
  const AData: TDateTime
): string;
begin
  Result :=
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AData
    );
end;

procedure AddNullableString(
  const AObj: TJSONObject;
  const ANome,
        AValor: string
);
begin
  if Trim(AValor).IsEmpty then
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    )
  else
    AObj.AddPair(
      ANome,
      AValor
    );
end;

procedure AddNullableDateTime(
  const AObj: TJSONObject;
  const ANome: string;
  const ATemValor: Boolean;
  const AValor: TDateTime
);
begin
  if ATemValor then
    AObj.AddPair(
      ANome,
      DataHoraISO(
        AValor
      )
    )
  else
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    );
end;

procedure AddJsonRawOrNull(
  const AObj: TJSONObject;
  const ANome,
        AJson: string
);
var
  Valor: TJSONValue;
begin
  if Trim(AJson).IsEmpty then
  begin
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    );

    Exit;
  end;

  Valor :=
    TJSONObject.ParseJSONValue(
      AJson
    );

  if Valor = nil then
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    )
  else
    AObj.AddPair(
      ANome,
      Valor
    );
end;

function ConfiguracaoParaJson(
  const AConfig: TCertificadoConfiguracao
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'configurada',
    TJSONBool.Create(
      AConfig.Existe
    )
  );

  if AConfig.TemIdModeloPadrao then
    Result.AddPair(
      'id_modelo_padrao',
      TJSONNumber.Create(
        AConfig.IdModeloPadrao
      )
    )
  else
    Result.AddPair(
      'id_modelo_padrao',
      TJSONNull.Create
    );

  AddNullableString(
    Result,
    'prefixo',
    AConfig.Prefixo
  );

  Result.AddPair(
    'usar_ano',
    TJSONBool.Create(
      AConfig.UsarAno
    )
  );

  Result.AddPair(
    'digitos_sequencia',
    TJSONNumber.Create(
      AConfig.DigitosSequencia
    )
  );

  Result.AddPair(
    'texto_validacao',
    AConfig.TextoValidacao
  );
end;

function CertificadoParaJson(
  const AItem: TCertificadoItem;
  const AIncluirCodigoValidacao: Boolean
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(
      AItem.Id
    )
  );

  Result.AddPair(
    'id_inscricao',
    TJSONNumber.Create(
      AItem.IdInscricao
    )
  );

  Result.AddPair(
    'id_turma',
    TJSONNumber.Create(
      AItem.IdTurma
    )
  );

  Result.AddPair(
    'id_participante',
    TJSONNumber.Create(
      AItem.IdParticipante
    )
  );

  Result.AddPair(
    'id_curso',
    TJSONNumber.Create(
      AItem.IdCurso
    )
  );

  if AItem.TemIdModelo then
    Result.AddPair(
      'id_modelo',
      TJSONNumber.Create(
        AItem.IdModelo
      )
    )
  else
    Result.AddPair(
      'id_modelo',
      TJSONNull.Create
    );

  AddNullableString(
    Result,
    'modelo_nome',
    AItem.ModeloNome
  );

  if AItem.TemIdCertificadoOrigem then
    Result.AddPair(
      'id_certificado_origem',
      TJSONNumber.Create(
        AItem.IdCertificadoOrigem
      )
    )
  else
    Result.AddPair(
      'id_certificado_origem',
      TJSONNull.Create
    );

  Result.AddPair(
    'numero_publico',
    AItem.NumeroPublico
  );

  if AIncluirCodigoValidacao then
    Result.AddPair(
      'codigo_validacao',
      AItem.CodigoValidacao
    );

  Result.AddPair(
    'versao',
    TJSONNumber.Create(
      AItem.Versao
    )
  );

  Result.AddPair(
    'situacao',
    AItem.Situacao
  );

  AddNullableDateTime(
    Result,
    'emitido_em',
    AItem.TemEmitidoEm,
    AItem.EmitidoEm
  );

  AddNullableDateTime(
    Result,
    'cancelado_em',
    AItem.TemCanceladoEm,
    AItem.CanceladoEm
  );

  AddNullableString(
    Result,
    'motivo_cancelamento',
    AItem.MotivoCancelamento
  );

  AddNullableString(
    Result,
    'motivo_reemissao',
    AItem.MotivoReemissao
  );

  Result.AddPair(
    'participante_nome',
    AItem.ParticipanteNome
  );

  Result.AddPair(
    'curso_nome',
    AItem.CursoNome
  );

  Result.AddPair(
    'instituicao_nome',
    AItem.InstituicaoNome
  );

  Result.AddPair(
    'carga_horaria_minutos',
    TJSONNumber.Create(
      AItem.CargaHorariaMinutos
    )
  );

  Result.AddPair(
    'data_conclusao',
    DataHoraISO(
      AItem.DataConclusao
    )
  );

  AddNullableString(
    Result,
    'pdf_storage_key',
    AItem.PdfStorageKey
  );

  AddNullableString(
    Result,
    'pdf_sha256',
    AItem.PdfSha256
  );

  if AItem.TemPdfTamanhoBytes then
    Result.AddPair(
      'pdf_tamanho_bytes',
      TJSONNumber.Create(
        AItem.PdfTamanhoBytes
      )
    )
  else
    Result.AddPair(
      'pdf_tamanho_bytes',
      TJSONNull.Create
    );

  AddNullableDateTime(
    Result,
    'pdf_gerado_em',
    AItem.TemPdfGeradoEm,
    AItem.PdfGeradoEm
  );

  if AItem.TemEmitidoPor then
    Result.AddPair(
      'emitido_por',
      TJSONNumber.Create(
        AItem.EmitidoPor
      )
    )
  else
    Result.AddPair(
      'emitido_por',
      TJSONNull.Create
    );

  AddNullableString(
    Result,
    'emitido_por_nome',
    AItem.EmitidoPorNome
  );

  Result.AddPair(
    'criado_em',
    DataHoraISO(
      AItem.CriadoEm
    )
  );

  Result.AddPair(
    'atualizado_em',
    DataHoraISO(
      AItem.AtualizadoEm
    )
  );
end;

function CertificadoPublicoParaJson(
  const AItem: TCertificadoItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'numero_publico',
    AItem.NumeroPublico
  );

  Result.AddPair(
    'situacao',
    AItem.Situacao
  );

  Result.AddPair(
    'participante_nome',
    AItem.ParticipanteNome
  );

  Result.AddPair(
    'curso_nome',
    AItem.CursoNome
  );

  Result.AddPair(
    'instituicao_nome',
    AItem.InstituicaoNome
  );

  Result.AddPair(
    'carga_horaria_minutos',
    TJSONNumber.Create(
      AItem.CargaHorariaMinutos
    )
  );

  Result.AddPair(
    'data_conclusao',
    DataHoraISO(
      AItem.DataConclusao
    )
  );

  Result.AddPair(
    'versao',
    TJSONNumber.Create(
      AItem.Versao
    )
  );

  AddNullableDateTime(
    Result,
    'emitido_em',
    AItem.TemEmitidoEm,
    AItem.EmitidoEm
  );

  AddNullableDateTime(
    Result,
    'cancelado_em',
    AItem.TemCanceladoEm,
    AItem.CanceladoEm
  );
end;

class procedure TInstituicaoCertificadoController.Registry;
begin

  // Configuração deve ser registrada antes de /certificados/:id.
  THorse.Get(
    '/v1/certifica/instituicao/certificados/configuracao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Config: TCertificadoConfiguracao;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'certificado.configurar',
          Claims
        ) then
          Exit;

        Config :=
          TInstituicaoCertificadoService.ObterConfiguracao(
            Claims.IdInstituicao
          );

        try
          TAppResponse.Ok(
            Res,
            ConfiguracaoParaJson(
              Config
            ),
            'Configuração de certificados carregada com sucesso.'
          );

        finally
          Config.Free;
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


  THorse.Put(
    '/v1/certifica/instituicao/certificados/configuracao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Config: TCertificadoConfiguracao;
      TemModelo: Boolean;
      IdModelo: Int64;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'certificado.configurar',
          Claims
        ) then
          Exit;

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

        Body :=
          JsonValue as TJSONObject;

        try
          TemModelo :=
            TemJsonValor(
              Body,
              'id_modelo_padrao'
            );

          IdModelo :=
            JsonInt64(
              Body,
              'id_modelo_padrao',
              0
            );

          Config :=
            TInstituicaoCertificadoService.SalvarConfiguracao(
              Claims.IdInstituicao,
              IdModelo,
              TemModelo,
              JsonString(
                Body,
                'prefixo'
              ),
              JsonBoolean(
                Body,
                'usar_ano',
                True
              ),
              JsonInteger(
                Body,
                'digitos_sequencia',
                6
              ),
              JsonString(
                Body,
                'texto_validacao',
                'Valide este certificado'
              )
            );

        finally
          Body.Free;
        end;

        try
          TAppResponse.Ok(
            Res,
            ConfiguracaoParaJson(
              Config
            ),
            'Configuração de certificados salva com sucesso.'
          );

        finally
          Config.Free;
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


  THorse.Get(
    '/v1/certifica/instituicao/certificados',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TCertificadoLista;
      Item: TCertificadoItem;
      Itens: TJSONArray;
      Paginacao: TJSONObject;
      Dados: TJSONObject;
      Pagina: Integer;
      PorPagina: Integer;
      IdTurma: Int64;
      IdParticipante: Int64;
      TotalPaginas: Integer;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'certificado.visualizar',
          Claims
        ) then
          Exit;

        Pagina :=
          StrToIntDef(
            Req.Query.Items[
              'page'
            ],
            1
          );

        PorPagina :=
          StrToIntDef(
            Req.Query.Items[
              'page_size'
            ],
            20
          );

        IdTurma :=
          StrToInt64Def(
            Req.Query.Items[
              'id_turma'
            ],
            0
          );

        IdParticipante :=
          StrToInt64Def(
            Req.Query.Items[
              'id_participante'
            ],
            0
          );

        Resultado :=
          TInstituicaoCertificadoService.Listar(
            Claims.IdInstituicao,
            Req.Query.Items[
              'busca'
            ],
            Req.Query.Items[
              'situacao'
            ],
            IdTurma,
            IdParticipante,
            Pagina,
            PorPagina
          );

        try
          Itens :=
            TJSONArray.Create;

          for Item in Resultado.Itens do
            Itens.AddElement(
              CertificadoParaJson(
                Item,
                False
              )
            );

          if Resultado.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas :=
              (
                Resultado.Total +
                Resultado.PorPagina -
                1
              ) div Resultado.PorPagina;

          Paginacao :=
            TJSONObject.Create;

          Paginacao.AddPair(
            'pagina',
            TJSONNumber.Create(
              Resultado.Pagina
            )
          );

          Paginacao.AddPair(
            'por_pagina',
            TJSONNumber.Create(
              Resultado.PorPagina
            )
          );

          Paginacao.AddPair(
            'total',
            TJSONNumber.Create(
              Resultado.Total
            )
          );

          Paginacao.AddPair(
            'total_paginas',
            TJSONNumber.Create(
              TotalPaginas
            )
          );

          Dados :=
            TJSONObject.Create;

          Dados.AddPair(
            'itens',
            Itens
          );

          Dados.AddPair(
            'paginacao',
            Paginacao
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Certificados carregados com sucesso.'
          );

        finally
          Resultado.Free;
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


  THorse.Post(
    '/v1/certifica/instituicao/inscricoes/:id_inscricao/certificados',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInscricao: Int64;
      Certificado: TCertificadoItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'certificado.emitir',
          Claims
        ) then
          Exit;

        IdInscricao :=
          StrToInt64Def(
            Req.Params.Items[
              'id_inscricao'
            ],
            0
          );

        Certificado :=
          TInstituicaoCertificadoService.EmitirPendente(
            Claims.IdInstituicao,
            IdInscricao,
            Claims.IdUsuarioInstituicao
          );

        try
          TAppResponse.Ok(
            Res,
            CertificadoParaJson(
              Certificado,
              True
            ),
            'Certificado criado e aguardando geração do PDF.'
          );

        finally
          Certificado.Free;
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


  THorse.Get(
    '/v1/certifica/instituicao/certificados/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCertificado: Int64;
      Certificado: TCertificadoItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'certificado.visualizar',
          Claims
        ) then
          Exit;

        IdCertificado :=
          StrToInt64Def(
            Req.Params.Items[
              'id'
            ],
            0
          );

        Certificado :=
          TInstituicaoCertificadoService.BuscarPorId(
            Claims.IdInstituicao,
            IdCertificado
          );

        try
          TAppResponse.Ok(
            Res,
            CertificadoParaJson(
              Certificado,
              True
            ),
            'Certificado carregado com sucesso.'
          );

        finally
          Certificado.Free;
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


  // Compatibilidade explícita: metadados do cliente não podem emitir um PDF.
  THorse.Post('/v1/certifica/instituicao/certificados/:id/pdf-finalizado',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
    begin
      try
        if not AutorizarInstituicao(Req, Res, 'certificado.emitir', Claims) then Exit;
        TAppErrors.RaiseBadRequest(
          'Finalização manual desabilitada. Utilize a operação gerar-pdf.');
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Patch(
    '/v1/certifica/instituicao/certificados/:id/cancelar',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCertificado: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Motivo: string;
      Certificado: TCertificadoItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'certificado.cancelar',
          Claims
        ) then
          Exit;

        IdCertificado :=
          StrToInt64Def(
            Req.Params.Items[
              'id'
            ],
            0
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

        Body :=
          JsonValue as TJSONObject;

        try
          Motivo :=
            JsonString(
              Body,
              'motivo'
            );

        finally
          Body.Free;
        end;

        Certificado :=
          TInstituicaoCertificadoService.Cancelar(
            Claims.IdInstituicao,
            IdCertificado,
            Claims.IdUsuarioInstituicao,
            Motivo
          );

        try
          TAppResponse.Ok(
            Res,
            CertificadoParaJson(
              Certificado,
              True
            ),
            'Certificado cancelado com sucesso.'
          );

        finally
          Certificado.Free;
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


  THorse.Post(
    '/v1/certifica/instituicao/certificados/:id/reemitir',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCertificado: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Motivo: string;
      Certificado: TCertificadoItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'certificado.emitir',
          Claims
        ) then
          Exit;

        IdCertificado :=
          StrToInt64Def(
            Req.Params.Items[
              'id'
            ],
            0
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

        Body :=
          JsonValue as TJSONObject;

        try
          Motivo :=
            JsonString(
              Body,
              'motivo'
            );

        finally
          Body.Free;
        end;

        Certificado :=
          TInstituicaoCertificadoService.Reemitir(
            Claims.IdInstituicao,
            IdCertificado,
            Claims.IdUsuarioInstituicao,
            Motivo
          );

        try
          TAppResponse.Ok(
            Res,
            CertificadoParaJson(
              Certificado,
              True
            ),
            'Reemissão criada e aguardando geração do PDF.'
          );

        finally
          Certificado.Free;
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


  THorse.Get(
    '/v1/certifica/instituicao/certificados/:id/historico',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCertificado: Int64;
      Historico: TCertificadoHistoricoLista;
      Item: TCertificadoHistoricoItem;
      Itens: TJSONArray;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          'certificado.visualizar',
          Claims
        ) then
          Exit;

        IdCertificado :=
          StrToInt64Def(
            Req.Params.Items[
              'id'
            ],
            0
          );

        Historico :=
          TInstituicaoCertificadoService.ListarHistorico(
            Claims.IdInstituicao,
            IdCertificado
          );

        try
          Itens :=
            TJSONArray.Create;

          for Item in Historico do
          begin
            Dados :=
              TJSONObject.Create;

            Dados.AddPair(
              'id',
              TJSONNumber.Create(
                Item.Id
              )
            );

            Dados.AddPair(
              'evento',
              Item.Evento
            );

            AddNullableString(
              Dados,
              'descricao',
              Item.Descricao
            );

            AddJsonRawOrNull(
              Dados,
              'dados',
              Item.Dados
            );

            if Item.TemIdUsuarioInstituicao then
              Dados.AddPair(
                'id_usuario_instituicao',
                TJSONNumber.Create(
                  Item.IdUsuarioInstituicao
                )
              )
            else
              Dados.AddPair(
                'id_usuario_instituicao',
                TJSONNull.Create
              );

            AddNullableString(
              Dados,
              'usuario_nome',
              Item.UsuarioNome
            );

            Dados.AddPair(
              'criado_em',
              DataHoraISO(
                Item.CriadoEm
              )
            );

            Itens.AddElement(
              Dados
            );
          end;

          Dados :=
            TJSONObject.Create;

          Dados.AddPair(
            'itens',
            Itens
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Histórico do certificado carregado com sucesso.'
          );

        finally
          Historico.Free;
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


  // Rota pública: não usa JWT nem recebe id_instituicao do cliente.
  THorse.Get(
    '/v1/certifica/publico/certificados/validar/:codigo',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Codigo: string;
      IP: string;
      UserAgent: string;
      Validacao: TCertificadoValidacaoPublica;
      Dados: TJSONObject;
    begin
      try
        Res.RawWebResponse.SetCustomHeader('Cache-Control', 'no-store');

        if not TAppRateLimit.EnforceIP(
          Req,
          Res,
          'publico-certificado-validar',
          60,
          60
        ) then
          Exit;

        Codigo := Trim(Req.Params.Items['codigo']);

        if Length(Codigo) <> 64 then
          TAppErrors.RaiseBadRequest('Código de validação inválido.');

        IP := TAppRequestInfo.GetIP(Req);
        UserAgent := TAppRequestInfo.GetUserAgent(Req);

        Validacao :=
          TInstituicaoCertificadoService.ValidarPublicamente(
            Codigo,
            IP,
            UserAgent
          );

        try
          Dados :=
            TJSONObject.Create;

          Dados.AddPair(
            'resultado',
            Validacao.Resultado
          );

          Dados.AddPair(
            'encontrado',
            TJSONBool.Create(
              Validacao.Encontrado
            )
          );

          if Validacao.Encontrado then
            Dados.AddPair(
              'certificado',
              CertificadoPublicoParaJson(
                Validacao.Certificado
              )
            )
          else
            Dados.AddPair(
              'certificado',
              TJSONNull.Create
            );

          TAppResponse.Ok(
            Res,
            Dados,
            'Validação de certificado concluída.'
          );

        finally
          Validacao.Free;
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
