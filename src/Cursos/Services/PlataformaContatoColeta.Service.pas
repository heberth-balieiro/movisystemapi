unit PlataformaContatoColeta.Service;

interface

uses
  System.JSON;

type
  TPlataformaContatoColetaService = class
  public
    class function Criar(
      const AIdUsuario:Int64;
      const ANome,ATipo,AUF,AModoAlvo,AMunicipio,ATermoBusca,ASegmento:string;
      const ALimite,AWorkers:Integer
    ):TJSONObject; static;
    class function Listar(const ASituacao,ATipo,AUF:string; const APagina,APorPagina:Integer):TJSONObject; static;
    class function Buscar(const AId:Int64):TJSONObject; static;
    class function ListarItens(const AIdColeta:Int64; const AClassificacao,ASituacaoRevisao:string; const APagina,APorPagina:Integer):TJSONObject; static;
    class function ProximaPendente:TJSONObject; static;
    class function Iniciar(const AId:Int64; const ATotalAlvos:Integer):TJSONObject; static;
    class function ReceberResultados(const AId:Int64; const AItens:TJSONArray; const AProgresso:TJSONObject):TJSONObject; static;
    class function Finalizar(const AId:Int64; const AResumo:TJSONObject):TJSONObject; static;
    class function MarcarErro(const AId:Int64; const AMensagem:string):TJSONObject; static;
    class function Cancelar(const AIdUsuario,AId:Int64):TJSONObject; static;
    class function RevisarItem(const AIdUsuario,AIdColeta,AIdItem:Int64; const ASituacao:string):TJSONObject; static;
    class function ImportarAprovados(const AIdUsuario,AIdColeta,AIdLista:Int64):TJSONObject; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaContatoColeta.DAO,
  PlataformaContatoColetaEntidade.DAO,
  PlataformaContato.DAO;

function NovaConexao:TUniConnection;
var C:TAppApiConfig;
begin
  C:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Result:=TDatabaseConnection.NewConnection(C.Database);
end;

function JStr(const O:TJSONObject; const N:string):string;
var V:TJSONValue;
begin
  Result:='';
  if O=nil then Exit;
  V:=O.GetValue(N);
  if (V<>nil) and not (V is TJSONNull) then Result:=V.Value;
end;

function JInt(const O:TJSONObject; const N:string):Integer;
begin
  Result:=StrToIntDef(JStr(O,N),0);
end;

function JBool(const O:TJSONObject; const N:string):Boolean;
var S:string;
begin
  S:=LowerCase(Trim(JStr(O,N)));
  Result:=MatchText(S,['1','true','sim','yes']);
end;

function TipoEntidade(const ATipo:string):Boolean;
begin
  Result:=MatchText(UpperCase(Trim(ATipo)),['SINDICATO','ASSOCIACAO']);
end;

function TipoParlamentarColeta(const ATipo:string):Boolean;
begin
  Result:=MatchText(UpperCase(Trim(ATipo)),['VEREADOR','DEPUTADO_ESTADUAL','UNALE_ASSOCIADO']);
end;

