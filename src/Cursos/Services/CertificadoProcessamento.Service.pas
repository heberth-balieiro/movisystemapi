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
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection,
  CertificadoProcessamento.Model,
  CertificadoProcessamento.DAO,
  InstituicaoCertificado.Model,
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
    TCertificadoProcessamentoDAO.Enfileirar(
      C,
      AIdInstituicao,
      AIdCertificado,
      ASolicitadoPor
    );
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
              TCertificadoProcessamentoDAO.MarcarCertificadoErro(
                C,
                Item.IdInstituicao,
                Item.IdCertificado
              );
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

end.
