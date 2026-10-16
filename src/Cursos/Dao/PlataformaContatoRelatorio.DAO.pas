unit PlataformaContatoRelatorio.DAO;

interface

uses
  Uni,
  PlataformaContatoRelatorio.Model;

type
  TPlataformaContatoRelatorioDAO = class
  private
    class function MontarWhere(const AFiltro:TPlataformaContatoRelatorioFiltro):string; static;
    class procedure AplicarFiltro(const AQry:TUniQuery; const AFiltro:TPlataformaContatoRelatorioFiltro); static;
    class function MapearItem(const AQry:TUniQuery):TPlataformaContatoRelatorioItem; static;
  public
    class function Listar(const AConn:TUniConnection; const AFiltro:TPlataformaContatoRelatorioFiltro):TPlataformaContatoRelatorioResultado; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils;

class function TPlataformaContatoRelatorioDAO.MontarWhere(const AFiltro:TPlataformaContatoRelatorioFiltro):string;
var Tipo:string;
begin
  Tipo:=UpperCase(Trim(AFiltro.Tipo));
  Result:=' WHERE 1=1 ';
  if Tipo='CAMARA' then
    Result:=Result+'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' AND (c.orgao=''Câmara Municipal'' OR c.grau=''Câmara Municipal'') '
  else if Tipo='PREFEITURA' then
    Result:=Result+'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' AND (c.orgao=''Prefeitura Municipal'' OR c.grau=''Prefeitura Municipal'') '
  else if Tipo='SINDICATO' then
    Result:=Result+'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' AND (c.orgao=''Sindicato'' OR c.grau=''Sindicato'') '
  else if Tipo='ASSOCIACAO' then
    Result:=Result+'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' AND (c.orgao=''Associação'' OR c.grau=''Associação'') '
  else if Tipo='UNALE_ASSOCIADO' then
    Result:=Result+'AND c.tipo_contato=''PARLAMENTAR'' AND c.unale_associado=1 '
  else
    Result:=Result+'AND c.tipo_contato=''PARLAMENTAR'' AND c.cargo=:cargo ';

  if not Trim(AFiltro.UF).IsEmpty then Result:=Result+'AND c.uf=:uf ';
  if not Trim(AFiltro.Municipio).IsEmpty then Result:=Result+'AND c.cidade=:cidade ';
  if not Trim(AFiltro.Partido).IsEmpty then Result:=Result+'AND c.partido=:partido ';
  if not Trim(AFiltro.Situacao).IsEmpty then Result:=Result+'AND c.situacao=:situacao ';
  if AFiltro.EmExercicio=1 then Result:=Result+'AND c.em_exercicio=1 '
  else if AFiltro.EmExercicio=0 then Result:=Result+'AND c.em_exercicio=0 ';
  if AFiltro.TemEmail=1 then Result:=Result+'AND COALESCE(c.email_normalizado,'''')<>'''' '
  else if AFiltro.TemEmail=0 then Result:=Result+'AND COALESCE(c.email_normalizado,'''')='''' ';
end;

class procedure TPlataformaContatoRelatorioDAO.AplicarFiltro(const AQry:TUniQuery; const AFiltro:TPlataformaContatoRelatorioFiltro);
var Tipo:string;
begin
  Tipo:=UpperCase(Trim(AFiltro.Tipo));
  if MatchText(Tipo,['VEREADOR','DEPUTADO_ESTADUAL','DEPUTADO_FEDERAL','SENADOR']) then
    AQry.ParamByName('cargo').AsString:=Tipo;
  if not Trim(AFiltro.UF).IsEmpty then AQry.ParamByName('uf').AsString:=UpperCase(Trim(AFiltro.UF));
  if not Trim(AFiltro.Municipio).IsEmpty then AQry.ParamByName('cidade').AsString:=Trim(AFiltro.Municipio);
  if not Trim(AFiltro.Partido).IsEmpty then AQry.ParamByName('partido').AsString:=UpperCase(Trim(AFiltro.Partido));
  if not Trim(AFiltro.Situacao).IsEmpty then AQry.ParamByName('situacao').AsString:=UpperCase(Trim(AFiltro.Situacao));
