unit InstituicaoCertificadoDocumento.DAO;

interface

uses
  Uni,
  InstituicaoCertificadoDocumento.Model;

type
  TInstituicaoCertificadoDocumentoDAO = class
  public
    class function BuscarTemplate(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64
    ): TCertificadoDocumentoTemplate; static;
  end;

implementation

class function TInstituicaoCertificadoDocumentoDAO.BuscarTemplate(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64
): TCertificadoDocumentoTemplate;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'm.template_html, ' +
      'm.template_configuracao, ' +
      'm.imagem_fundo_url, ' +
      'COALESCE(cc.texto_validacao, ''Valide este certificado'') AS texto_validacao ' +
      'FROM certificado c ' +
      'INNER JOIN certificado_modelo m ' +
      '  ON m.id_instituicao = c.id_instituicao ' +
      ' AND m.id = c.id_modelo ' +
      'LEFT JOIN certificado_configuracao cc ' +
      '  ON cc.id_instituicao = c.id_instituicao ' +
      'WHERE c.id_instituicao = :id_instituicao ' +
      'AND c.id = :id_certificado ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_certificado'
    ).AsLargeInt :=
      AIdCertificado;

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result :=
      TCertificadoDocumentoTemplate.Create;

    Result.TemplateHtml :=
      Qry.FieldByName(
        'template_html'
      ).AsString;

    Result.TemplateConfiguracao :=
      Qry.FieldByName(
        'template_configuracao'
      ).AsString;

    Result.ImagemFundoUrl :=
      Qry.FieldByName(
        'imagem_fundo_url'
      ).AsString;

    Result.TextoValidacao :=
      Qry.FieldByName(
        'texto_validacao'
      ).AsString;

  finally
    Qry.Free;
  end;
end;

end.
