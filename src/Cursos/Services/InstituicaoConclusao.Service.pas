unit InstituicaoConclusao.Service;

interface

uses
  Uni,
  InstituicaoConclusao.Model;

type
  TInstituicaoConclusaoService = class
  private
    class function JsonNumero(
      const AJson,
            ACampo: string;
      const ADefault: Double;
      out AEncontrado: Boolean
    ): Double; static;

    class function JsonBooleano(
      const AJson,
            ACampo: string;
      const ADefault: Boolean
    ): Boolean; static;

    class function ResultadoPresencaJson(
      const AMetrica: TConclusaoMetricaPresenca;
      const APercentualMinimo: Double;
      const AJustificadaContaComoPresenca: Boolean
    ): string; static;

    class function ResultadoAulasJson(
      const AMetrica: TConclusaoMetricaAulas;
      const APercentualMinimo: Double
    ): string; static;

    class function ResultadoPendenteJson(
      const AMotivo: string
    ): string; static;

    class function MontarResumo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TConclusaoResumo; static;

  public
    class function Consultar(
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TConclusaoResumo; static;

    class function Avaliar(
      const AIdInstituicao,
            AIdInscricao,
            AUsuarioInstituicao: Int64
    ): TConclusaoResumo; static;

    class function AvaliarCriterioManual(
      const AIdInstituicao,
            AIdInscricao,
            AIdCriterio,
            AUsuarioInstituicao: Int64;
      const ADados: TConclusaoAvaliacaoManual
    ): TConclusaoResumo; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.JSON,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoConclusao.DAO,
  InstituicaoInscricao.DAO,
  InstituicaoInscricao.Model;

class function TInstituicaoConclusaoService.JsonNumero(
  const AJson,
        ACampo: string;
  const ADefault: Double;
  out AEncontrado: Boolean
): Double;
var
  Raiz: TJSONValue;
  Valor: TJSONValue;
  Objeto: TJSONObject;
  Texto: string;
begin
  Result := ADefault;
  AEncontrado := False;

  if Trim(AJson).IsEmpty then
    Exit;

  Raiz :=
    TJSONObject.ParseJSONValue(
      AJson
    );

  try
    if not (Raiz is TJSONObject) then
      Exit;

    Objeto :=
      Raiz as TJSONObject;

    Valor :=
      Objeto.GetValue(
        ACampo
      );

    if (Valor = nil) or
       (Valor is TJSONNull) then
      Exit;

    Texto :=
      StringReplace(
        Valor.Value,
        '.',
        FormatSettings.DecimalSeparator,
        [rfReplaceAll]
      );

    if not TryStrToFloat(
      Texto,
      Result
    ) then
      Result := ADefault
    else
      AEncontrado := True;

  finally
    Raiz.Free;
  end;
end;

class function TInstituicaoConclusaoService.JsonBooleano(
  const AJson,
        ACampo: string;
  const ADefault: Boolean
): Boolean;
var
  Raiz: TJSONValue;
  Valor: TJSONValue;
  Objeto: TJSONObject;
begin
  Result := ADefault;

  if Trim(AJson).IsEmpty then
    Exit;

  Raiz :=
    TJSONObject.ParseJSONValue(
      AJson
    );

  try
    if not (Raiz is TJSONObject) then
      Exit;

    Objeto :=
      Raiz as TJSONObject;

    Valor :=
      Objeto.GetValue(
        ACampo
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

  finally
    Raiz.Free;
  end;
end;

class function TInstituicaoConclusaoService.ResultadoPresencaJson(
  const AMetrica: TConclusaoMetricaPresenca;
  const APercentualMinimo: Double;
  const AJustificadaContaComoPresenca: Boolean
): string;
var
  Obj: TJSONObject;
begin
  Obj :=
    TJSONObject.Create;

  try
    Obj.AddPair(
      'percentual_obtido',
      TJSONNumber.Create(
        AMetrica.Percentual
      )
    );

    Obj.AddPair(
      'percentual_minimo',
      TJSONNumber.Create(
        APercentualMinimo
      )
    );

    Obj.AddPair(
      'minutos_previstos',
      TJSONNumber.Create(
        AMetrica.MinutosPrevistos
      )
    );

    Obj.AddPair(
      'minutos_computados',
      TJSONNumber.Create(
        AMetrica.MinutosComputados
      )
    );

    Obj.AddPair(
      'justificada_como_presenca',
      TJSONBool.Create(
        AJustificadaContaComoPresenca
      )
    );

    Result :=
      Obj.ToJSON;

  finally
    Obj.Free;
  end;
end;

class function TInstituicaoConclusaoService.ResultadoAulasJson(
  const AMetrica: TConclusaoMetricaAulas;
  const APercentualMinimo: Double
): string;
var
  Obj: TJSONObject;
begin
  Obj :=
    TJSONObject.Create;

  try
    Obj.AddPair(
      'percentual_obtido',
      TJSONNumber.Create(
        AMetrica.Percentual
      )
    );

    Obj.AddPair(
      'percentual_minimo',
      TJSONNumber.Create(
        APercentualMinimo
      )
    );

    Obj.AddPair(
      'aulas_obrigatorias',
      TJSONNumber.Create(
        AMetrica.TotalAulas
      )
    );

    Obj.AddPair(
      'aulas_concluidas',
      TJSONNumber.Create(
        AMetrica.AulasConcluidas
      )
    );

    Result :=
      Obj.ToJSON;

  finally
    Obj.Free;
  end;
end;

class function TInstituicaoConclusaoService.ResultadoPendenteJson(
  const AMotivo: string
): string;
var
  Obj: TJSONObject;
begin
  Obj :=
    TJSONObject.Create;

  try
    Obj.AddPair(
      'pendente',
      TJSONBool.Create(
        True
      )
    );

    Obj.AddPair(
      'motivo',
      AMotivo
    );

    Result :=
      Obj.ToJSON;

  finally
    Obj.Free;
  end;
end;

class function TInstituicaoConclusaoService.MontarResumo(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao: Int64
): TConclusaoResumo;
var
  Contexto: TConclusaoInscricaoContexto;
  Criterios: TConclusaoCriterioLista;
  Item: TConclusaoCriterioItem;
  InscricaoAtual: TInstituicaoInscricaoItem;
begin
  Result := nil;

  Contexto :=
    TInstituicaoConclusaoDAO.BuscarContexto(
      AConn,
      AIdInstituicao,
      AIdInscricao
    );

  try
    if Contexto = nil then
      TAppErrors.RaiseBadRequest(
        'Inscrição não encontrada.'
      );

    InscricaoAtual :=
      TInstituicaoInscricaoDAO.BuscarPorId(
        AConn,
        AIdInstituicao,
        AIdInscricao
      );

    try
      if InscricaoAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Inscrição não encontrada.'
        );

      Criterios :=
        TInstituicaoConclusaoDAO.ListarCriterios(
          AConn,
          AIdInstituicao,
          Contexto.IdTurma,
          AIdInscricao
        );

      try
        Result :=
          TConclusaoResumo.Create;

        Result.IdInscricao :=
          Contexto.IdInscricao;

        Result.IdTurma :=
          Contexto.IdTurma;

        Result.IdCurso :=
          Contexto.IdCurso;

        Result.ParticipanteNome :=
          Contexto.ParticipanteNome;

        Result.CursoNome :=
          Contexto.CursoNome;

        Result.TurmaNome :=
          Contexto.TurmaNome;

        Result.SituacaoInscricao :=
          InscricaoAtual.Situacao;

        Result.TemPercentualPresenca :=
          InscricaoAtual.TemPercentualPresenca;

        if Result.TemPercentualPresenca then
          Result.PercentualPresenca :=
            InscricaoAtual.PercentualPresenca;

        Result.PercentualProgresso :=
          InscricaoAtual.PercentualProgresso;

        Result.ElegivelCertificado :=
          InscricaoAtual.ElegivelCertificado;

        for Item in Criterios do
        begin
          if Item.Obrigatorio then
          begin
            Result.CriteriosObrigatorios :=
              Result.CriteriosObrigatorios +
              1;

            if not Item.TemAtendido then
              Result.CriteriosObrigatoriosPendentes :=
                Result.CriteriosObrigatoriosPendentes +
                1
            else if Item.Atendido then
              Result.CriteriosObrigatoriosAtendidos :=
                Result.CriteriosObrigatoriosAtendidos +
                1
            else
              Result.CriteriosObrigatoriosNaoAtendidos :=
                Result.CriteriosObrigatoriosNaoAtendidos +
                1;
          end;

        end;

        while Criterios.Count > 0 do
        begin
          Item :=
            Criterios.Extract(
              Criterios[0]
            );

          Result.Criterios.Add(
            Item
          );
        end;

      finally
        Criterios.Free;
      end;

    finally
      InscricaoAtual.Free;
    end;

  finally
    Contexto.Free;
  end;
end;

class function TInstituicaoConclusaoService.Consultar(
  const AIdInstituicao,
        AIdInscricao: Int64
): TConclusaoResumo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Inscrição inválida.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(
        ParamStr(0)
      ) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Result :=
      MontarResumo(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConclusaoService.Avaliar(
  const AIdInstituicao,
        AIdInscricao,
        AUsuarioInstituicao: Int64
): TConclusaoResumo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contexto: TConclusaoInscricaoContexto;
  Criterios: TConclusaoCriterioLista;
  Criterio: TConclusaoCriterioItem;
  MetricaPresenca: TConclusaoMetricaPresenca;
  MetricaAulas: TConclusaoMetricaAulas;
  PercentualMinimo: Double;
  EncontrouPercentual: Boolean;
  JustificadaContaComoPresenca: Boolean;
  ResultadoJson: string;
  TemAtendido: Boolean;
  Atendido: Boolean;
  TemCriterioPresenca: Boolean;
  CriteriosObrigatorios: Integer;
  ObrigatoriosAtendidos: Integer;
  ObrigatoriosPendentes: Integer;
  ObrigatoriosNaoAtendidos: Integer;
  Elegivel: Boolean;
  PercentualProgresso: Double;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Inscrição inválida.'
    );

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(
        ParamStr(0)
      ) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Contexto :=
      TInstituicaoConclusaoDAO.BuscarContexto(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

    try
      if Contexto = nil then
        TAppErrors.RaiseBadRequest(
          'Inscrição não encontrada.'
        );

      Criterios :=
        TInstituicaoConclusaoDAO.ListarCriterios(
          Conn,
          AIdInstituicao,
          Contexto.IdTurma,
          AIdInscricao
        );

      try
        TemCriterioPresenca := False;

        MetricaPresenca :=
          Default(
            TConclusaoMetricaPresenca
          );

        MetricaAulas :=
          TInstituicaoConclusaoDAO.CalcularAulas(
            Conn,
            AIdInstituicao,
            Contexto.IdTurma,
            Contexto.IdCurso,
            AIdInscricao
          );

        if MetricaAulas.TemAulasObrigatorias then
          PercentualProgresso :=
            MetricaAulas.Percentual
        else
          PercentualProgresso := 0;

        Conn.StartTransaction;

        try
          for Criterio in Criterios do
          begin
            if SameText(
              Criterio.Tipo,
              'PRESENCA_MINIMA'
            ) then
            begin
              TemCriterioPresenca := True;

              JustificadaContaComoPresenca :=
                JsonBooleano(
                  Criterio.Configuracao,
                  'justificada_como_presenca',
                  False
                );

              MetricaPresenca :=
                TInstituicaoConclusaoDAO.CalcularPresenca(
                  Conn,
                  AIdInstituicao,
                  Contexto.IdTurma,
                  AIdInscricao,
                  JustificadaContaComoPresenca
                );

              PercentualMinimo :=
                JsonNumero(
                  Criterio.Configuracao,
                  'percentual_minimo',
                  0,
                  EncontrouPercentual
                );

              if
                not EncontrouPercentual or
                (PercentualMinimo < 0) or
                (PercentualMinimo > 100)
              then
              begin
                TemAtendido := False;
                Atendido := False;

                ResultadoJson :=
                  ResultadoPendenteJson(
                    'O critério PRESENCA_MINIMA não possui percentual_minimo válido.'
                  );
              end
              else if not MetricaPresenca.TemBaseCalculo then
              begin
                TemAtendido := False;
                Atendido := False;

                ResultadoJson :=
                  ResultadoPendenteJson(
                    'Não existem encontros obrigatórios com carga horária para calcular a presença.'
                  );
              end
              else
              begin
                TemAtendido := True;

                Atendido :=
                  MetricaPresenca.Percentual >=
                  PercentualMinimo;

                ResultadoJson :=
                  ResultadoPresencaJson(
                    MetricaPresenca,
                    PercentualMinimo,
                    JustificadaContaComoPresenca
                  );
              end;

              TInstituicaoConclusaoDAO.SalvarResultadoAutomatico(
                Conn,
                AIdInstituicao,
                Contexto.IdTurma,
                AIdInscricao,
                Criterio.IdCriterio,
                TemAtendido,
                Atendido,
                ResultadoJson
              );
            end
            else if SameText(
              Criterio.Tipo,
              'AULAS_CONCLUIDAS'
            ) then
            begin
              PercentualMinimo :=
                JsonNumero(
                  Criterio.Configuracao,
                  'percentual_minimo',
                  100,
                  EncontrouPercentual
                );

              if not EncontrouPercentual then
                PercentualMinimo := 100;

              if
                (PercentualMinimo < 0) or
                (PercentualMinimo > 100)
              then
              begin
                TemAtendido := False;
                Atendido := False;

                ResultadoJson :=
                  ResultadoPendenteJson(
                    'O percentual_minimo de AULAS_CONCLUIDAS é inválido.'
                  );
              end
              else if not MetricaAulas.TemAulasObrigatorias then
              begin
                TemAtendido := False;
                Atendido := False;

                ResultadoJson :=
                  ResultadoPendenteJson(
                    'Não existem aulas obrigatórias ativas para avaliar.'
                  );
              end
              else
              begin
                TemAtendido := True;

                Atendido :=
                  MetricaAulas.Percentual >=
                  PercentualMinimo;

                ResultadoJson :=
                  ResultadoAulasJson(
                    MetricaAulas,
                    PercentualMinimo
                  );
              end;

              TInstituicaoConclusaoDAO.SalvarResultadoAutomatico(
                Conn,
                AIdInstituicao,
                Contexto.IdTurma,
                AIdInscricao,
                Criterio.IdCriterio,
                TemAtendido,
                Atendido,
                ResultadoJson
              );
            end;
          end;

          if not TemCriterioPresenca then
            MetricaPresenca :=
              TInstituicaoConclusaoDAO.CalcularPresenca(
                Conn,
                AIdInstituicao,
                Contexto.IdTurma,
                AIdInscricao,
                False
              );

          Criterios.Free;
          Criterios := nil;

          Criterios :=
            TInstituicaoConclusaoDAO.ListarCriterios(
              Conn,
              AIdInstituicao,
              Contexto.IdTurma,
              AIdInscricao
            );

          CriteriosObrigatorios := 0;
          ObrigatoriosAtendidos := 0;
          ObrigatoriosPendentes := 0;
          ObrigatoriosNaoAtendidos := 0;

          for Criterio in Criterios do
          begin
            if Criterio.Obrigatorio then
            begin
              Inc(
                CriteriosObrigatorios
              );

              if not Criterio.TemAtendido then
                Inc(
                  ObrigatoriosPendentes
                )
              else if Criterio.Atendido then
                Inc(
                  ObrigatoriosAtendidos
                )
              else
                Inc(
                  ObrigatoriosNaoAtendidos
                );
            end;
          end;

          if CriteriosObrigatorios = 0 then
            Elegivel :=
              SameText(
                Contexto.Situacao,
                'CONCLUIDO'
              )
          else
            Elegivel :=
              (
                ObrigatoriosAtendidos =
                CriteriosObrigatorios
              ) and
              (
                ObrigatoriosPendentes = 0
              ) and
              (
                ObrigatoriosNaoAtendidos = 0
              );

          if MatchText(
            Contexto.Situacao,
            [
              'CANCELADO',
              'REPROVADO',
              'DESISTENTE'
            ]
          ) then
            Elegivel := False;

          TInstituicaoConclusaoDAO.AtualizarResumoInscricao(
            Conn,
            AIdInstituicao,
            AIdInscricao,
            AUsuarioInstituicao,
            MetricaPresenca,
            PercentualProgresso,
            Elegivel
          );

          if
            Elegivel and
            MatchText(
              Contexto.Situacao,
              [
                'INSCRITO',
                'CONFIRMADO',
                'EM_ANDAMENTO'
              ]
            )
          then
          begin
            TInstituicaoInscricaoDAO.AlterarSituacao(
              Conn,
              AIdInstituicao,
              AIdInscricao,
              AUsuarioInstituicao,
              'CONCLUIDO',
              ''
            );

            TInstituicaoInscricaoDAO.InserirHistorico(
              Conn,
              AIdInstituicao,
              Contexto.IdTurma,
              AIdInscricao,
              AUsuarioInstituicao,
              Contexto.Situacao,
              'CONCLUIDO',
              'Conclusão automática após atendimento dos critérios obrigatórios.'
            );
          end;

          Conn.Commit;

        except
          if Conn.InTransaction then
            Conn.Rollback;

          raise;
        end;

      finally
        Criterios.Free;
      end;

    finally
      Contexto.Free;
    end;

    Result :=
      MontarResumo(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConclusaoService.AvaliarCriterioManual(
  const AIdInstituicao,
        AIdInscricao,
        AIdCriterio,
        AUsuarioInstituicao: Int64;
  const ADados: TConclusaoAvaliacaoManual
): TConclusaoResumo;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contexto: TConclusaoInscricaoContexto;
  Criterios: TConclusaoCriterioLista;
  Criterio: TConclusaoCriterioItem;
  CriterioEncontrado: TConclusaoCriterioItem;
  JsonValue: TJSONValue;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if (AIdInscricao <= 0) or
     (AIdCriterio <= 0) then
    TAppErrors.RaiseBadRequest(
      'Inscrição ou critério inválido.'
    );

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if not Trim(
    ADados.ResultadoJson
  ).IsEmpty then
  begin
    JsonValue :=
      TJSONObject.ParseJSONValue(
        ADados.ResultadoJson
      );

    try
      if JsonValue = nil then
        TAppErrors.RaiseBadRequest(
          'resultado deve ser um JSON válido.'
        );
    finally
      JsonValue.Free;
    end;
  end;

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(
        ParamStr(0)
      ) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Contexto :=
      TInstituicaoConclusaoDAO.BuscarContexto(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

    try
      if Contexto = nil then
        TAppErrors.RaiseBadRequest(
          'Inscrição não encontrada.'
        );

      Criterios :=
        TInstituicaoConclusaoDAO.ListarCriterios(
          Conn,
          AIdInstituicao,
          Contexto.IdTurma,
          AIdInscricao
        );

      try
        CriterioEncontrado := nil;

        for Criterio in Criterios do
        begin
          if Criterio.IdCriterio = AIdCriterio then
          begin
            CriterioEncontrado := Criterio;
            Break;
          end;
        end;

        if CriterioEncontrado = nil then
          TAppErrors.RaiseBadRequest(
            'Critério não encontrado ou inativo para esta turma.'
          );

        if MatchText(
          CriterioEncontrado.Tipo,
          [
            'PRESENCA_MINIMA',
            'AULAS_CONCLUIDAS'
          ]
        ) then
          TAppErrors.RaiseBadRequest(
            'Este critério é calculado automaticamente e não aceita avaliação manual.'
          );

        TInstituicaoConclusaoDAO.SalvarResultadoManual(
          Conn,
          AIdInstituicao,
          Contexto.IdTurma,
          AIdInscricao,
          AIdCriterio,
          AUsuarioInstituicao,
          ADados.TemAtendido,
          ADados.Atendido,
          ADados.ResultadoJson
        );

      finally
        Criterios.Free;
      end;

    finally
      Contexto.Free;
    end;

  finally
    Conn.Free;
  end;

  Result :=
    Avaliar(
      AIdInstituicao,
      AIdInscricao,
      AUsuarioInstituicao
    );
end;

end.