class function TPlataformaContatoColetaService.Criar(
  const AIdUsuario:Int64;
  const ANome,ATipo,AUF,AModoAlvo,AMunicipio,ATermoBusca,ASegmento:string;
  const ALimite,AWorkers:Integer
):TJSONObject;
var
  C:TUniConnection;
  Id:Int64;
  Tipo,UF,Modo,Municipio,TermoBusca,Segmento:string;
  Limite,Workers:Integer;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  if Trim(ANome).IsEmpty then TAppErrors.RaiseBadRequest('Informe o nome da coleta.');

  Tipo:=UpperCase(Trim(ATipo));
  if Tipo.IsEmpty then Tipo:='CAMARA';
  if not MatchText(Tipo,[
    'CAMARA','PREFEITURA','SINDICATO','ASSOCIACAO',
    'VEREADOR','DEPUTADO_ESTADUAL','UNALE_ASSOCIADO'
  ]) then
    TAppErrors.RaiseBadRequest('Tipo de coleta não suportado.');

  UF:=UpperCase(Trim(AUF));
  if Length(UF)<>2 then TAppErrors.RaiseBadRequest('UF inválida.');

  Modo:=UpperCase(Trim(AModoAlvo));
  if Modo.IsEmpty then Modo:='TODOS';
  if not MatchText(Modo,['TODOS','MUNICIPIO','SEM_CONTATO']) then
    TAppErrors.RaiseBadRequest('Modo de alvo inválido.');

  if (TipoEntidade(Tipo) or TipoParlamentarColeta(Tipo)) and SameText(Modo,'SEM_CONTATO') then
    TAppErrors.RaiseBadRequest('O modo SEM_CONTATO ainda não se aplica a este tipo de coleta.');

  if MatchText(Tipo,['DEPUTADO_ESTADUAL','UNALE_ASSOCIADO']) and SameText(Modo,'MUNICIPIO') then
    TAppErrors.RaiseBadRequest('Deputados estaduais e associados UNALE são coletados por UF, não por município.');

  Municipio:=Trim(AMunicipio);
  if (Modo='MUNICIPIO') and Municipio.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o município da coleta.');
  if Modo<>'MUNICIPIO' then Municipio:='';

  TermoBusca:=Trim(ATermoBusca);
  Segmento:=UpperCase(Trim(ASegmento));
  if TipoEntidade(Tipo) and TermoBusca.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o termo de busca para sindicato ou associação.');

  Limite:=ALimite;
  if Limite<0 then Limite:=0;
  if Modo='MUNICIPIO' then Limite:=1;

  Workers:=AWorkers;
  if Workers<=0 then Workers:=6;
  if Workers>20 then Workers:=20;

  C:=NovaConexao;
  try
    C.StartTransaction;
    try
      Id:=TPlataformaContatoColetaDAO.Criar(
        C,AIdUsuario,Trim(ANome),Tipo,UF,Modo,Municipio,Limite,Workers
      );
      TPlataformaContatoColetaEntidadeDAO.AtualizarParametros(
        C,Id,TermoBusca,Segmento
      );
      TPlataformaContatoDAO.RegistrarAuditoria(
        C,AIdUsuario,'COLETA_CRIADA','plataforma_contato_coleta',Id.ToString,
        'Coleta de contatos criada.','',''
      );
      C.Commit;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;

    Result:=TPlataformaContatoColetaDAO.Buscar(C,Id);
    TPlataformaContatoColetaEntidadeDAO.EnriquecerColeta(C,Id,Result);
  finally
    C.Free;
  end;
end;

class function TPlataformaContatoColetaService.Listar(const ASituacao,ATipo,AUF:string; const APagina,APorPagina:Integer):TJSONObject;
var C:TUniConnection;
begin
  C:=NovaConexao;
  try
    Result:=TPlataformaContatoColetaDAO.Listar(C,ASituacao,ATipo,AUF,APagina,APorPagina);
    TPlataformaContatoColetaEntidadeDAO.EnriquecerLista(C,Result);
  finally
    C.Free;
  end;
end;

class function TPlataformaContatoColetaService.Buscar(const AId:Int64):TJSONObject;
var C:TUniConnection;
begin
  if AId<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  C:=NovaConexao;
  try
    Result:=TPlataformaContatoColetaDAO.Buscar(C,AId);
    if Result=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    TPlataformaContatoColetaEntidadeDAO.EnriquecerColeta(C,AId,Result);
  finally
    C.Free;
  end;
end;

