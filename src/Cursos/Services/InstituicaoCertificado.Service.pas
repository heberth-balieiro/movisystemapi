unit InstituicaoCertificado.Service;

interface

uses
  InstituicaoCertificado.Model;

type
  TInstituicaoCertificadoService = class
  private
    class procedure ValidarSituacao(
      const ASituacao: string
    ); static;

    class function GerarCodigoValidacao: string; static;

    class function MontarNumeroPublico(
      const APrefixo: string;
      const AUsarAno: Boolean;
      const AAno,
            ADigitos: Integer;
      const ASequencial: Int64
    ): string; static;

    class function ResolverModelo(
      const AContexto: TCertificadoEmissaoContexto;
      const AConfig: TCertificadoConfiguracao
    ): Int64; static;

    class procedure ValidarContextoEmissao(
      const AContexto: TCertificadoEmissaoContexto
    ); static;

    class procedure ValidarPdf(
      const APdf: TCertificadoPdfFinalizacao
    ); static;

  public
    class function ObterConfiguracao(
      const AIdInstituicao: Int64
    ): TCertificadoConfiguracao; static;

    class function SalvarConfiguracao(
      const AIdInstituicao: Int64;
      const AIdModeloPadrao: Int64;
      const ATemIdModeloPadrao: Boolean;
      const APrefixo: string;
      const AUsarAno: Boolean;
      const ADigitosSequencia: Integer;
      const ATextoValidacao: string
    ): TCertificadoConfiguracao; static;

    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca,
            ASituacao: string;
      const AIdTurma,
            AIdParticipante: Int64;
      const APagina,
            APorPagina: Integer
    ): TCertificadoLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdCertificado: Int64
    ): TCertificadoItem; static;

    class function EmitirPendente(
      const AIdInstituicao,
            AIdInscricao,
            AUsuarioInstituicao: Int64
    ): TCertificadoItem; static;

    class function FinalizarPdf(
      const AIdInstituicao,
            AIdCertificado,
            AUsuarioInstituicao: Int64;
      const APdf: TCertificadoPdfFinalizacao
    ): TCertificadoItem; static;

    class function Cancelar(
      const AIdInstituicao,
            AIdCertificado,
            AUsuarioInstituicao: Int64;
      const AMotivo: string
    ): TCertificadoItem; static;

    class function Reemitir(
      const AIdInstituicao,
            AIdCertificado,
            AUsuarioInstituicao: Int64;
      const AMotivo: string
    ): TCertificadoItem; static;

    class function ListarHistorico(
      const AIdInstituicao,
            AIdCertificado: Int64
    ): TCertificadoHistoricoLista; static;

    class function ValidarPublicamente(
      const ACodigoValidacao,
            AIP,
            AUserAgent: string
    ): TCertificadoValidacaoPublica; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.DateUtils,
  System.Hash,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoCertificado.DAO;

class procedure TInstituicaoCertificadoService.ValidarSituacao(
  const ASituacao: string
);
begin
  if not MatchText(
    UpperCase(
      Trim(
        ASituacao
      )
    ),
    [
      'PENDENTE',
      'VALIDO',
      'CANCELADO',
      'ERRO'
    ]
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação de certificado inválida.'
    );
end;

class function TInstituicaoCertificadoService.GerarCodigoValidacao: string;

  function LimparGuid(
    const AGuid: TGUID
  ): string;
  begin
    Result :=
      GUIDToString(
        AGuid
      );

    Result :=
      StringReplace(
        Result,
        '{',
        '',
        [rfReplaceAll]
      );

    Result :=
      StringReplace(
        Result,
        '}',
        '',
        [rfReplaceAll]
      );

    Result :=
      StringReplace(
        Result,
        '-',
        '',
        [rfReplaceAll]
      );
  end;

var
  G1: TGUID;
  G2: TGUID;
begin
  CreateGUID(
    G1
  );

  CreateGUID(
    G2
  );

  Result :=
    UpperCase(
      LimparGuid(G1) +
      LimparGuid(G2)
    );
end;

