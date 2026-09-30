unit CertificadoProcessamento.Service;

interface

type
  TCertificadoProcessamentoService = class
  public
    class procedure Enfileirar(
      const AIdInstituicao,
            AIdCertificado,
            ASolicitadoPor: Int64
    ); static;

    class function ProcessarProximo: Boolean; static;

    class function Listar(
      const AIdInstituicao,
            AUsuarioInstituicao: Int64;
      const ABusca,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TCertificadoProcessamentoLista; static;

    class function Reprocessar(
      const AIdInstituicao,
            AIdCertificado,
            AUsuarioInstituicao: Int64
    ): TCertificadoProcessamentoItem; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  CertificadoProcessamento.Model,
  CertificadoProcessamento.DAO,
  InstituicaoPermissao.Service,
  InstituicaoCertificado.Model,
  InstituicaoCertificado.DAO,
  InstituicaoCertificado.Service,
  InstituicaoCertificadoDocumento.Service;

function NovaConexao: TUniConnection;
var
  Config: TAppApiConfig;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Result := TDatabaseConnection.NewConnection(Config.Database);
end;

class procedure TCertificadoProcessamentoService.Enfileirar(
  const AIdInstituicao,
        AIdCertificado,
        ASolicitadoPor: Int64
);
var
  C: TUniConnection;
begin
  if (AIdInstituicao <= 0) or (AIdCertificado <= 0) or (ASolicitadoPor <= 0) then
    Exit;

  C := NovaConexao;
  try
    C.StartTransaction;
    try
      TCertificadoProcessamentoDAO.Enfileirar(
        C,
        AIdInstituicao,
        AIdCertificado,
        ASolicitadoPor
      );

      TInstituicaoCertificadoDAO.InserirHistorico(
        C,
        AIdInstituicao,
        AIdCertificado,
        ASolicitadoPor,
        'PROCESSAMENTO_AGENDADO',
        'Geração automática do PDF e QR Code agendada.',
        ''
      );

      C.Commit;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
  finally
    C.Free;
  end;
end;

class function TCertificadoProcessamentoService.ProcessarProximo: Boolean;
var
  C: TUniConnection;
  Item: TCertificadoProcessamentoItem;
  Certificado: TCertificadoItem;
begin
  Result := False;
  Item := nil;
  Certificado := nil;

  C := NovaConexao;
  try
    C.StartTransaction;
    try
      TCertificadoProcessamentoDAO.RecuperarTravados(C);
      Item := TCertificadoProcessamentoDAO.ReservarProximo(C);
      C.Commit;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
  finally
    C.Free;
  end;

  if Item = nil then
    Exit;

  Result := True;

  try
    try
      Certificado := TInstituicaoCertificadoDocumentoService.GerarPdf(
        Item.IdInstituicao,
        Item.IdCertificado,
        Item.SolicitadoPor
      );

      C := NovaConexao;
      try
        TCertificadoProcessamentoDAO.MarcarConcluido(C, Item.Id);
      finally
        C.Free;
      end;
    except
      on E: Exception do
      begin
        Certificado.Free;
        Certificado := nil;

        try
          Certificado := TInstituicaoCertificadoService.BuscarPorId(
            Item.IdInstituicao,
            Item.IdCertificado
          );
        except
          Certificado.Free;
          Certificado := nil;
        end;

        C := NovaConexao;
        try
          if (Certificado <> nil) and SameText(Certificado.Situacao, 'VALIDO') then
            TCertificadoProcessamentoDAO.MarcarConcluido(C, Item.Id)
          else
          begin
            TCertificadoProcessamentoDAO.MarcarErro(C, Item.Id, E.Message);

            if Item.Tentativas >= 3 then
            begin
              TCertificadoProcessamentoDAO.MarcarCertificadoErro(
                C,
                Item.IdInstituicao,
                Item.IdCertificado
              );

              TInstituicaoCertificadoDAO.InserirHistorico(
                C,
                Item.IdInstituicao,
                Item.IdCertificado,
                Item.SolicitadoPor,
                'PROCESSAMENTO_ERRO',
                'Falha definitiva após 3 tentativas de geração automática do PDF e QR Code.',
                ''
              );
            end;
          end;
        finally
          C.Free;
        end;
      end;
    end;
  finally
    Certificado.Free;
    Item.Free;
  end;
end;


class function TCertificadoProcessamentoService.Listar(
  const AIdInstituicao,
        AUsuarioInstituicao: Int64;
  const ABusca,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TCertificadoProcessamentoLista;
var
  C: TUniConnection;
  Pagina, PorPagina: Integer;
  Situacao: string;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AUsuarioInstituicao,
    'certificado.visualizar'
  );

  Situacao := UpperCase(Trim(ASituacao));
  if (Situacao <> '') and
     (Situacao <> 'PENDENTE') and
     (Situacao <> 'PROCESSANDO') and
     (Situacao <> 'CONCLUIDO') and
     (Situacao <> 'ERRO') then
    TAppErrors.RaiseBadRequest('Situação de processamento inválida.');

  Pagina := APagina;
  if Pagina <= 0 then Pagina := 1;

  PorPagina := APorPagina;
  if PorPagina <= 0 then PorPagina := 20;
  if PorPagina > 100 then PorPagina := 100;

  C := NovaConexao;
  try
    Result := TCertificadoProcessamentoDAO.Listar(
      C,
      AIdInstituicao,
      ABusca,
      Situacao,
      Pagina,
      PorPagina
    );
  finally
    C.Free;
  end;
end;

class function TCertificadoProcessamentoService.Reprocessar(
  const AIdInstituicao,
        AIdCertificado,
        AUsuarioInstituicao: Int64
): TCertificadoProcessamentoItem;
var
  C: TUniConnection;
begin
  if (AIdInstituicao <= 0) or (AIdCertificado <= 0) then
    TAppErrors.RaiseBadRequest('Certificado inválido.');

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AUsuarioInstituicao,
    'certificado.reprocessar'
  );

  C := NovaConexao;
  try
    C.StartTransaction;
    try
      Result := TCertificadoProcessamentoDAO.BuscarPorCertificado(
        C,
        AIdInstituicao,
        AIdCertificado
      );

      if Result = nil then
        TAppErrors.RaiseBadRequest('Processamento do certificado não encontrado.');

      if not SameText(Result.Situacao, 'ERRO') then
        TAppErrors.RaiseBadRequest('Somente processamentos com erro podem ser reenfileirados.');

      if not SameText(Result.CertificadoSituacao, 'ERRO') and
         not SameText(Result.CertificadoSituacao, 'PENDENTE') then
        TAppErrors.RaiseBadRequest('O certificado não está disponível para reprocessamento.');

      Result.Free;
      Result := nil;

      TCertificadoProcessamentoDAO.Reprocessar(
        C,
        AIdInstituicao,
        AIdCertificado,
        AUsuarioInstituicao
      );

      TInstituicaoCertificadoDAO.InserirHistorico(
        C,
        AIdInstituicao,
        AIdCertificado,
        AUsuarioInstituicao,
        'PROCESSAMENTO_REENFILEIRADO',
        'Reprocessamento manual do PDF e QR Code solicitado.',
        ''
      );

      C.Commit;

      Result := TCertificadoProcessamentoDAO.BuscarPorCertificado(
        C,
        AIdInstituicao,
        AIdCertificado
      );
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
  finally
    C.Free;
  end;
end;

end.
