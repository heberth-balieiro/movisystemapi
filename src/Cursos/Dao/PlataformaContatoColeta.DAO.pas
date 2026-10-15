unit PlataformaContatoColeta.DAO;

interface

uses
  Uni,
  System.JSON;

type
  TPlataformaContatoColetaDAO = class
  public
    class function Criar(
      const AConn:TUniConnection;
      const AIdUsuario:Int64;
      const ANome,ATipo,AUF:string;
      const ALimite,AWorkers:Integer
    ):Int64; static;

    class function Listar(
      const AConn:TUniConnection;
      const ASituacao,ATipo,AUF:string;
      const APagina,APorPagina:Integer
    ):TJSONObject; static;

    class function Buscar(
      const AConn:TUniConnection;
      const AId:Int64
    ):TJSONObject; static;

    class function ListarItens(
      const AConn:TUniConnection;
      const AIdColeta:Int64;
      const AClassificacao,ASituacaoRevisao:string;
      const APagina,APorPagina:Integer
    ):TJSONObject; static;

    class function ProximaPendente(
      const AConn:TUniConnection
    ):TJSONObject; static;

    class procedure MarcarProcessando(
      const AConn:TUniConnection;
      const AId:Int64;
      const ATotalAlvos:Integer
    ); static;

    class function InserirItem(
      const AConn:TUniConnection;
      const AIdColeta:Int64;
      const ANomeOrgao,ACidade,AUF,AEmail,ASite,APaginaOrigem,
            AClassificacao,AObservacao,ADataColeta:string
    ):Boolean; static;

    class procedure AtualizarProgresso(
      const AConn:TUniConnection;
      const AId:Int64;
      const ATotalProcessados,ATotalEmails,ATotalInstitucionais,
            ATotalRevisar,ATotalSemEmail:Integer
    ); static;

    class procedure Finalizar(
      const AConn:TUniConnection;
      const AId:Int64;
      const ATotalAlvos,ATotalProcessados,ATotalEmails,
            ATotalInstitucionais,ATotalRevisar,ATotalSemEmail:Integer
    ); static;

    class procedure MarcarErro(
      const AConn:TUniConnection;
      const AId:Int64;
      const AMensagem:string
    ); static;

    class procedure Cancelar(
      const AConn:TUniConnection;
      const AId:Int64
    ); static;

    class procedure AlterarSituacaoItem(
      const AConn:TUniConnection;
      const AIdColeta,AIdItem:Int64;
      const ASituacao:string
    ); static;

    class function ImportarAprovados(
      const AConn:TUniConnection;
      const AIdColeta,AIdLista,AIdUsuario:Int64
    ):TJSONObject; static;
  end;

implementation

uses
  System.SysUtils;

procedure AddNullable(const O:TJSONObject; const N,V:string);
begin
  if Trim(V).IsEmpty then
    O.AddPair(N,TJSONNull.Create)
  else
    O.AddPair(N,V);
end;

class function TPlataformaContatoColetaDAO.Criar(
  const AConn:TUniConnection;
  const AIdUsuario:Int64;
  const ANome,ATipo,AUF:string;
  const ALimite,AWorkers:Integer
):Int64;
var
  Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'INSERT INTO plataforma_contato_coleta ' +
      '(nome,tipo,uf,limite,workers,situacao,criado_por) ' +
      'VALUES (:nome,:tipo,:uf,:limite,:workers,''PENDENTE'',:usuario)';

    Q.ParamByName('nome').AsString:=ANome;
    Q.ParamByName('tipo').AsString:=ATipo;
    Q.ParamByName('uf').AsString:=AUF;
    Q.ParamByName('limite').AsInteger:=ALimite;
    Q.ParamByName('workers').AsInteger:=AWorkers;
    Q.ParamByName('usuario').AsLargeInt:=AIdUsuario;
    Q.Execute;

    Q.Close;
    Q.SQL.Text:='SELECT LAST_INSERT_ID() id';
    Q.Open;
    Result:=Q.FieldByName('id').AsLargeInt;
  finally
    Q.Free;
  end;
end;

