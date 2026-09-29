unit PlataformaCampanha.Service;

interface

uses
  System.JSON,
  System.Classes;

type
  TPlataformaCampanhaService = class
  private
    class function NovaConexao: TObject; static;
    class function EmailValido(const AEmail: string): Boolean; static;
    class function NormalizarWhatsApp(const AValor: string): string; static;
    class function CanalValido(const ACanal: string): Boolean; static;
    class procedure ExigirRascunho(const AConn: TObject; const AIdCampanha: Int64); static;
    class function AplicarVariaveis(const ATexto, ANome, AEmpresa: string): string; static;
    class function TipoMime(const ANome: string): string; static;
    class function NomeSeguro(const AValor: string): string; static;
  public
    class function Listar(const ABusca, ASituacao, ACanal: string;
      const APagina, APorPagina: Integer): TJSONObject; static;
    class function Buscar(const AId: Int64): TJSONObject; static;
    class function Salvar(const AIdUsuario, AId: Int64;
      const ANome, ACanal, AAssuntoEmail, ACorpoEmail, AMensagemWhatsApp, AIP, AUserAgent: string): TJSONObject; static;
    class function AdicionarDestinatario(const AIdCampanha: Int64;
      const ANome, AEmail, AWhatsApp, AEmpresa, AOrigem: string): TJSONObject; static;
    class function ImportarCSV(const AIdCampanha: Int64; const AStream: TStream): TJSONObject; static;
    class procedure ExcluirDestinatario(const AIdCampanha, AIdDestinatario: Int64); static;
    class function SalvarAnexo(const AIdCampanha: Int64; const ANomeOriginal: string;
      const AStream: TStream): TJSONObject; static;
    class procedure ExcluirAnexo(const AIdCampanha, AIdAnexo: Int64); static;
    class function Iniciar(const AIdUsuario, AIdCampanha: Int64; const AIP,AUserAgent:string): TJSONObject; static;
    class function Cancelar(const AIdUsuario, AIdCampanha: Int64; const AIP,AUserAgent:string): TJSONObject; static;
    class function ReprocessarFalhas(const AIdUsuario, AIdCampanha: Int64; const AIP,AUserAgent:string): TJSONObject; static;
    class function ListarBloqueios: TJSONArray; static;
    class procedure AdicionarBloqueio(const AIdUsuario:Int64; const ACanal,AValor,AMotivo:string); static;
    class procedure ExcluirBloqueio(const AId:Int64); static;
    class procedure EnviarEmailTeste(const ADestinatario,AAssunto,AHtml:string); static;
    class procedure EnviarWhatsAppTeste(const ANumero,AMensagem:string); static;
    class procedure ProcessarProximo; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.IOUtils,
  System.Generics.Collections,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaCampanha.DAO,
  PlataformaEmailEnvio.Service,
  PlataformaWhatsApp.Service,
  EvolutionApi.Service;

class function TPlataformaCampanhaService.NovaConexao: TObject;
var C:TAppApiConfig;
begin
 C:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
 Result:=TDatabaseConnection.NewConnection(C.Database);
end;

class function TPlataformaCampanhaService.EmailValido(const AEmail:string):Boolean;
var E:string; P:Integer;
begin E:=LowerCase(Trim(AEmail)); P:=Pos('@',E);
 Result:=(P>1) and (P<Length(E)-2) and (Pos('.',Copy(E,P+2,MaxInt))>0); end;

class function TPlataformaCampanhaService.NormalizarWhatsApp(const AValor:string):string;
var C:Char;
begin Result:=''; for C in AValor do if CharInSet(C,['0'..'9']) then Result:=Result+C;
 if (Length(Result)=10) or (Length(Result)=11) then Result:='55'+Result;
end;

class function TPlataformaCampanhaService.CanalValido(const ACanal:string):Boolean;
begin Result:=MatchText(UpperCase(Trim(ACanal)),['EMAIL','WHATSAPP','AMBOS']); end;

