unit PlataformaCampanhaPublico.Service;

interface

uses
  System.JSON;

type
  TPlataformaCampanhaPublicoService = class
  private
    class function NovaConexao: TObject; static;
    class procedure ValidarTipo(const ATipo:string); static;
    class procedure ValidarFlag(const ANome:string; var AValor:Integer); static;
  public
    class function Listar(
      const AIdCampanha:Int64;
      const ATipo,ABusca,AUF,AMunicipio,APartido:string;
      AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp:Integer;
      const APagina,APorPagina:Integer
    ):TJSONObject; static;

    class function AdicionarTodos(
      const AIdUsuario,AIdCampanha:Int64;
      const ATipo,ABusca,AUF,AMunicipio,APartido:string;
      AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp:Integer;
      const AIP,AUserAgent:string
    ):TJSONObject; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaCampanhaPublico.DAO,
  PlataformaCampanha.DAO,
  PlataformaContato.DAO;

class function TPlataformaCampanhaPublicoService.NovaConexao:TObject;
var C:TAppApiConfig;
begin
  C:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Result:=TDatabaseConnection.NewConnection(C.Database);
end;

class procedure TPlataformaCampanhaPublicoService.ValidarTipo(const ATipo:string);
var Tipo:string;
begin
  Tipo:=UpperCase(Trim(ATipo));
  if Tipo.IsEmpty then Exit;
  if not MatchText(Tipo,['CAMARA','PREFEITURA','SINDICATO','ASSOCIACAO','VEREADOR','DEPUTADO_ESTADUAL','DEPUTADO_FEDERAL','SENADOR','UNALE_ASSOCIADO']) then
    TAppErrors.RaiseBadRequest('Tipo de público inválido.');
end;

class procedure TPlataformaCampanhaPublicoService.ValidarFlag(const ANome:string; var AValor:Integer);
begin
  if (AValor<>-1) and (AValor<>0) and (AValor<>1) then
    TAppErrors.RaiseBadRequest('Filtro inválido: '+ANome+'.');
end;

class function TPlataformaCampanhaPublicoService.Listar(
  const AIdCampanha:Int64;
  const ATipo,ABusca,AUF,AMunicipio,APartido:string;
  AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp:Integer;
  const APagina,APorPagina:Integer):TJSONObject;
var C:TUniConnection; Situacao,Canal:string;
begin
  if AIdCampanha<=0 then TAppErrors.RaiseBadRequest('Campanha inválida.');
  ValidarTipo(ATipo); ValidarFlag('em_exercicio',AEmExercicio); ValidarFlag('unale_associado',AUnaleAssociado); ValidarFlag('tem_email',ATemEmail); ValidarFlag('tem_whatsapp',ATemWhatsApp);
  if (not Trim(AUF).IsEmpty) and (Length(Trim(AUF))<>2) then TAppErrors.RaiseBadRequest('UF inválida.');

  C:=TUniConnection(NovaConexao);
  try
    if not TPlataformaCampanhaPublicoDAO.ObterCampanhaContexto(C,AIdCampanha,Situacao,Canal) then TAppErrors.RaiseNotFound('Campanha não encontrada.');
    if not SameText(Situacao,'RASCUNHO') then TAppErrors.RaiseBadRequest('O público só pode ser alterado enquanto a campanha estiver em rascunho.');
    Result:=TPlataformaCampanhaPublicoDAO.Listar(C,AIdCampanha,Canal,UpperCase(Trim(ATipo)),Trim(ABusca),UpperCase(Trim(AUF)),Trim(AMunicipio),UpperCase(Trim(APartido)),AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp,APagina,APorPagina);
  finally C.Free; end;
end;

class function TPlataformaCampanhaPublicoService.AdicionarTodos(
  const AIdUsuario,AIdCampanha:Int64;
  const ATipo,ABusca,AUF,AMunicipio,APartido:string;
  AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp:Integer;
  const AIP,AUserAgent:string):TJSONObject;
var C:TUniConnection; Situacao,Canal:string; Inseridos:Integer;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  if AIdCampanha<=0 then TAppErrors.RaiseBadRequest('Campanha inválida.');
  ValidarTipo(ATipo); ValidarFlag('em_exercicio',AEmExercicio); ValidarFlag('unale_associado',AUnaleAssociado); ValidarFlag('tem_email',ATemEmail); ValidarFlag('tem_whatsapp',ATemWhatsApp);
  if (not Trim(AUF).IsEmpty) and (Length(Trim(AUF))<>2) then TAppErrors.RaiseBadRequest('UF inválida.');

  C:=TUniConnection(NovaConexao);
  try
    if not TPlataformaCampanhaPublicoDAO.ObterCampanhaContexto(C,AIdCampanha,Situacao,Canal) then TAppErrors.RaiseNotFound('Campanha não encontrada.');
    if not SameText(Situacao,'RASCUNHO') then TAppErrors.RaiseBadRequest('O público só pode ser alterado enquanto a campanha estiver em rascunho.');
    C.StartTransaction;
    try
      Inseridos:=TPlataformaCampanhaPublicoDAO.AdicionarPorFiltro(C,AIdCampanha,Canal,UpperCase(Trim(ATipo)),Trim(ABusca),UpperCase(Trim(AUF)),Trim(AMunicipio),UpperCase(Trim(APartido)),AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp);
      TPlataformaCampanhaDAO.AtualizarTotaisCampanha(C,AIdCampanha);
      TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'PUBLICO_CAMPANHA_ADICIONADO','plataforma_campanha',AIdCampanha.ToString,Format('%d contato(s) adicionados à campanha por filtro de público.',[Inseridos]),AIP,AUserAgent);
      C.Commit;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
    Result:=TJSONObject.Create;
    Result.AddPair('inseridos',TJSONNumber.Create(Inseridos));
  finally C.Free; end;
end;

end.