end;

class function TPlataformaContatoRelatorioDAO.MapearItem(const AQry:TUniQuery):TPlataformaContatoRelatorioItem;
begin
  Result:=TPlataformaContatoRelatorioItem.Create;
  Result.Id:=AQry.FieldByName('id').AsLargeInt;
  if SameText(AQry.FieldByName('tipo_documento').AsString,'CNPJ') then Result.Documento:=AQry.FieldByName('documento').AsString;
  Result.RazaoSocial:=AQry.FieldByName('razao_social').AsString;
  Result.NomeFantasia:=AQry.FieldByName('nome_fantasia').AsString;
  Result.Responsavel:=AQry.FieldByName('responsavel').AsString;
  Result.Telefone:=AQry.FieldByName('telefone').AsString;
  Result.Email:=AQry.FieldByName('email').AsString;
  Result.Grau:=AQry.FieldByName('grau').AsString;
  Result.Cidade:=AQry.FieldByName('cidade').AsString;
  Result.UF:=AQry.FieldByName('uf').AsString;
  Result.Orgao:=AQry.FieldByName('orgao').AsString;
  Result.Site:=AQry.FieldByName('site').AsString;
  Result.Fonte:=AQry.FieldByName('fonte').AsString;
  if not AQry.FieldByName('data_coleta').IsNull then Result.DataColeta:=FormatDateTime('yyyy-mm-dd',AQry.FieldByName('data_coleta').AsDateTime);
  Result.Situacao:=AQry.FieldByName('situacao').AsString;
  Result.Cargo:=AQry.FieldByName('cargo').AsString;
  Result.Partido:=AQry.FieldByName('partido').AsString;
  Result.IdExterno:=AQry.FieldByName('id_externo').AsString;
  Result.FonteDados:=AQry.FieldByName('fonte_dados').AsString;
  Result.UrlPerfil:=AQry.FieldByName('url_perfil').AsString;
  Result.UnaleAssociado:=AQry.FieldByName('unale_associado').AsBoolean;
  Result.EmExercicio:=AQry.FieldByName('em_exercicio').AsBoolean;
end;

class function TPlataformaContatoRelatorioDAO.Listar(const AConn:TUniConnection; const AFiltro:TPlataformaContatoRelatorioFiltro):TPlataformaContatoRelatorioResultado;
var Q:TUniQuery; WhereSQL,SelectSQL:string;
begin
  Result:=TPlataformaContatoRelatorioResultado.Create;
  Q:=TUniQuery.Create(nil);
  try
    try
      Q.Connection:=AConn;
      WhereSQL:=MontarWhere(AFiltro);
      SelectSQL:=
        'SELECT c.id,c.tipo_documento,c.documento,c.razao_social,c.nome_fantasia,'+
        'c.responsavel,c.telefone,c.email,c.grau,c.cidade,c.uf,c.orgao,c.site,'+
        'c.fonte,c.data_coleta,c.situacao,c.cargo,c.partido,c.id_externo,'+
        'c.fonte_dados,c.url_perfil,c.unale_associado,c.em_exercicio ';
      Q.SQL.Text:=SelectSQL+'FROM plataforma_contato c '+WhereSQL+
        'ORDER BY c.uf,c.cidade,COALESCE(NULLIF(c.responsavel,''''),NULLIF(c.nome_fantasia,''''),c.razao_social),c.id LIMIT 5000';
      AplicarFiltro(Q,AFiltro);
      Q.Open;
      while not Q.Eof do begin Result.Itens.Add(MapearItem(Q)); Q.Next; end;
      Result.Tipo:=UpperCase(Trim(AFiltro.Tipo));
      Result.Total:=Result.Itens.Count;
    except
      Result.Free;
      raise;
    end;
  finally
    Q.Free;
  end;
end;

end.