class procedure TPlataformaCampanhaService.ExigirRascunho(const AConn:TObject; const AIdCampanha:Int64);
begin
 if not SameText(TPlataformaCampanhaDAO.BuscarSituacao(TUniConnection(AConn),AIdCampanha),'RASCUNHO') then
  TAppErrors.RaiseBadRequest('A campanha só pode ser alterada enquanto estiver em rascunho.');
end;

class function TPlataformaCampanhaService.AplicarVariaveis(const ATexto,ANome,AEmpresa:string):string;
begin
 Result:=StringReplace(ATexto,'{{nome}}',ANome,[rfReplaceAll,rfIgnoreCase]);
 Result:=StringReplace(Result,'{{empresa}}',AEmpresa,[rfReplaceAll,rfIgnoreCase]);
end;

class function TPlataformaCampanhaService.TipoMime(const ANome:string):string;
var E:string;
begin E:=LowerCase(ExtractFileExt(ANome));
 if E='.pdf' then Result:='application/pdf'
 else if MatchText(E,['.jpg','.jpeg']) then Result:='image/jpeg'
 else if E='.png' then Result:='image/png'
 else if E='.doc' then Result:='application/msword'
 else if E='.docx' then Result:='application/vnd.openxmlformats-officedocument.wordprocessingml.document'
 else if E='.xls' then Result:='application/vnd.ms-excel'
 else if E='.xlsx' then Result:='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
 else TAppErrors.RaiseBadRequest('Formato de anexo não permitido.');
end;

class function TPlataformaCampanhaService.NomeSeguro(const AValor:string):string;
var C:Char;
begin Result:=''; for C in AValor do
 if CharInSet(C,['A'..'Z','a'..'z','0'..'9','-','_','.']) then Result:=Result+C else Result:=Result+'_';
 if Result.IsEmpty then Result:='arquivo';
end;

class function TPlataformaCampanhaService.Listar(const ABusca,ASituacao,ACanal:string; const APagina,APorPagina:Integer):TJSONObject;
var C:TUniConnection;
begin C:=TUniConnection(NovaConexao); try Result:=TPlataformaCampanhaDAO.Listar(C,ABusca,ASituacao,ACanal,APagina,APorPagina); finally C.Free; end; end;

class function TPlataformaCampanhaService.Buscar(const AId:Int64):TJSONObject;
var C:TUniConnection;
begin if AId<=0 then TAppErrors.RaiseBadRequest('Campanha inválida.');
 C:=TUniConnection(NovaConexao); try Result:=TPlataformaCampanhaDAO.Buscar(C,AId); if Result=nil then TAppErrors.RaiseNotFound('Campanha não encontrada.'); finally C.Free; end; end;

class function TPlataformaCampanhaService.Salvar(const AIdUsuario,AId:Int64;
 const ANome,ACanal,AAssuntoEmail,ACorpoEmail,AMensagemWhatsApp,AIP,AUserAgent:string):TJSONObject;
var C:TUniConnection; Id:Int64; Canal:string;
begin
 if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
 if Trim(ANome).IsEmpty or (Length(Trim(ANome))>180) then TAppErrors.RaiseBadRequest('Informe um nome de campanha válido.');
 Canal:=UpperCase(Trim(ACanal)); if not CanalValido(Canal) then TAppErrors.RaiseBadRequest('Canal inválido.');
 if (Canal<>'WHATSAPP') and Trim(AAssuntoEmail).IsEmpty then TAppErrors.RaiseBadRequest('Informe o assunto do e-mail.');
 if (Canal<>'WHATSAPP') and Trim(ACorpoEmail).IsEmpty then TAppErrors.RaiseBadRequest('Informe o conteúdo do e-mail.');
 if (Canal<>'EMAIL') and Trim(AMensagemWhatsApp).IsEmpty then TAppErrors.RaiseBadRequest('Informe a mensagem do WhatsApp.');
 C:=TUniConnection(NovaConexao);
 try
  C.StartTransaction;
  try
   Id:=AId;
   if Id<=0 then begin
    Id:=TPlataformaCampanhaDAO.Inserir(C,AIdUsuario,Trim(ANome),Canal,Trim(AAssuntoEmail),ACorpoEmail,AMensagemWhatsApp);
    TPlataformaCampanhaDAO.RegistrarAuditoria(C,AIdUsuario,'CAMPANHA_CRIADA',Id,'Campanha criada.',AIP,AUserAgent);
   end else begin
    ExigirRascunho(C,Id);
    TPlataformaCampanhaDAO.Atualizar(C,Id,Trim(ANome),Canal,Trim(AAssuntoEmail),ACorpoEmail,AMensagemWhatsApp);
    TPlataformaCampanhaDAO.RegistrarAuditoria(C,AIdUsuario,'CAMPANHA_ALTERADA',Id,'Campanha alterada.',AIP,AUserAgent);
   end;
   TPlataformaCampanhaDAO.AtualizarTotaisCampanha(C,Id); C.Commit;
  except if C.InTransaction then C.Rollback; raise; end;
  Result:=TPlataformaCampanhaDAO.Buscar(C,Id);
 finally C.Free; end;
