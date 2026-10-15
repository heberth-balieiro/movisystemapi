unit PlataformaContatoColeta.Service;

interface

uses
  System.JSON;

type
  TPlataformaContatoColetaService = class
  public
    class function Criar(const AIdUsuario:Int64; const ANome,ATipo,AUF:string; const ALimite,AWorkers:Integer):TJSONObject; static;
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
  PlataformaContato.DAO;

function NovaConexao:TUniConnection;
var C:TAppApiConfig;
begin
  C:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Result:=TDatabaseConnection.NewConnection(C.Database);
end;

function JStr(const O:TJSONObject; const N:string):string;
var V:TJSONValue;
begin Result:=''; if O=nil then Exit; V:=O.GetValue(N); if (V<>nil) and not (V is TJSONNull) then Result:=V.Value; end;

function JInt(const O:TJSONObject; const N:string):Integer;
begin Result:=StrToIntDef(JStr(O,N),0); end;

class function TPlataformaContatoColetaService.Criar(const AIdUsuario:Int64; const ANome,ATipo,AUF:string; const ALimite,AWorkers:Integer):TJSONObject;
var C:TUniConnection; Id:Int64; Tipo,UF:string; Limite,Workers:Integer;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  if Trim(ANome).IsEmpty then TAppErrors.RaiseBadRequest('Informe o nome da coleta.');
  Tipo:=UpperCase(Trim(ATipo)); if Tipo.IsEmpty then Tipo:='CAMARA';
  if not MatchText(Tipo,['CAMARA']) then TAppErrors.RaiseBadRequest('Tipo de coleta ainda não suportado. Use CAMARA.');
  UF:=UpperCase(Trim(AUF)); if Length(UF)<>2 then TAppErrors.RaiseBadRequest('UF inválida.');
  Limite:=ALimite; if Limite<0 then Limite:=0;
  Workers:=AWorkers; if Workers<=0 then Workers:=6; if Workers>20 then Workers:=20;
  C:=NovaConexao; try
    C.StartTransaction;
    try
      Id:=TPlataformaContatoColetaDAO.Criar(C,AIdUsuario,Trim(ANome),Tipo,UF,Limite,Workers);
      TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'COLETA_CRIADA','plataforma_contato_coleta',Id.ToString,'Coleta de contatos criada.','','');
      C.Commit;
    except if C.InTransaction then C.Rollback; raise; end;
    Result:=TPlataformaContatoColetaDAO.Buscar(C,Id);
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.Listar(const ASituacao,ATipo,AUF:string; const APagina,APorPagina:Integer):TJSONObject;
var C:TUniConnection;
begin C:=NovaConexao; try Result:=TPlataformaContatoColetaDAO.Listar(C,ASituacao,ATipo,AUF,APagina,APorPagina); finally C.Free; end; end;

class function TPlataformaContatoColetaService.Buscar(const AId:Int64):TJSONObject;
var C:TUniConnection;
begin if AId<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.'); C:=NovaConexao; try Result:=TPlataformaContatoColetaDAO.Buscar(C,AId); if Result=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.'); finally C.Free; end; end;

class function TPlataformaContatoColetaService.ListarItens(const AIdColeta:Int64; const AClassificacao,ASituacaoRevisao:string; const APagina,APorPagina:Integer):TJSONObject;
var C:TUniConnection; J:TJSONObject;
begin
  if AIdColeta<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  C:=NovaConexao; try J:=TPlataformaContatoColetaDAO.Buscar(C,AIdColeta); if J=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.'); J.Free; Result:=TPlataformaContatoColetaDAO.ListarItens(C,AIdColeta,AClassificacao,ASituacaoRevisao,APagina,APorPagina); finally C.Free; end;
end;

class function TPlataformaContatoColetaService.ProximaPendente:TJSONObject;
var C:TUniConnection;
begin C:=NovaConexao; try Result:=TPlataformaContatoColetaDAO.ProximaPendente(C); finally C.Free; end; end;