class function TPlataformaContatoColetaService.ListarItens(const AIdColeta:Int64; const AClassificacao,ASituacaoRevisao:string; const APagina,APorPagina:Integer):TJSONObject;
var C:TUniConnection; J:TJSONObject;
begin
  if AIdColeta<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  C:=NovaConexao;
  try
    J:=TPlataformaContatoColetaDAO.Buscar(C,AIdColeta);
    if J=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    J.Free;
    Result:=TPlataformaContatoColetaDAO.ListarItens(C,AIdColeta,AClassificacao,ASituacaoRevisao,APagina,APorPagina);
    TPlataformaContatoColetaEntidadeDAO.EnriquecerItensParlamentares(C,Result);
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.ProximaPendente:TJSONObject;
var C:TUniConnection; Modo,Tipo,UF:string; Municipios:TJSONArray; V:TJSONValue; Id:Int64;
begin
  C:=NovaConexao;
  try
    Result:=TPlataformaContatoColetaDAO.ProximaPendente(C);
    if Result=nil then Exit;

    V:=Result.GetValue('id');
    Id:=0;
    if V<>nil then Id:=StrToInt64Def(V.Value,0);
    TPlataformaContatoColetaEntidadeDAO.EnriquecerColeta(C,Id,Result);

    Modo:=JStr(Result,'modo_alvo');
    if SameText(Modo,'SEM_CONTATO') then
    begin
      Tipo:=JStr(Result,'tipo');
      UF:=JStr(Result,'uf');
      Municipios:=TPlataformaContatoColetaDAO.ListarMunicipiosComContato(C,Tipo,UF);
      Result.AddPair('municipios_ignorar',Municipios);
    end;
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.Iniciar(const AId:Int64; const ATotalAlvos:Integer):TJSONObject;
var C:TUniConnection; J:TJSONObject;
begin
  if AId<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  C:=NovaConexao;
  try
    J:=TPlataformaContatoColetaDAO.Buscar(C,AId);
    if J=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    try
      if not SameText(JStr(J,'situacao'),'PENDENTE') then
        TAppErrors.RaiseBadRequest('A coleta não está pendente.');
    finally J.Free; end;
    TPlataformaContatoColetaDAO.MarcarProcessando(C,AId,ATotalAlvos);
    Result:=TPlataformaContatoColetaDAO.Buscar(C,AId);
    TPlataformaContatoColetaEntidadeDAO.EnriquecerColeta(C,AId,Result);
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.ReceberResultados(const AId:Int64; const AItens:TJSONArray; const AProgresso:TJSONObject):TJSONObject;
var C:TUniConnection; I,Inseridos:Integer; V:TJSONValue; O,J:TJSONObject; TipoColeta:string; Inseriu:Boolean;
begin
  if AId<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  if AItens=nil then TAppErrors.RaiseBadRequest('Itens não informados.');
  C:=NovaConexao;
  try
    J:=TPlataformaContatoColetaDAO.Buscar(C,AId);
    if J=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    try
      if not SameText(JStr(J,'situacao'),'PROCESSANDO') then
        TAppErrors.RaiseBadRequest('A coleta não está em processamento.');
      TipoColeta:=JStr(J,'tipo');
    finally J.Free; end;

    Inseridos:=0;
    C.StartTransaction;
    try
      for I:=0 to AItens.Count-1 do
      begin
        V:=AItens.Items[I];
        if not (V is TJSONObject) then Continue;
        O:=V as TJSONObject;
        if Trim(JStr(O,'nome_orgao')).IsEmpty or Trim(JStr(O,'cidade')).IsEmpty or
           Trim(JStr(O,'uf')).IsEmpty or Trim(JStr(O,'classificacao')).IsEmpty then Continue;
        Inseriu:=TPlataformaContatoColetaDAO.InserirItem(
          C,AId,JStr(O,'nome_orgao'),JStr(O,'cidade'),JStr(O,'uf'),JStr(O,'email'),
          JStr(O,'site'),JStr(O,'pagina_origem'),JStr(O,'classificacao'),
          JStr(O,'observacao'),JStr(O,'data_coleta')
        );
        if Inseriu then Inc(Inseridos);

        if TipoParlamentarColeta(TipoColeta) then
          TPlataformaContatoColetaEntidadeDAO.AtualizarMetadadosParlamentar(
            C,AId,JStr(O,'nome_orgao'),JStr(O,'cidade'),JStr(O,'uf'),JStr(O,'email'),
            'PARLAMENTAR',JStr(O,'cargo'),JStr(O,'partido'),JStr(O,'id_externo'),
            JStr(O,'fonte_dados'),JStr(O,'url_perfil'),JStr(O,'foto_url'),
            JBool(O,'unale_associado') or SameText(TipoColeta,'UNALE_ASSOCIADO')
          );
      end;
      if AProgresso<>nil then
        TPlataformaContatoColetaDAO.AtualizarProgresso(
          C,AId,JInt(AProgresso,'total_processados'),JInt(AProgresso,'total_emails'),
          JInt(AProgresso,'total_institucionais'),JInt(AProgresso,'total_revisar'),
          JInt(AProgresso,'total_sem_email')
        );
      C.Commit;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;

    Result:=TJSONObject.Create;
    Result.AddPair('inseridos',TJSONNumber.Create(Inseridos));
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.Finalizar(const AId:Int64; const AResumo:TJSONObject):TJSONObject;
var C:TUniConnection;
begin
  if (AId<=0) or (AResumo=nil) then TAppErrors.RaiseBadRequest('Resumo da coleta inválido.');
  C:=NovaConexao;
  try
    TPlataformaContatoColetaDAO.Finalizar(
      C,AId,JInt(AResumo,'total_alvos'),JInt(AResumo,'total_processados'),
      JInt(AResumo,'total_emails'),JInt(AResumo,'total_institucionais'),
      JInt(AResumo,'total_revisar'),JInt(AResumo,'total_sem_email')
    );
    Result:=TPlataformaContatoColetaDAO.Buscar(C,AId);
    if Result=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    TPlataformaContatoColetaEntidadeDAO.EnriquecerColeta(C,AId,Result);
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.MarcarErro(const AId:Int64; const AMensagem:string):TJSONObject;
var C:TUniConnection;
begin
  if AId<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  C:=NovaConexao;
  try
    TPlataformaContatoColetaDAO.MarcarErro(C,AId,AMensagem);
    Result:=TPlataformaContatoColetaDAO.Buscar(C,AId);
    if Result=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    TPlataformaContatoColetaEntidadeDAO.EnriquecerColeta(C,AId,Result);
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.Cancelar(const AIdUsuario,AId:Int64):TJSONObject;
var C:TUniConnection; J:TJSONObject;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  C:=NovaConexao;
  try
    J:=TPlataformaContatoColetaDAO.Buscar(C,AId);
    if J=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    J.Free;
    C.StartTransaction;
    try
      TPlataformaContatoColetaDAO.Cancelar(C,AId);
      TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'COLETA_CANCELADA','plataforma_contato_coleta',AId.ToString,'Coleta de contatos cancelada.','','');
      C.Commit;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
    Result:=TPlataformaContatoColetaDAO.Buscar(C,AId);
    TPlataformaContatoColetaEntidadeDAO.EnriquecerColeta(C,AId,Result);
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.RevisarItem(const AIdUsuario,AIdColeta,AIdItem:Int64; const ASituacao:string):TJSONObject;
var C:TUniConnection; Sit:string;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  Sit:=UpperCase(Trim(ASituacao));
  if not MatchText(Sit,['APROVADO','DESCARTADO']) then TAppErrors.RaiseBadRequest('Situação de revisão inválida.');
  C:=NovaConexao;
  try
    TPlataformaContatoColetaDAO.AlterarSituacaoItem(C,AIdColeta,AIdItem,Sit);
    Result:=TJSONObject.Create;
    Result.AddPair('id',TJSONNumber.Create(AIdItem));
    Result.AddPair('situacao_revisao',Sit);
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.ImportarAprovados(const AIdUsuario,AIdColeta,AIdLista:Int64):TJSONObject;
var C:TUniConnection; J:TJSONObject; Tipo:string;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  if AIdColeta<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  C:=NovaConexao;
  try
    if (AIdLista>0) and not TPlataformaContatoDAO.ListaExiste(C,AIdLista) then
      TAppErrors.RaiseBadRequest('Lista de contatos não encontrada.');

    J:=TPlataformaContatoColetaDAO.Buscar(C,AIdColeta);
    if J=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    try Tipo:=JStr(J,'tipo'); finally J.Free; end;

    C.StartTransaction;
    try
      if TipoEntidade(Tipo) then
        Result:=TPlataformaContatoColetaEntidadeDAO.ImportarAprovados(C,AIdColeta,AIdLista,AIdUsuario)
      else if TipoParlamentarColeta(Tipo) then
        Result:=TPlataformaContatoColetaEntidadeDAO.ImportarAprovadosParlamentares(C,AIdColeta,AIdLista,AIdUsuario)
      else
        Result:=TPlataformaContatoColetaDAO.ImportarAprovados(C,AIdColeta,AIdLista,AIdUsuario);

      TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'COLETA_IMPORTADA','plataforma_contato_coleta',AIdColeta.ToString,'Contatos aprovados da coleta importados para a base.','','');
      C.Commit;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
  finally C.Free; end;
end;

end.