end;

class function TPlataformaCampanhaService.AdicionarDestinatario(const AIdCampanha:Int64;
 const ANome,AEmail,AWhatsApp,AEmpresa,AOrigem:string):TJSONObject;
var C:TUniConnection; Email,Whats:string; Id:Int64;
begin
 Email:=LowerCase(Trim(AEmail)); Whats:=NormalizarWhatsApp(AWhatsApp);
 if Trim(ANome).IsEmpty then TAppErrors.RaiseBadRequest('Informe o nome do destinatário.');
 if (not Email.IsEmpty) and not EmailValido(Email) then TAppErrors.RaiseBadRequest('E-mail do destinatário inválido.');
 if (not Whats.IsEmpty) and ((Length(Whats)<12) or (Length(Whats)>13)) then TAppErrors.RaiseBadRequest('WhatsApp do destinatário inválido.');
 if Email.IsEmpty and Whats.IsEmpty then TAppErrors.RaiseBadRequest('Informe e-mail ou WhatsApp.');
 C:=TUniConnection(NovaConexao);
 try ExigirRascunho(C,AIdCampanha);
  if TPlataformaCampanhaDAO.DestinatarioDuplicado(C,AIdCampanha,Email,Whats) then TAppErrors.RaiseBadRequest('Destinatário já adicionado à campanha.');
  Id:=TPlataformaCampanhaDAO.AdicionarDestinatario(C,AIdCampanha,Trim(ANome),Email,Whats,Trim(AEmpresa),UpperCase(Trim(AOrigem)));
  TPlataformaCampanhaDAO.AtualizarTotaisCampanha(C,AIdCampanha);
  Result:=TJSONObject.Create; Result.AddPair('id',TJSONNumber.Create(Id));
 finally C.Free; end;
end;

class function SplitCsv(const S:string; Delim:Char):TArray<string>;
var L:TList<string>; I:Integer; C:Char; Buf:string; Quote:Boolean;
begin
 L:=TList<string>.Create; try Buf:=''; Quote:=False; I:=1;
 while I<=Length(S) do begin C:=S[I];
  if C='"' then begin if Quote and (I<Length(S)) and (S[I+1]='"') then begin Buf:=Buf+'"'; Inc(I); end else Quote:=not Quote; end
  else if (C=Delim) and not Quote then begin L.Add(Trim(Buf)); Buf:=''; end else Buf:=Buf+C;
  Inc(I);
 end; L.Add(Trim(Buf)); Result:=L.ToArray; finally L.Free; end;
end;