class function TPlataformaContatoColetaService.Iniciar(const AId:Int64; const ATotalAlvos:Integer):TJSONObject;
var C:TUniConnection; J:TJSONObject;
begin
  if AId<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  C:=NovaConexao; try
    J:=TPlataformaContatoColetaDAO.Buscar(C,AId); if J=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    try if not SameText(JStr(J,'situacao'),'PENDENTE') then TAppErrors.RaiseBadRequest('A coleta não está pendente.'); finally J.Free; end;
    TPlataformaContatoColetaDAO.MarcarProcessando(C,AId,ATotalAlvos);
    Result:=TPlataformaContatoColetaDAO.Buscar(C,AId);
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.ReceberResultados(const AId:Int64; const AItens:TJSONArray; const AProgresso:TJSONObject):TJSONObject;
var C:TUniConnection; I,Inseridos:Integer; V:TJSONValue; O,J:TJSONObject;
begin
  if AId<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  if AItens=nil then TAppErrors.RaiseBadRequest('Itens não informados.');
  C:=NovaConexao; try
    J:=TPlataformaContatoColetaDAO.Buscar(C,AId); if J=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.');
    try if not SameText(JStr(J,'situacao'),'PROCESSANDO') then TAppErrors.RaiseBadRequest('A coleta não está em processamento.'); finally J.Free; end;
    Inseridos:=0; C.StartTransaction;
    try
      for I:=0 to AItens.Count-1 do begin V:=AItens.Items[I]; if not (V is TJSONObject) then Continue; O:=V as TJSONObject;
        if Trim(JStr(O,'nome_orgao')).IsEmpty or Trim(JStr(O,'cidade')).IsEmpty or Trim(JStr(O,'uf')).IsEmpty or Trim(JStr(O,'classificacao')).IsEmpty then Continue;
        if TPlataformaContatoColetaDAO.InserirItem(C,AId,JStr(O,'nome_orgao'),JStr(O,'cidade'),JStr(O,'uf'),JStr(O,'email'),JStr(O,'site'),JStr(O,'pagina_origem'),JStr(O,'classificacao'),JStr(O,'observacao'),JStr(O,'data_coleta')) then Inc(Inseridos);
      end;
      if AProgresso<>nil then TPlataformaContatoColetaDAO.AtualizarProgresso(C,AId,JInt(AProgresso,'total_processados'),JInt(AProgresso,'total_emails'),JInt(AProgresso,'total_institucionais'),JInt(AProgresso,'total_revisar'),JInt(AProgresso,'total_sem_email'));
      C.Commit;
    except if C.InTransaction then C.Rollback; raise; end;
    Result:=TJSONObject.Create; Result.AddPair('inseridos',TJSONNumber.Create(Inseridos));
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.Finalizar(const AId:Int64; const AResumo:TJSONObject):TJSONObject;
var C:TUniConnection;
begin
  if (AId<=0) or (AResumo=nil) then TAppErrors.RaiseBadRequest('Resumo da coleta inválido.');
  C:=NovaConexao; try TPlataformaContatoColetaDAO.Finalizar(C,AId,JInt(AResumo,'total_alvos'),JInt(AResumo,'total_processados'),JInt(AResumo,'total_emails'),JInt(AResumo,'total_institucionais'),JInt(AResumo,'total_revisar'),JInt(AResumo,'total_sem_email')); Result:=TPlataformaContatoColetaDAO.Buscar(C,AId); if Result=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.'); finally C.Free; end;
end;

class function TPlataformaContatoColetaService.MarcarErro(const AId:Int64; const AMensagem:string):TJSONObject;
var C:TUniConnection;
begin if AId<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.'); C:=NovaConexao; try TPlataformaContatoColetaDAO.MarcarErro(C,AId,AMensagem); Result:=TPlataformaContatoColetaDAO.Buscar(C,AId); if Result=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.'); finally C.Free; end; end;

class function TPlataformaContatoColetaService.Cancelar(const AIdUsuario,AId:Int64):TJSONObject;
var C:TUniConnection; J:TJSONObject;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  C:=NovaConexao; try
    J:=TPlataformaContatoColetaDAO.Buscar(C,AId); if J=nil then TAppErrors.RaiseNotFound('Coleta não encontrada.'); J.Free;
    C.StartTransaction; try TPlataformaContatoColetaDAO.Cancelar(C,AId); TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'COLETA_CANCELADA','plataforma_contato_coleta',AId.ToString,'Coleta de contatos cancelada.','',''); C.Commit; except if C.InTransaction then C.Rollback; raise; end;
    Result:=TPlataformaContatoColetaDAO.Buscar(C,AId);
  finally C.Free; end;
end;

class function TPlataformaContatoColetaService.RevisarItem(const AIdUsuario,AIdColeta,AIdItem:Int64; const ASituacao:string):TJSONObject;
var C:TUniConnection; Sit:string;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  Sit:=UpperCase(Trim(ASituacao)); if not MatchText(Sit,['APROVADO','DESCARTADO']) then TAppErrors.RaiseBadRequest('Situação de revisão inválida.');
  C:=NovaConexao; try TPlataformaContatoColetaDAO.AlterarSituacaoItem(C,AIdColeta,AIdItem,Sit); Result:=TJSONObject.Create; Result.AddPair('id',TJSONNumber.Create(AIdItem)); Result.AddPair('situacao_revisao',Sit); finally C.Free; end;
end;

class function TPlataformaContatoColetaService.ImportarAprovados(const AIdUsuario,AIdColeta,AIdLista:Int64):TJSONObject;
var C:TUniConnection;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  if AIdColeta<=0 then TAppErrors.RaiseBadRequest('Coleta inválida.');
  C:=NovaConexao; try
    if (AIdLista>0) and not TPlataformaContatoDAO.ListaExiste(C,AIdLista) then TAppErrors.RaiseBadRequest('Lista de contatos não encontrada.');
    C.StartTransaction;
    try Result:=TPlataformaContatoColetaDAO.ImportarAprovados(C,AIdColeta,AIdLista,AIdUsuario); TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'COLETA_IMPORTADA','plataforma_contato_coleta',AIdColeta.ToString,'Contatos aprovados da coleta importados para a base.','',''); C.Commit;
    except if C.InTransaction then C.Rollback; raise; end;
  finally C.Free; end;
end;

end.