class function TInstituicaoCertificadoService.MontarNumeroPublico(
  const APrefixo: string;
  const AUsarAno: Boolean;
  const AAno,
        ADigitos: Integer;
  const ASequencial: Int64
): string;

  function PreencherZeros(
    const AValor: Int64;
    const ATamanho: Integer
  ): string;
  begin
    Result :=
      IntToStr(
        AValor
      );

    while Length(Result) < ATamanho do
      Result :=
        '0' +
        Result;
  end;

var
  Partes: string;
begin
  Partes := '';

  if not Trim(APrefixo).IsEmpty then
    Partes :=
      Trim(
        APrefixo
      );

  if AUsarAno then
  begin
    if not Partes.IsEmpty then
      Partes :=
        Partes +
        '-';

    Partes :=
      Partes +
      IntToStr(
        AAno
      );
  end;

  if not Partes.IsEmpty then
    Partes :=
      Partes +
      '-';

  Result :=
    Partes +
    PreencherZeros(
      ASequencial,
      ADigitos
    );
end;

class function TInstituicaoCertificadoService.ResolverModelo(
  const AContexto: TCertificadoEmissaoContexto;
  const AConfig: TCertificadoConfiguracao
): Int64;
begin
  Result := 0;

  if AContexto.TemIdModeloTurma then
  begin
    Result :=
      AContexto.IdModeloTurma;

    Exit;
  end;

  if AConfig.TemIdModeloPadrao then
    Result :=
      AConfig.IdModeloPadrao;
end;

class procedure TInstituicaoCertificadoService.ValidarContextoEmissao(
  const AContexto: TCertificadoEmissaoContexto
);
begin
  if AContexto = nil then
    TAppErrors.RaiseBadRequest(
      'Inscrição não encontrada.'
    );

  if not SameText(
    AContexto.SituacaoInscricao,
    'CONCLUIDO'
  ) then
    TAppErrors.RaiseBadRequest(
      'A inscrição precisa estar concluída para emitir certificado.'
    );

  if not AContexto.ElegivelCertificado then
    TAppErrors.RaiseBadRequest(
      'A inscrição não está elegível para certificado.'
    );

  if not AContexto.TemDataConclusao then
    TAppErrors.RaiseBadRequest(
      'A inscrição não possui data de conclusão.'
    );

  if AContexto.CargaHorariaMinutos <= 0 then
    TAppErrors.RaiseBadRequest(
      'A carga horária do curso/turma é inválida para emissão.'
    );
end;

class procedure TInstituicaoCertificadoService.ValidarPdf(
  const APdf: TCertificadoPdfFinalizacao
);

  function EhHexadecimal(
    const ATexto: string
  ): Boolean;
  var
    C: Char;
  begin
    Result :=
      not ATexto.IsEmpty;

    if not Result then
      Exit;

    for C in ATexto do
    begin
      if not (
        ((C >= '0') and (C <= '9')) or
        ((C >= 'a') and (C <= 'f')) or
        ((C >= 'A') and (C <= 'F'))
      ) then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;

begin
  if Trim(APdf.PdfStorageKey).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe a chave de armazenamento do PDF.'
    );

  if Length(
    Trim(
      APdf.PdfStorageKey
    )
  ) > 500 then
    TAppErrors.RaiseBadRequest(
      'A chave de armazenamento do PDF deve possuir no máximo 500 caracteres.'
    );

  if (
    Length(
      Trim(
        APdf.PdfSha256
      )
    ) <> 64
  ) or
  not EhHexadecimal(
    Trim(
      APdf.PdfSha256
    )
  ) then
    TAppErrors.RaiseBadRequest(
      'Informe o SHA-256 válido do PDF com 64 caracteres hexadecimais.'
    );

  if APdf.PdfTamanhoBytes <= 0 then
    TAppErrors.RaiseBadRequest(
      'Informe um tamanho válido para o PDF.'
    );
end;