class function TPlataformaCampanhaService.ImportarCSV(const AIdCampanha:Int64; const AStream:TStream):TJSONObject;
var C:TUniConnection; SL:TStringList; Headers,Vals:TArray<string>; Delim:Char; I,J:Integer;
 Nome,Email,Whats,Empresa:string; IdxNome,IdxEmail,IdxWhats,IdxEmpresa:Integer; Total,Inseridos,Duplicados,Invalidos,Bloqueados:Integer;
 function Idx(const N:string):Integer; var K:Integer; begin Result:=-1; for K:=0 to High(Headers) do if SameText(Trim(Headers[K]),N) then Exit(K); end;
 function Val(AIdx:Integer):string; begin if (AIdx>=0) and (AIdx<=High(Vals)) then Result:=Vals[AIdx] else Result:=''; end;
begin
 if (AStream=nil) or (AStream.Size<=0) then TAppErrors.RaiseBadRequest('Arquivo CSV não informado.');
 if AStream.Size>2*1024*1024 then TAppErrors.RaiseBadRequest('O CSV deve possuir no máximo 2 MB.');
 SL:=TStringList.Create; C:=TUniConnection(NovaConexao);
 try
  ExigirRascunho(C,AIdCampanha); AStream.Position:=0; SL.LoadFromStream(AStream,TEncoding.UTF8);
  if SL.Count<2 then TAppErrors.RaiseBadRequest('CSV sem registros.');
  Delim:=','; if SL[0].CountChar(';')>SL[0].CountChar(',') then Delim:=';';
  Headers:=SplitCsv(SL[0],Delim); IdxNome:=Idx('nome'); IdxEmail:=Idx('email'); IdxWhats:=Idx('whatsapp'); IdxEmpresa:=Idx('empresa');
  if IdxNome<0 then TAppErrors.RaiseBadRequest('CSV deve conter a coluna nome.');
  if (IdxEmail<0) and (IdxWhats<0) then TAppErrors.RaiseBadRequest('CSV deve conter email ou whatsapp.');
  Total:=0; Inseridos:=0; Duplicados:=0; Invalidos:=0; Bloqueados:=0;
  for I:=1 to SL.Count-1 do begin
   if Trim(SL[I]).IsEmpty then Continue; Inc(Total); Vals:=SplitCsv(SL[I],Delim);
   Nome:=Trim(Val(IdxNome)); Email:=LowerCase(Trim(Val(IdxEmail))); Whats:=NormalizarWhatsApp(Val(IdxWhats)); Empresa:=Trim(Val(IdxEmpresa));
   if Nome.IsEmpty or ((not Email.IsEmpty) and not EmailValido(Email)) or
      ((not Whats.IsEmpty) and ((Length(Whats)<12) or (Length(Whats)>13))) or (Email.IsEmpty and Whats.IsEmpty) then begin Inc(Invalidos); Continue; end;
   if TPlataformaCampanhaDAO.DestinatarioDuplicado(C,AIdCampanha,Email,Whats) then begin Inc(Duplicados); Continue; end;
   if ((not Email.IsEmpty) and TPlataformaCampanhaDAO.EstaBloqueado(C,'EMAIL',Email)) and
      ((Whats.IsEmpty) or TPlataformaCampanhaDAO.EstaBloqueado(C,'WHATSAPP',Whats)) then begin Inc(Bloqueados); Continue; end;
   TPlataformaCampanhaDAO.AdicionarDestinatario(C,AIdCampanha,Nome,Email,Whats,Empresa,'CSV'); Inc(Inseridos);
  end;
  TPlataformaCampanhaDAO.AtualizarTotaisCampanha(C,AIdCampanha);
  Result:=TJSONObject.Create; Result.AddPair('total_linhas',TJSONNumber.Create(Total)); Result.AddPair('inseridos',TJSONNumber.Create(Inseridos));
  Result.AddPair('duplicados',TJSONNumber.Create(Duplicados)); Result.AddPair('invalidos',TJSONNumber.Create(Invalidos)); Result.AddPair('bloqueados',TJSONNumber.Create(Bloqueados));
 finally C.Free; SL.Free; end;
end;

class procedure TPlataformaCampanhaService.ExcluirDestinatario(const AIdCampanha,AIdDestinatario:Int64);
var C:TUniConnection; begin C:=TUniConnection(NovaConexao); try ExigirRascunho(C,AIdCampanha); TPlataformaCampanhaDAO.ExcluirDestinatario(C,AIdCampanha,AIdDestinatario); TPlataformaCampanhaDAO.AtualizarTotaisCampanha(C,AIdCampanha); finally C.Free; end; end;