class function TPlataformaContatoColetaDAO.Listar(
  const AConn:TUniConnection;
  const ASituacao,ATipo,AUF:string;
  const APagina,APorPagina:Integer
):TJSONObject;
var
  Q:TUniQuery;
  A:TJSONArray;
  J,P:TJSONObject;
  WhereSQL:string;
  Pagina,PorPagina,Total,TotalPaginas:Integer;

  procedure Params;
  begin
    if not Trim(ASituacao).IsEmpty then
      Q.ParamByName('situacao').AsString:=UpperCase(Trim(ASituacao));
    if not Trim(ATipo).IsEmpty then
      Q.ParamByName('tipo').AsString:=UpperCase(Trim(ATipo));
    if not Trim(AUF).IsEmpty then
      Q.ParamByName('uf').AsString:=UpperCase(Trim(AUF));
  end;

begin
  Pagina:=APagina;
  if Pagina<=0 then Pagina:=1;

  PorPagina:=APorPagina;
  if PorPagina<=0 then PorPagina:=50;
  if PorPagina>200 then PorPagina:=200;

  WhereSQL:=' WHERE 1=1 ';
  if not Trim(ASituacao).IsEmpty then
    WhereSQL:=WhereSQL+'AND situacao=:situacao ';
  if not Trim(ATipo).IsEmpty then
    WhereSQL:=WhereSQL+'AND tipo=:tipo ';
  if not Trim(AUF).IsEmpty then
    WhereSQL:=WhereSQL+'AND uf=:uf ';

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;

    Q.SQL.Text:=
      'SELECT COUNT(*) total ' +
      'FROM plataforma_contato_coleta ' + WhereSQL;
    Params;
    Q.Open;
    Total:=Q.FieldByName('total').AsInteger;

    Q.Close;
    Q.SQL.Text:=
      'SELECT * ' +
      'FROM plataforma_contato_coleta ' + WhereSQL +
      'ORDER BY id DESC LIMIT :limite OFFSET :offset';
    Params;
    Q.ParamByName('limite').AsInteger:=PorPagina;
    Q.ParamByName('offset').AsInteger:=(Pagina-1)*PorPagina;
    Q.Open;

    A:=TJSONArray.Create;
    while not Q.Eof do
    begin
      J:=TJSONObject.Create;
      J.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      J.AddPair('nome',Q.FieldByName('nome').AsString);
      J.AddPair('tipo',Q.FieldByName('tipo').AsString);
      J.AddPair('uf',Q.FieldByName('uf').AsString);
      J.AddPair('limite',TJSONNumber.Create(Q.FieldByName('limite').AsInteger));
      J.AddPair('workers',TJSONNumber.Create(Q.FieldByName('workers').AsInteger));
      J.AddPair('situacao',Q.FieldByName('situacao').AsString);
      J.AddPair('total_alvos',TJSONNumber.Create(Q.FieldByName('total_alvos').AsInteger));
      J.AddPair('total_processados',TJSONNumber.Create(Q.FieldByName('total_processados').AsInteger));
      J.AddPair('total_emails',TJSONNumber.Create(Q.FieldByName('total_emails').AsInteger));
      J.AddPair('total_institucionais',TJSONNumber.Create(Q.FieldByName('total_institucionais').AsInteger));
      J.AddPair('total_revisar',TJSONNumber.Create(Q.FieldByName('total_revisar').AsInteger));
      J.AddPair('total_sem_email',TJSONNumber.Create(Q.FieldByName('total_sem_email').AsInteger));
      AddNullable(J,'mensagem_erro',Q.FieldByName('mensagem_erro').AsString);
      J.AddPair('criado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('criado_em').AsDateTime));

      if Q.FieldByName('iniciado_em').IsNull then
        J.AddPair('iniciado_em',TJSONNull.Create)
      else
        J.AddPair('iniciado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('iniciado_em').AsDateTime));

      if Q.FieldByName('finalizado_em').IsNull then
        J.AddPair('finalizado_em',TJSONNull.Create)
      else
        J.AddPair('finalizado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('finalizado_em').AsDateTime));

      A.AddElement(J);
      Q.Next;
    end;

    TotalPaginas:=0;
    if Total>0 then
      TotalPaginas:=(Total+PorPagina-1) div PorPagina;

    P:=TJSONObject.Create;
    P.AddPair('pagina',TJSONNumber.Create(Pagina));
    P.AddPair('por_pagina',TJSONNumber.Create(PorPagina));
    P.AddPair('total',TJSONNumber.Create(Total));
    P.AddPair('total_paginas',TJSONNumber.Create(TotalPaginas));

    Result:=TJSONObject.Create;
    Result.AddPair('itens',A);
    Result.AddPair('paginacao',P);
  finally
    Q.Free;
  end;
end;

class function TPlataformaContatoColetaDAO.Buscar(
  const AConn:TUniConnection;
  const AId:Int64
):TJSONObject;
var
  Q:TUniQuery;
begin
  Result:=nil;
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:='SELECT * FROM plataforma_contato_coleta WHERE id=:id LIMIT 1';
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Open;

    if Q.IsEmpty then Exit;

    Result:=TJSONObject.Create;
    Result.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
    Result.AddPair('nome',Q.FieldByName('nome').AsString);
    Result.AddPair('tipo',Q.FieldByName('tipo').AsString);
    Result.AddPair('uf',Q.FieldByName('uf').AsString);
    Result.AddPair('limite',TJSONNumber.Create(Q.FieldByName('limite').AsInteger));
    Result.AddPair('workers',TJSONNumber.Create(Q.FieldByName('workers').AsInteger));
    Result.AddPair('situacao',Q.FieldByName('situacao').AsString);
    Result.AddPair('total_alvos',TJSONNumber.Create(Q.FieldByName('total_alvos').AsInteger));
    Result.AddPair('total_processados',TJSONNumber.Create(Q.FieldByName('total_processados').AsInteger));
    Result.AddPair('total_emails',TJSONNumber.Create(Q.FieldByName('total_emails').AsInteger));
    Result.AddPair('total_institucionais',TJSONNumber.Create(Q.FieldByName('total_institucionais').AsInteger));
    Result.AddPair('total_revisar',TJSONNumber.Create(Q.FieldByName('total_revisar').AsInteger));
    Result.AddPair('total_sem_email',TJSONNumber.Create(Q.FieldByName('total_sem_email').AsInteger));
    AddNullable(Result,'mensagem_erro',Q.FieldByName('mensagem_erro').AsString);
    Result.AddPair('criado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('criado_em').AsDateTime));

    if Q.FieldByName('iniciado_em').IsNull then
      Result.AddPair('iniciado_em',TJSONNull.Create)
    else
      Result.AddPair('iniciado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('iniciado_em').AsDateTime));

    if Q.FieldByName('finalizado_em').IsNull then
      Result.AddPair('finalizado_em',TJSONNull.Create)
    else
      Result.AddPair('finalizado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('finalizado_em').AsDateTime));
  finally
    Q.Free;
  end;
end;

class function TPlataformaContatoColetaDAO.ListarItens(
  const AConn:TUniConnection;
  const AIdColeta:Int64;
  const AClassificacao,ASituacaoRevisao:string;
  const APagina,APorPagina:Integer
):TJSONObject;
var
  Q:TUniQuery;
  A:TJSONArray;
  J,P:TJSONObject;
  W:string;
  Pagina,PorPagina,Total,TotalPaginas:Integer;

  procedure Params;
  begin
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    if not Trim(AClassificacao).IsEmpty then
      Q.ParamByName('classificacao').AsString:=UpperCase(Trim(AClassificacao));
    if not Trim(ASituacaoRevisao).IsEmpty then
      Q.ParamByName('revisao').AsString:=UpperCase(Trim(ASituacaoRevisao));
  end;

begin
  Pagina:=APagina;
  if Pagina<=0 then Pagina:=1;

  PorPagina:=APorPagina;
  if PorPagina<=0 then PorPagina:=100;
  if PorPagina>500 then PorPagina:=500;

  W:=' WHERE id_coleta=:coleta ';
  if not Trim(AClassificacao).IsEmpty then
    W:=W+'AND classificacao=:classificacao ';
  if not Trim(ASituacaoRevisao).IsEmpty then
    W:=W+'AND situacao_revisao=:revisao ';

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'SELECT COUNT(*) total ' +
      'FROM plataforma_contato_coleta_item ' + W;
    Params;
    Q.Open;
    Total:=Q.FieldByName('total').AsInteger;

    Q.Close;
    Q.SQL.Text:=
      'SELECT * ' +
      'FROM plataforma_contato_coleta_item ' + W +
      'ORDER BY cidade,email,id LIMIT :limite OFFSET :offset';
    Params;
    Q.ParamByName('limite').AsInteger:=PorPagina;
    Q.ParamByName('offset').AsInteger:=(Pagina-1)*PorPagina;
    Q.Open;

    A:=TJSONArray.Create;
    while not Q.Eof do
    begin
      J:=TJSONObject.Create;
      J.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      J.AddPair('nome_orgao',Q.FieldByName('nome_orgao').AsString);
      J.AddPair('cidade',Q.FieldByName('cidade').AsString);
      J.AddPair('uf',Q.FieldByName('uf').AsString);
      AddNullable(J,'email',Q.FieldByName('email').AsString);
      AddNullable(J,'site',Q.FieldByName('site').AsString);
      AddNullable(J,'pagina_origem',Q.FieldByName('pagina_origem').AsString);
      J.AddPair('classificacao',Q.FieldByName('classificacao').AsString);
      AddNullable(J,'observacao',Q.FieldByName('observacao').AsString);
      J.AddPair('situacao_revisao',Q.FieldByName('situacao_revisao').AsString);

      if Q.FieldByName('id_contato').IsNull then
        J.AddPair('id_contato',TJSONNull.Create)
      else
        J.AddPair('id_contato',TJSONNumber.Create(Q.FieldByName('id_contato').AsLargeInt));

      if Q.FieldByName('coletado_em').IsNull then
        J.AddPair('coletado_em',TJSONNull.Create)
      else
        J.AddPair('coletado_em',FormatDateTime('yyyy-mm-dd',Q.FieldByName('coletado_em').AsDateTime));

      A.AddElement(J);
      Q.Next;
    end;

    TotalPaginas:=0;
    if Total>0 then
      TotalPaginas:=(Total+PorPagina-1) div PorPagina;

    P:=TJSONObject.Create;
    P.AddPair('pagina',TJSONNumber.Create(Pagina));
    P.AddPair('por_pagina',TJSONNumber.Create(PorPagina));
    P.AddPair('total',TJSONNumber.Create(Total));
    P.AddPair('total_paginas',TJSONNumber.Create(TotalPaginas));

    Result:=TJSONObject.Create;
    Result.AddPair('itens',A);
    Result.AddPair('paginacao',P);
  finally
    Q.Free;
  end;
end;

class function TPlataformaContatoColetaDAO.ProximaPendente(
  const AConn:TUniConnection
):TJSONObject;
var
  Q:TUniQuery;
begin
  Result:=nil;
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'SELECT id,nome,tipo,uf,limite,workers ' +
      'FROM plataforma_contato_coleta ' +
      'WHERE situacao=''PENDENTE'' ' +
      'ORDER BY id LIMIT 1';
    Q.Open;

    if Q.IsEmpty then Exit;

    Result:=TJSONObject.Create;
    Result.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
    Result.AddPair('nome',Q.FieldByName('nome').AsString);
    Result.AddPair('tipo',Q.FieldByName('tipo').AsString);
    Result.AddPair('uf',Q.FieldByName('uf').AsString);
    Result.AddPair('limite',TJSONNumber.Create(Q.FieldByName('limite').AsInteger));
    Result.AddPair('workers',TJSONNumber.Create(Q.FieldByName('workers').AsInteger));
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaContatoColetaDAO.MarcarProcessando(
  const AConn:TUniConnection;
  const AId:Int64;
  const ATotalAlvos:Integer
);
var
  Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta SET ' +
      'situacao=''PROCESSANDO'',' +
      'iniciado_em=COALESCE(iniciado_em,CURRENT_TIMESTAMP(3)),' +
      'finalizado_em=NULL,mensagem_erro=NULL,total_alvos=:total ' +
      'WHERE id=:id AND situacao=''PENDENTE''';
    Q.ParamByName('total').AsInteger:=ATotalAlvos;
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Execute;
  finally
    Q.Free;
  end;
end;

class function TPlataformaContatoColetaDAO.InserirItem(
  const AConn:TUniConnection;
  const AIdColeta:Int64;
  const ANomeOrgao,ACidade,AUF,AEmail,ASite,APaginaOrigem,
        AClassificacao,AObservacao,ADataColeta:string
):Boolean;
var
  Q:TUniQuery;
  D:TDateTime;
  TemData:Boolean;
  Y,M,Day:Word;

  procedure S(const N,V:string);
  begin
    if Trim(V).IsEmpty then
      Q.ParamByName(N).Clear
    else
      Q.ParamByName(N).AsString:=Trim(V);
  end;

begin
  TemData:=False;
  D:=0;
  if Length(Trim(ADataColeta))=10 then
  begin
    Y:=StrToIntDef(Copy(ADataColeta,1,4),0);
    M:=StrToIntDef(Copy(ADataColeta,6,2),0);
    Day:=StrToIntDef(Copy(ADataColeta,9,2),0);
    TemData:=TryEncodeDate(Y,M,Day,D);
  end;

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'INSERT IGNORE INTO plataforma_contato_coleta_item ' +
      '(id_coleta,nome_orgao,cidade,uf,email,site,pagina_origem,' +
      'classificacao,observacao,situacao_revisao,coletado_em) ' +
      'VALUES (:coleta,:nome,:cidade,:uf,:email,:site,:pagina,' +
      ':classificacao,:obs,:revisao,:data)';

    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.ParamByName('nome').AsString:=Trim(ANomeOrgao);
    Q.ParamByName('cidade').AsString:=Trim(ACidade);
    Q.ParamByName('uf').AsString:=UpperCase(Trim(AUF));
    S('email',LowerCase(Trim(AEmail)));
    S('site',ASite);
    S('pagina',APaginaOrigem);
    Q.ParamByName('classificacao').AsString:=UpperCase(Trim(AClassificacao));
    S('obs',AObservacao);

    if SameText(Trim(AClassificacao),'INSTITUCIONAL') then
      Q.ParamByName('revisao').AsString:='APROVADO'
    else
      Q.ParamByName('revisao').AsString:='PENDENTE';

    if TemData then
      Q.ParamByName('data').AsDateTime:=D
    else
      Q.ParamByName('data').Clear;

    Q.Execute;
    Result:=Q.RowsAffected>0;
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaContatoColetaDAO.AtualizarProgresso(
  const AConn:TUniConnection;
  const AId:Int64;
  const ATotalProcessados,ATotalEmails,ATotalInstitucionais,
        ATotalRevisar,ATotalSemEmail:Integer
);
var
  Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta SET ' +
      'total_processados=:p,total_emails=:e,total_institucionais=:i,' +
      'total_revisar=:r,total_sem_email=:s ' +
      'WHERE id=:id AND situacao=''PROCESSANDO''';
    Q.ParamByName('p').AsInteger:=ATotalProcessados;
    Q.ParamByName('e').AsInteger:=ATotalEmails;
    Q.ParamByName('i').AsInteger:=ATotalInstitucionais;
    Q.ParamByName('r').AsInteger:=ATotalRevisar;
    Q.ParamByName('s').AsInteger:=ATotalSemEmail;
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Execute;
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaContatoColetaDAO.Finalizar(
  const AConn:TUniConnection;
  const AId:Int64;
  const ATotalAlvos,ATotalProcessados,ATotalEmails,
        ATotalInstitucionais,ATotalRevisar,ATotalSemEmail:Integer
);
var
  Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta SET ' +
      'situacao=''CONCLUIDA'',total_alvos=:a,total_processados=:p,' +
      'total_emails=:e,total_institucionais=:i,total_revisar=:r,' +
      'total_sem_email=:s,finalizado_em=CURRENT_TIMESTAMP(3),' +
      'mensagem_erro=NULL ' +
      'WHERE id=:id AND situacao=''PROCESSANDO''';
    Q.ParamByName('a').AsInteger:=ATotalAlvos;
    Q.ParamByName('p').AsInteger:=ATotalProcessados;
    Q.ParamByName('e').AsInteger:=ATotalEmails;
    Q.ParamByName('i').AsInteger:=ATotalInstitucionais;
    Q.ParamByName('r').AsInteger:=ATotalRevisar;
    Q.ParamByName('s').AsInteger:=ATotalSemEmail;
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Execute;
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaContatoColetaDAO.MarcarErro(
  const AConn:TUniConnection;
  const AId:Int64;
  const AMensagem:string
);
var
  Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta SET ' +
      'situacao=''ERRO'',mensagem_erro=:m,' +
      'finalizado_em=CURRENT_TIMESTAMP(3) ' +
      'WHERE id=:id AND situacao IN (''PENDENTE'',''PROCESSANDO'')';
    Q.ParamByName('m').AsString:=Copy(Trim(AMensagem),1,4000);
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Execute;
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaContatoColetaDAO.Cancelar(
  const AConn:TUniConnection;
  const AId:Int64
);
var
  Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta SET ' +
      'situacao=''CANCELADA'',finalizado_em=CURRENT_TIMESTAMP(3) ' +
      'WHERE id=:id AND situacao IN (''PENDENTE'',''PROCESSANDO'')';
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Execute;
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaContatoColetaDAO.AlterarSituacaoItem(
  const AConn:TUniConnection;
  const AIdColeta,AIdItem:Int64;
  const ASituacao:string
);
var
  Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta_item SET situacao_revisao=:s ' +
      'WHERE id=:item AND id_coleta=:coleta ' +
      'AND situacao_revisao<>''IMPORTADO''';
    Q.ParamByName('s').AsString:=ASituacao;
    Q.ParamByName('item').AsLargeInt:=AIdItem;
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Execute;
  finally
    Q.Free;
  end;
end;

class function TPlataformaContatoColetaDAO.ImportarAprovados(
  const AConn:TUniConnection;
  const AIdColeta,AIdLista,AIdUsuario:Int64
):TJSONObject;
var
  Q:TUniQuery;
  Novos,Existentes,Vinculados:Integer;
begin
  Novos:=0;
  Existentes:=0;
  Vinculados:=0;

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;

    Q.SQL.Text:=
      'SELECT COUNT(*) total ' +
      'FROM plataforma_contato_coleta_item ' +
      'WHERE id_coleta=:coleta ' +
      'AND situacao_revisao=''APROVADO'' ' +
      'AND COALESCE(email,'''')<>''''';
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Open;
    Existentes:=Q.FieldByName('total').AsInteger;

    Q.Close;
    Q.SQL.Text:=
      'INSERT INTO plataforma_contato ' +
      '(razao_social,nome_fantasia,email,email_normalizado,grau,cidade,uf,' +
      'orgao,site,observacao,fonte,data_coleta,situacao,criado_por) ' +
      'SELECT i.nome_orgao,i.nome_orgao,i.email,LOWER(i.email),' +
      '''Câmara Municipal'',i.cidade,i.uf,''Câmara Municipal'',i.site,' +
      'i.observacao,i.pagina_origem,i.coletado_em,''ATIVO'',:usuario ' +
      'FROM plataforma_contato_coleta_item i ' +
      'WHERE i.id_coleta=:coleta ' +
      'AND i.situacao_revisao=''APROVADO'' ' +
      'AND COALESCE(i.email,'''')<>'''' ' +
      'AND NOT EXISTS (' +
      'SELECT 1 FROM plataforma_contato c ' +
      'WHERE c.email_normalizado=LOWER(i.email))';
    Q.ParamByName('usuario').AsLargeInt:=AIdUsuario;
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Execute;
    Novos:=Q.RowsAffected;
    Existentes:=Existentes-Novos;

    Q.Close;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta_item i ' +
      'JOIN plataforma_contato c ' +
      'ON c.email_normalizado=LOWER(i.email) ' +
      'SET i.id_contato=c.id,i.situacao_revisao=''IMPORTADO'' ' +
      'WHERE i.id_coleta=:coleta ' +
      'AND i.situacao_revisao=''APROVADO''';
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Execute;

    if AIdLista>0 then
    begin
      Q.Close;
      Q.SQL.Text:=
        'INSERT IGNORE INTO plataforma_contato_lista_item ' +
        '(id_lista,id_contato) ' +
        'SELECT :lista,id_contato ' +
        'FROM plataforma_contato_coleta_item ' +
        'WHERE id_coleta=:coleta ' +
        'AND situacao_revisao=''IMPORTADO'' ' +
        'AND id_contato IS NOT NULL';
      Q.ParamByName('lista').AsLargeInt:=AIdLista;
      Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
      Q.Execute;
      Vinculados:=Q.RowsAffected;
    end;

    Result:=TJSONObject.Create;
    Result.AddPair('novos',TJSONNumber.Create(Novos));
    Result.AddPair('existentes',TJSONNumber.Create(Existentes));
    Result.AddPair('vinculados_lista',TJSONNumber.Create(Vinculados));
  finally
    Q.Free;
  end;
end;

end.