class function TInstituicaoCertificadoService.ObterConfiguracao(
  const AIdInstituicao: Int64
): TCertificadoConfiguracao;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
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
      TInstituicaoCertificadoDAO.ObterConfiguracao(
        Conn,
        AIdInstituicao
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoService.SalvarConfiguracao(
  const AIdInstituicao: Int64;
  const AIdModeloPadrao: Int64;
  const ATemIdModeloPadrao: Boolean;
  const APrefixo: string;
  const AUsarAno: Boolean;
  const ADigitosSequencia: Integer;
  const ATextoValidacao: string
): TCertificadoConfiguracao;
var
  ConfigApi: TAppApiConfig;
  Conn: TUniConnection;
  NovaConfig: TCertificadoConfiguracao;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if (
    ADigitosSequencia < 4
  ) or (
    ADigitosSequencia > 12
  ) then
    TAppErrors.RaiseBadRequest(
      'A quantidade de dígitos da sequência deve ficar entre 4 e 12.'
    );

  if Length(
    Trim(
      APrefixo
    )
  ) > 30 then
    TAppErrors.RaiseBadRequest(
      'O prefixo deve possuir no máximo 30 caracteres.'
    );

  if Trim(
    ATextoValidacao
  ).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o texto de validação.'
    );

  if Length(
    Trim(
      ATextoValidacao
    )
  ) > 255 then
    TAppErrors.RaiseBadRequest(
      'O texto de validação deve possuir no máximo 255 caracteres.'
    );

  ConfigApi :=
    TAppConfig.Carregar(
      ExtractFilePath(
        ParamStr(0)
      ) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      ConfigApi.Database
    );

  try
    if ATemIdModeloPadrao then
    begin
      if not TInstituicaoCertificadoDAO.ModeloAtivoExiste(
        Conn,
        AIdInstituicao,
        AIdModeloPadrao
      ) then
        TAppErrors.RaiseBadRequest(
          'Modelo padrão não encontrado ou inativo.'
        );
    end;

    NovaConfig :=
      TCertificadoConfiguracao.Create;

    try
      NovaConfig.TemIdModeloPadrao :=
        ATemIdModeloPadrao;

      NovaConfig.IdModeloPadrao :=
        AIdModeloPadrao;

      NovaConfig.Prefixo :=
        Trim(
          APrefixo
        );

      NovaConfig.UsarAno :=
        AUsarAno;

      NovaConfig.DigitosSequencia :=
        ADigitosSequencia;

      NovaConfig.TextoValidacao :=
        Trim(
          ATextoValidacao
        );

      TInstituicaoCertificadoDAO.SalvarConfiguracao(
        Conn,
        AIdInstituicao,
        NovaConfig
      );

    finally
      NovaConfig.Free;
    end;

    Result :=
      TInstituicaoCertificadoDAO.ObterConfiguracao(
        Conn,
        AIdInstituicao
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoService.Listar(
  const AIdInstituicao: Int64;
  const ABusca,
        ASituacao: string;
  const AIdTurma,
        AIdParticipante: Int64;
  const APagina,
        APorPagina: Integer
): TCertificadoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TCertificadoFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro :=
    Default(
      TCertificadoFiltro
    );

  Filtro.Busca :=
    Trim(
      ABusca
    );

  Filtro.Situacao :=
    UpperCase(
      Trim(
        ASituacao
      )
    );

  Filtro.IdTurma :=
    AIdTurma;

  Filtro.IdParticipante :=
    AIdParticipante;

  Filtro.Pagina :=
    APagina;

  Filtro.PorPagina :=
    APorPagina;

  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 20;

  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  if not Filtro.Situacao.IsEmpty then
    ValidarSituacao(
      Filtro.Situacao
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
      TInstituicaoCertificadoDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoService.BuscarPorId(
  const AIdInstituicao,
        AIdCertificado: Int64
): TCertificadoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCertificado <= 0 then
    TAppErrors.RaiseBadRequest(
      'Certificado inválido.'
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
      TInstituicaoCertificadoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdCertificado
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Certificado não encontrado.'
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoService.EmitirPendente(
  const AIdInstituicao,
        AIdInscricao,
        AUsuarioInstituicao: Int64
): TCertificadoItem;
var
  ConfigApi: TAppApiConfig;
  Conn: TUniConnection;
  Contexto: TCertificadoEmissaoContexto;
  ConfigCert: TCertificadoConfiguracao;
  IdModelo: Int64;
  AnoSequencia: Integer;
  Sequencial: Int64;
  NumeroPublico: string;
  CodigoValidacao: string;
  CodigoDisponivel: Boolean;
  Tentativas: Integer;
  IdCertificado: Int64;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Inscrição inválida.'
    );

  ConfigApi :=
    TAppConfig.Carregar(
      ExtractFilePath(
        ParamStr(0)
      ) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      ConfigApi.Database
    );

  try
    Contexto :=
      TInstituicaoCertificadoDAO.BuscarContextoEmissao(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

    try
      ValidarContextoEmissao(
        Contexto
      );

      if TInstituicaoCertificadoDAO.ExisteCertificadoParaInscricao(
        Conn,
        AIdInstituicao,
        AIdInscricao
      ) then
        TAppErrors.RaiseBadRequest(
          'A inscrição já possui certificado. Utilize a operação de reemissão quando necessário.'
        );

      ConfigCert :=
        TInstituicaoCertificadoDAO.ObterConfiguracao(
          Conn,
          AIdInstituicao
        );

      try
        IdModelo :=
          ResolverModelo(
            Contexto,
            ConfigCert
          );

        if IdModelo <= 0 then
          TAppErrors.RaiseBadRequest(
            'Configure um modelo de certificado na turma ou como modelo padrão da instituição.'
          );

        if not TInstituicaoCertificadoDAO.ModeloAtivoExiste(
          Conn,
          AIdInstituicao,
          IdModelo
        ) then
          TAppErrors.RaiseBadRequest(
            'O modelo de certificado selecionado está inativo ou não existe.'
          );

        Tentativas := 0;
        CodigoDisponivel := False;

        repeat
          Inc(
            Tentativas
          );

          CodigoValidacao :=
            GerarCodigoValidacao;

          CodigoDisponivel :=
            not TInstituicaoCertificadoDAO.ExisteCodigoValidacao(
              Conn,
              CodigoValidacao
            );

        until
          CodigoDisponivel or
          (
            Tentativas >= 5
          );

        if not CodigoDisponivel then
          raise Exception.Create(
            'Não foi possível gerar um código público de validação único.'
          );

        Conn.StartTransaction;

        try
          if ConfigCert.UsarAno then
            AnoSequencia :=
              YearOf(
                Now
              )
          else
            AnoSequencia := 0;

          Sequencial :=
            TInstituicaoCertificadoDAO.ProximoSequencial(
              Conn,
              AIdInstituicao,
              AnoSequencia
            );

          NumeroPublico :=
            MontarNumeroPublico(
              ConfigCert.Prefixo,
              ConfigCert.UsarAno,
              YearOf(Now),
              ConfigCert.DigitosSequencia,
              Sequencial
            );

          IdCertificado :=
            TInstituicaoCertificadoDAO.InserirPendente(
              Conn,
              AIdInstituicao,
              IdModelo,
              0,
              AUsuarioInstituicao,
              False,
              NumeroPublico,
              CodigoValidacao,
              '',
              1,
              Contexto
            );

          Result :=
            TInstituicaoCertificadoDAO.BuscarPorId(
              Conn,
              AIdInstituicao,
              IdCertificado
            );

          if Result = nil then
            raise Exception.Create(
              'Certificado criado, mas não foi possível recuperar os dados.'
            );

          Conn.Commit;

        except
          if Conn.InTransaction then
            Conn.Rollback;

          Result.Free;
          Result := nil;

          raise;
        end;

      finally
        ConfigCert.Free;
      end;

    finally
      Contexto.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoService.FinalizarPdf(
  const AIdInstituicao,
        AIdCertificado,
        AUsuarioInstituicao: Int64;
  const APdf: TCertificadoPdfFinalizacao
): TCertificadoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TCertificadoItem;
  Origem: TCertificadoItem;
  DadosJson: string;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if AIdCertificado <= 0 then
    TAppErrors.RaiseBadRequest(
      'Certificado inválido.'
    );

  ValidarPdf(
    APdf
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
    Atual :=
      TInstituicaoCertificadoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdCertificado
      );

    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest(
          'Certificado não encontrado.'
        );

      if not SameText(
        Atual.Situacao,
        'PENDENTE'
      ) and
      not SameText(
        Atual.Situacao,
        'ERRO'
      ) then
        TAppErrors.RaiseBadRequest(
          'Somente certificados pendentes ou com erro podem receber um novo PDF.'
        );

      Conn.StartTransaction;

      try
        TInstituicaoCertificadoDAO.FinalizarPdf(
          Conn,
          AIdInstituicao,
          AIdCertificado,
          AUsuarioInstituicao,
          APdf
        );

        DadosJson :=
          Format(
            '{"pdf_sha256":"%s","pdf_tamanho_bytes":%d}',
            [
              LowerCase(
                Trim(
                  APdf.PdfSha256
                )
              ),
              APdf.PdfTamanhoBytes
            ]
          );

        TInstituicaoCertificadoDAO.InserirHistorico(
          Conn,
          AIdInstituicao,
          AIdCertificado,
          AUsuarioInstituicao,
          'PDF_GERADO',
          'PDF do certificado gerado e registrado.',
          DadosJson
        );

        TInstituicaoCertificadoDAO.InserirHistorico(
          Conn,
          AIdInstituicao,
          AIdCertificado,
          AUsuarioInstituicao,
          'EMITIDO',
          'Certificado emitido e disponibilizado como válido.',
          ''
        );

        if Atual.TemIdCertificadoOrigem then
        begin
          Origem :=
            TInstituicaoCertificadoDAO.BuscarPorId(
              Conn,
              AIdInstituicao,
              Atual.IdCertificadoOrigem
            );

          try
            if (
              Origem <> nil
            ) and
            SameText(
              Origem.Situacao,
              'VALIDO'
            ) then
            begin
              TInstituicaoCertificadoDAO.Cancelar(
                Conn,
                AIdInstituicao,
                Origem.Id,
                'Substituído por reemissão do certificado.'
              );

              TInstituicaoCertificadoDAO.InserirHistorico(
                Conn,
                AIdInstituicao,
                Origem.Id,
                AUsuarioInstituicao,
                'CANCELADO',
                'Certificado cancelado por reemissão.',
                Format(
                  '{"novo_certificado_id":%d}',
                  [
                    AIdCertificado
                  ]
                )
              );

              TInstituicaoCertificadoDAO.InserirHistorico(
                Conn,
                AIdInstituicao,
                AIdCertificado,
                AUsuarioInstituicao,
                'REEMITIDO',
                'Nova versão emitida em substituição ao certificado anterior.',
                Format(
                  '{"certificado_origem_id":%d}',
                  [
                    Origem.Id
                  ]
                )
              );
            end;

          finally
            Origem.Free;
          end;
        end;

        Result :=
          TInstituicaoCertificadoDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdCertificado
          );

        Conn.Commit;

      except
        if Conn.InTransaction then
          Conn.Rollback;

        Result.Free;
        Result := nil;

        raise;
      end;

    finally
      Atual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoService.Cancelar(
  const AIdInstituicao,
        AIdCertificado,
        AUsuarioInstituicao: Int64;
  const AMotivo: string
): TCertificadoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TCertificadoItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if Trim(
    AMotivo
  ).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o motivo do cancelamento.'
    );

  if Length(
    Trim(
      AMotivo
    )
  ) > 500 then
    TAppErrors.RaiseBadRequest(
      'O motivo do cancelamento deve possuir no máximo 500 caracteres.'
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
    Atual :=
      TInstituicaoCertificadoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdCertificado
      );

    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest(
          'Certificado não encontrado.'
        );

      if SameText(
        Atual.Situacao,
        'CANCELADO'
      ) then
        TAppErrors.RaiseBadRequest(
          'O certificado já está cancelado.'
        );

      Conn.StartTransaction;

      try
        TInstituicaoCertificadoDAO.Cancelar(
          Conn,
          AIdInstituicao,
          AIdCertificado,
          AMotivo
        );

        TInstituicaoCertificadoDAO.InserirHistorico(
          Conn,
          AIdInstituicao,
          AIdCertificado,
          AUsuarioInstituicao,
          'CANCELADO',
          Trim(
            AMotivo
          ),
          ''
        );

        Result :=
          TInstituicaoCertificadoDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdCertificado
          );

        Conn.Commit;

      except
        if Conn.InTransaction then
          Conn.Rollback;

        Result.Free;
        Result := nil;

        raise;
      end;

    finally
      Atual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoService.Reemitir(
  const AIdInstituicao,
        AIdCertificado,
        AUsuarioInstituicao: Int64;
  const AMotivo: string
): TCertificadoItem;
var
  ConfigApi: TAppApiConfig;
  Conn: TUniConnection;
  Origem: TCertificadoItem;
  Contexto: TCertificadoEmissaoContexto;
  ConfigCert: TCertificadoConfiguracao;
  IdModelo: Int64;
  AnoSequencia: Integer;
  Sequencial: Int64;
  NumeroPublico: string;
  CodigoValidacao: string;
  CodigoDisponivel: Boolean;
  Tentativas: Integer;
  IdNovo: Int64;
  Versao: Integer;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if Trim(
    AMotivo
  ).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o motivo da reemissão.'
    );

  if Length(
    Trim(
      AMotivo
    )
  ) > 500 then
    TAppErrors.RaiseBadRequest(
      'O motivo da reemissão deve possuir no máximo 500 caracteres.'
    );

  ConfigApi :=
    TAppConfig.Carregar(
      ExtractFilePath(
        ParamStr(0)
      ) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      ConfigApi.Database
    );

  try
    Origem :=
      TInstituicaoCertificadoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdCertificado
      );

    try
      if Origem = nil then
        TAppErrors.RaiseBadRequest(
          'Certificado de origem não encontrado.'
        );

      if SameText(
        Origem.Situacao,
        'PENDENTE'
      ) then
        TAppErrors.RaiseBadRequest(
          'Finalize ou cancele o certificado pendente antes de solicitar reemissão.'
        );

      Contexto :=
        TInstituicaoCertificadoDAO.BuscarContextoEmissao(
          Conn,
          AIdInstituicao,
          Origem.IdInscricao
        );

      try
        ValidarContextoEmissao(
          Contexto
        );

        ConfigCert :=
          TInstituicaoCertificadoDAO.ObterConfiguracao(
            Conn,
            AIdInstituicao
          );

        try
          IdModelo :=
            ResolverModelo(
              Contexto,
              ConfigCert
            );

          if IdModelo <= 0 then
            TAppErrors.RaiseBadRequest(
              'Configure um modelo de certificado para a reemissão.'
            );

          if not TInstituicaoCertificadoDAO.ModeloAtivoExiste(
            Conn,
            AIdInstituicao,
            IdModelo
          ) then
            TAppErrors.RaiseBadRequest(
              'O modelo de certificado da reemissão está inativo ou não existe.'
            );

          Tentativas := 0;
          CodigoDisponivel := False;

          repeat
            Inc(
              Tentativas
            );

            CodigoValidacao :=
              GerarCodigoValidacao;

            CodigoDisponivel :=
              not TInstituicaoCertificadoDAO.ExisteCodigoValidacao(
                Conn,
                CodigoValidacao
              );

          until
            CodigoDisponivel or
            (
              Tentativas >= 5
            );

          if not CodigoDisponivel then
            raise Exception.Create(
              'Não foi possível gerar um código de validação único para a reemissão.'
            );

          Conn.StartTransaction;

          try
            if ConfigCert.UsarAno then
              AnoSequencia :=
                YearOf(
                  Now
                )
            else
              AnoSequencia := 0;

            Sequencial :=
              TInstituicaoCertificadoDAO.ProximoSequencial(
                Conn,
                AIdInstituicao,
                AnoSequencia
              );

            NumeroPublico :=
              MontarNumeroPublico(
                ConfigCert.Prefixo,
                ConfigCert.UsarAno,
                YearOf(Now),
                ConfigCert.DigitosSequencia,
                Sequencial
              );

            Versao :=
              TInstituicaoCertificadoDAO.ProximaVersao(
                Conn,
                AIdInstituicao,
                Origem.IdInscricao
              );

            IdNovo :=
              TInstituicaoCertificadoDAO.InserirPendente(
                Conn,
                AIdInstituicao,
                IdModelo,
                Origem.Id,
                AUsuarioInstituicao,
                True,
                NumeroPublico,
                CodigoValidacao,
                AMotivo,
                Versao,
                Contexto
              );

            TInstituicaoCertificadoDAO.InserirHistorico(
              Conn,
              AIdInstituicao,
              IdNovo,
              AUsuarioInstituicao,
              'REEMITIDO',
              'Reemissão criada e aguardando geração do PDF.',
              Format(
                '{"certificado_origem_id":%d}',
                [
                  Origem.Id
                ]
              )
            );

            Result :=
              TInstituicaoCertificadoDAO.BuscarPorId(
                Conn,
                AIdInstituicao,
                IdNovo
              );

            if Result = nil then
              raise Exception.Create(
                'Reemissão criada, mas não foi possível recuperar o novo certificado.'
              );

            Conn.Commit;

          except
            if Conn.InTransaction then
              Conn.Rollback;

            Result.Free;
            Result := nil;

            raise;
          end;

        finally
          ConfigCert.Free;
        end;

      finally
        Contexto.Free;
      end;

    finally
      Origem.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoService.ListarHistorico(
  const AIdInstituicao,
        AIdCertificado: Int64
): TCertificadoHistoricoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Certificado: TCertificadoItem;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCertificado <= 0 then
    TAppErrors.RaiseBadRequest(
      'Certificado inválido.'
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
    Certificado :=
      TInstituicaoCertificadoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdCertificado
      );

    try
      if Certificado = nil then
        TAppErrors.RaiseBadRequest(
          'Certificado não encontrado.'
        );

      Result :=
        TInstituicaoCertificadoDAO.ListarHistorico(
          Conn,
          AIdInstituicao,
          AIdCertificado
        );

    finally
      Certificado.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoService.ValidarPublicamente(
  const ACodigoValidacao,
        AIP,
        AUserAgent: string
): TCertificadoValidacaoPublica;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Certificado: TCertificadoItem;
  ResultadoValidacao: string;
  CodigoHash: string;