class function TPlataformaCampanhaService.SalvarAnexo(const AIdCampanha:Int64; const ANomeOriginal:string; const AStream:TStream):TJSONObject;
var C:TUniConnection; Mime,Dir,Storage,Caminho:string; G:TGUID; F:TFileStream; Id:Int64;
begin
 if (AStream=nil) or (AStream.Size<=0) then TAppErrors.RaiseBadRequest('Anexo não informado.');
 if AStream.Size>10*1024*1024 then TAppErrors.RaiseBadRequest('Cada anexo deve possuir no máximo 10 MB.');
 Mime:=TipoMime(ANomeOriginal);
 C:=TUniConnection(NovaConexao);
 try ExigirRascunho(C,AIdCampanha); if TPlataformaCampanhaDAO.ContarAnexos(C,AIdCampanha)>=5 then TAppErrors.RaiseBadRequest('A campanha aceita no máximo 5 anexos.');
  CreateGUID(G); Storage:=LowerCase(StringReplace(StringReplace(GUIDToString(G),'{','',[rfReplaceAll]),'}','',[rfReplaceAll]))+LowerCase(ExtractFileExt(ANomeOriginal));
  Dir:=TPath.Combine(TPath.Combine(TPath.Combine(ExtractFilePath(ParamStr(0)),'uploads'),'campanhas'),AIdCampanha.ToString); ForceDirectories(Dir);
  Caminho:=TPath.Combine(Dir,Storage); AStream.Position:=0; F:=TFileStream.Create(Caminho,fmCreate); try F.CopyFrom(AStream,0); finally F.Free; end;
  try Id:=TPlataformaCampanhaDAO.AdicionarAnexo(C,AIdCampanha,Copy(NomeSeguro(ANomeOriginal),1,255),Storage,Caminho,Mime,AStream.Size);
  except if TFile.Exists(Caminho) then TFile.Delete(Caminho); raise; end;
  Result:=TJSONObject.Create; Result.AddPair('id',TJSONNumber.Create(Id)); Result.AddPair('nome_original',ANomeOriginal); Result.AddPair('mime_type',Mime); Result.AddPair('tamanho_bytes',TJSONNumber.Create(AStream.Size));
 finally C.Free; end;
end;

class procedure TPlataformaCampanhaService.ExcluirAnexo(const AIdCampanha,AIdAnexo:Int64);
var C:TUniConnection; Caminho:string;
begin C:=TUniConnection(NovaConexao); try ExigirRascunho(C,AIdCampanha); Caminho:=TPlataformaCampanhaDAO.BuscarCaminhoAnexo(C,AIdCampanha,AIdAnexo); TPlataformaCampanhaDAO.ExcluirAnexo(C,AIdCampanha,AIdAnexo); if (not Caminho.IsEmpty) and TFile.Exists(Caminho) then TFile.Delete(Caminho); finally C.Free; end; end;

