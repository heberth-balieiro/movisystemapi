unit PlataformaContatoRelatorio.Service;

interface

uses
  PlataformaContatoRelatorio.Model;

type
  TPlataformaContatoRelatorioService = class
  public
    class function Listar(
      const AIdUsuario:Int64;
      const AFiltro:TPlataformaContatoRelatorioFiltro;
      const AIP,AUserAgent:string
    ):TPlataformaContatoRelatorioResultado; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaContato.DAO,
  PlataformaContatoRelatorio.DAO;

class function TPlataformaContatoRelatorioService.Listar(
  const AIdUsuario:Int64;
  const AFiltro:TPlataformaContatoRelatorioFiltro;
  const AIP,AUserAgent:string
):TPlataformaContatoRelatorioResultado;
var
  Cfg:TAppApiConfig;
  Conn:TUniConnection;
  Filtro:TPlataformaContatoRelatorioFiltro;
  Tipo:string;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');

  Filtro:=AFiltro;
  Tipo:=UpperCase(Trim(Filtro.Tipo));
  if not MatchText(Tipo,[
    'CAMARA','PREFEITURA','SINDICATO','ASSOCIACAO',
    'VEREADOR','DEPUTADO_ESTADUAL','DEPUTADO_FEDERAL','SENADOR','UNALE_ASSOCIADO'
  ]) then
    TAppErrors.RaiseBadRequest('Tipo de relatório inválido.');

  Filtro.Tipo:=Tipo;
  Filtro.UF:=UpperCase(Trim(Filtro.UF));
  Filtro.Municipio:=Trim(Filtro.Municipio);
  Filtro.Partido:=UpperCase(Trim(Filtro.Partido));
  Filtro.Situacao:=UpperCase(Trim(Filtro.Situacao));

  if (not Filtro.UF.IsEmpty) and (Length(Filtro.UF)<>2) then
    TAppErrors.RaiseBadRequest('UF inválida.');
  if (not Filtro.Situacao.IsEmpty) and not MatchText(Filtro.Situacao,['ATIVO','INATIVO']) then
    TAppErrors.RaiseBadRequest('Situação inválida.');

  Cfg:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn:=TDatabaseConnection.NewConnection(Cfg.Database);
  try
    Result:=TPlataformaContatoRelatorioDAO.Listar(Conn,Filtro);
    TPlataformaContatoDAO.RegistrarAuditoria(
      Conn,AIdUsuario,'RELATORIO_CONTATOS_GERADO','plataforma_contato','',
      'Relatório analítico gerado: '+Tipo,AIP,AUserAgent
    );
  finally
    Conn.Free;
  end;
end;

end.