begin
  Result :=
    TCertificadoValidacaoPublica.Create;

  if Trim(
    ACodigoValidacao
  ).IsEmpty then
  begin
    Result.Encontrado := False;
    Result.Resultado := 'NAO_ENCONTRADO';
    Exit;
  end;

  CodigoHash :=
    LowerCase(
      THashSHA2.GetHashString(
        Trim(
          ACodigoValidacao
        )
      )
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
    Certificado :=
      TInstituicaoCertificadoDAO.BuscarPublicoPorCodigo(
        Conn,
        Trim(
          ACodigoValidacao
        )
      );

    if Certificado = nil then
    begin
      ResultadoValidacao := 'NAO_ENCONTRADO';

      TInstituicaoCertificadoDAO.RegistrarValidacao(
        Conn,
        0,
        0,
        False,
        CodigoHash,
        ResultadoValidacao,
        AIP,
        AUserAgent
      );

      Result.Encontrado := False;
      Result.Resultado := ResultadoValidacao;

      Exit;
    end;

    if SameText(
      Certificado.Situacao,
      'VALIDO'
    ) then
      ResultadoValidacao := 'VALIDO'
    else if SameText(
      Certificado.Situacao,
      'CANCELADO'
    ) then
      ResultadoValidacao := 'CANCELADO'
    else
      ResultadoValidacao := 'ERRO';

    TInstituicaoCertificadoDAO.RegistrarValidacao(
      Conn,
      Certificado.IdInstituicao,
      Certificado.Id,
      True,
      CodigoHash,
      ResultadoValidacao,
      AIP,
      AUserAgent
    );

    Result.Encontrado := True;
    Result.Resultado := ResultadoValidacao;
    Result.Certificado := Certificado;
    Certificado := nil;

  finally
    Certificado.Free;
    Conn.Free;
  end;
end;

end.