class function TPlataformaCampanhaService.Iniciar(const AIdUsuario,AIdCampanha:Int64; const AIP,AUserAgent:string):TJSONObject;
var C:TUniConnection; Camp:TJSONObject; Canal:string;
begin
 C:=TUniConnection(NovaConexao); Camp:=nil;
 try ExigirRascunho(C,AIdCampanha); Camp:=TPlataformaCampanhaDAO.Buscar(C,AIdCampanha); if Camp=nil then TAppErrors.RaiseNotFound('Campanha não encontrada.');
  if Camp.GetValue<Integer>('total_destinatarios',0)<=0 then TAppErrors.RaiseBadRequest('Adicione ao menos um destinatário.');
  Canal:=Camp.GetValue<string>('canal','');
  if (Canal<>'WHATSAPP') and (not TPlataformaEmailEnvioService.Configurado) then TAppErrors.RaiseBadRequest('Configure o e-mail global antes de iniciar a campanha.');
  if Canal<>'EMAIL' then begin var U,K,N:string; if not TPlataformaWhatsAppService.ObterCredenciais(U,K,N) then TAppErrors.RaiseBadRequest('Configure e conecte o WhatsApp global antes de iniciar a campanha.'); end;
  C.StartTransaction; try TPlataformaCampanhaDAO.Iniciar(C,AIdCampanha); TPlataformaCampanhaDAO.RegistrarAuditoria(C,AIdUsuario,'CAMPANHA_INICIADA',AIdCampanha,'Campanha iniciada.',AIP,AUserAgent); C.Commit; except if C.InTransaction then C.Rollback; raise; end;
  Camp.Free; Camp:=TPlataformaCampanhaDAO.Buscar(C,AIdCampanha); Result:=Camp; Camp:=nil;
 finally Camp.Free; C.Free; end;
end;

class function TPlataformaCampanhaService.Cancelar(const AIdUsuario,AIdCampanha:Int64; const AIP,AUserAgent:string):TJSONObject;
var C:TUniConnection;
begin C:=TUniConnection(NovaConexao); try C.StartTransaction; try TPlataformaCampanhaDAO.Cancelar(C,AIdCampanha); TPlataformaCampanhaDAO.RegistrarAuditoria(C,AIdUsuario,'CAMPANHA_CANCELADA',AIdCampanha,'Campanha cancelada.',AIP,AUserAgent); C.Commit; except if C.InTransaction then C.Rollback; raise; end; Result:=TPlataformaCampanhaDAO.Buscar(C,AIdCampanha); finally C.Free; end; end;

class function TPlataformaCampanhaService.ReprocessarFalhas(const AIdUsuario,AIdCampanha:Int64; const AIP,AUserAgent:string):TJSONObject;
var C:TUniConnection;
begin C:=TUniConnection(NovaConexao); try C.StartTransaction; try TPlataformaCampanhaDAO.ReprocessarFalhas(C,AIdCampanha); TPlataformaCampanhaDAO.RegistrarAuditoria(C,AIdUsuario,'CAMPANHA_FALHAS_REPROCESSADAS',AIdCampanha,'Falhas reenfileiradas.',AIP,AUserAgent); C.Commit; except if C.InTransaction then C.Rollback; raise; end; Result:=TPlataformaCampanhaDAO.Buscar(C,AIdCampanha); finally C.Free; end; end;

class function TPlataformaCampanhaService.ListarBloqueios:TJSONArray;
var C:TUniConnection; begin C:=TUniConnection(NovaConexao); try Result:=TPlataformaCampanhaDAO.ListarBloqueios(C); finally C.Free; end; end;

class procedure TPlataformaCampanhaService.AdicionarBloqueio(const AIdUsuario:Int64; const ACanal,AValor,AMotivo:string);
var C:TUniConnection; Canal,Norm:string;
begin Canal:=UpperCase(Trim(ACanal)); if not MatchText(Canal,['EMAIL','WHATSAPP']) then TAppErrors.RaiseBadRequest('Canal inválido.');
 if Canal='EMAIL' then begin Norm:=LowerCase(Trim(AValor)); if not EmailValido(Norm) then TAppErrors.RaiseBadRequest('E-mail inválido.'); end
 else begin Norm:=NormalizarWhatsApp(AValor); if (Length(Norm)<12) or (Length(Norm)>13) then TAppErrors.RaiseBadRequest('WhatsApp inválido.'); end;
 C:=TUniConnection(NovaConexao); try TPlataformaCampanhaDAO.AdicionarBloqueio(C,AIdUsuario,Canal,Trim(AValor),Norm,Trim(AMotivo)); finally C.Free; end;
end;

class procedure TPlataformaCampanhaService.ExcluirBloqueio(const AId:Int64);
var C:TUniConnection; begin C:=TUniConnection(NovaConexao); try TPlataformaCampanhaDAO.ExcluirBloqueio(C,AId); finally C.Free; end; end;

class procedure TPlataformaCampanhaService.EnviarEmailTeste(const ADestinatario,AAssunto,AHtml:string);
begin if not EmailValido(ADestinatario) then TAppErrors.RaiseBadRequest('E-mail de teste inválido.'); TPlataformaEmailEnvioService.Enviar(ADestinatario,AAssunto,AHtml); end;

class procedure TPlataformaCampanhaService.EnviarWhatsAppTeste(const ANumero,AMensagem:string);
var U,K,N:string; J:TJSONValue; Num:string;
begin Num:=NormalizarWhatsApp(ANumero); if (Length(Num)<12) or (Length(Num)>13) then TAppErrors.RaiseBadRequest('WhatsApp de teste inválido.');
 if not TPlataformaWhatsAppService.ObterCredenciais(U,K,N) then TAppErrors.RaiseBadRequest('Configuração global do WhatsApp indisponível.');
 J:=TEvolutionApiService.EnviarTexto(U,K,N,Num,AMensagem); J.Free;
end;

class procedure TPlataformaCampanhaService.ProcessarProximo;
var C:TUniConnection; E:TJSONObject; IdEnvio,IdCampanha:Int64; Canal,Dest,Nome,Empresa,Assunto,Corpo,Msg,U,K,N,Provider:string; Anexos:TJSONArray; I:Integer; J:TJSONValue;
begin
 C:=TUniConnection(NovaConexao); E:=nil; Anexos:=nil;
 try
  E:=TPlataformaCampanhaDAO.ProximoEnvio(C); if E=nil then Exit;
  IdEnvio:=E.GetValue<Int64>('id',0); IdCampanha:=E.GetValue<Int64>('id_campanha',0);
  TPlataformaCampanhaDAO.MarcarProcessando(C,IdEnvio);
  try
   Canal:=E.GetValue<string>('canal',''); Dest:=E.GetValue<string>('destinatario',''); Nome:=E.GetValue<string>('nome',''); Empresa:=E.GetValue<string>('empresa','');
   if Canal='EMAIL' then begin
    Assunto:=AplicarVariaveis(E.GetValue<string>('assunto_email',''),Nome,Empresa);
    Corpo:=AplicarVariaveis(E.GetValue<string>('corpo_email',''),Nome,Empresa);
    Anexos:=TPlataformaCampanhaDAO.BuscarAnexos(C,IdCampanha);
    TPlataformaEmailEnvioService.EnviarComAnexos(Dest,Assunto,Corpo,Anexos);
   end else begin
    Msg:=AplicarVariaveis(E.GetValue<string>('mensagem_whatsapp',''),Nome,Empresa);
    if not TPlataformaWhatsAppService.ObterCredenciais(U,K,N) then raise Exception.Create('Configuração global do WhatsApp indisponível.');
    J:=TEvolutionApiService.EnviarTexto(U,K,N,Dest,Msg); try Provider:=''; if J<>nil then Provider:=J.GetValue<string>('key.id',''); finally J.Free; end;
    Anexos:=TPlataformaCampanhaDAO.BuscarAnexos(C,IdCampanha);
    for I:=0 to Anexos.Count-1 do begin
      J:=TEvolutionApiService.EnviarMidia(U,K,N,Dest,
        (Anexos.Items[I] as TJSONObject).GetValue<string>('caminho_storage',''),
        (Anexos.Items[I] as TJSONObject).GetValue<string>('nome_original',''),
        (Anexos.Items[I] as TJSONObject).GetValue<string>('mime_type',''),
        '');
      J.Free;
    end;
   end;
   TPlataformaCampanhaDAO.MarcarEnviado(C,IdEnvio,Provider);
  except on Ex:Exception do TPlataformaCampanhaDAO.MarcarFalha(C,IdEnvio,Ex.Message); end;
  TPlataformaCampanhaDAO.AtualizarTotaisCampanha(C,IdCampanha);
 finally Anexos.Free; E.Free; C.Free; end;
end;

end.
