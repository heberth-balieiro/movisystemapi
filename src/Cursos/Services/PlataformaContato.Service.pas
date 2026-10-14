unit PlataformaContato.Service;

interface

uses
  System.JSON,
  System.Classes,
  Uni;

type
  TPlataformaContatoService = class
  private
    class function NovaConexao: TUniConnection; static;
    class function SomenteDigitos(const AValor: string): string; static;
    class function NormalizarTelefone(const AValor: string): string; static;
    class function EmailValido(const AEmail: string): Boolean; static;
    class function NormalizarEmail(const AEmail: string): string; static;
    class function TipoDocumento(const ADocumento: string): string; static;
    class procedure ValidarDocumento(const ADocumentoNormalizado: string); static;
  public
    class function Listar(
      const ABusca, ACidade, AUF, AOrgao, AGrau, ASituacao: string;
      const AIdLista: Int64;
      const ATemEmail, ATemWhatsApp, APagina, APorPagina: Integer
    ): TJSONObject; static;
    class function Buscar(const AId: Int64): TJSONObject; static;
    class function Salvar(
      const AIdUsuario, AId: Int64;
      const ADocumento, ARazaoSocial, ANomeFantasia, AResponsavel,
            ATelefone, AEmail, AGrau, ACidade, AUF, AOrgao,
            ASite, AObservacao, AFonte, ASituacao, ADataColeta: string;
      const AIP, AUserAgent: string
    ): TJSONObject; static;
    class function ListarListas: TJSONArray; static;
    class function SalvarLista(
      const AIdUsuario, AId: Int64;
      const ANome, ADescricao, ACidade, AUF, AOrgao, AGrau, AFonte,
            AIP, AUserAgent: string
    ): TJSONObject; static;
    class function ValidarCSV(const AStream:TStream; const AIdLista:Int64):TJSONObject; static;
    class function ImportarCSV(
      const AIdUsuario:Int64;
      const AStream:TStream;
      const AIdLista:Int64;
      const AIP,AUserAgent:string
    ):TJSONObject; static;
    class function AdicionarNaCampanha(
      const AIdUsuario,AIdCampanha,AIdLista:Int64;
      const AIds:TJSONArray;
      const AIP,AUserAgent:string
    ):TJSONObject; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  System.DateUtils,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaContato.DAO,
  PlataformaCampanha.DAO;

class function TPlataformaContatoService.NovaConexao:TUniConnection;
var C:TAppApiConfig;
begin
  C:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Result:=TDatabaseConnection.NewConnection(C.Database);
end;

class function TPlataformaContatoService.SomenteDigitos(const AValor:string):string;
var C:Char;
begin Result:=''; for C in AValor do if CharInSet(C,['0'..'9']) then Result:=Result+C; end;

class function TPlataformaContatoService.NormalizarTelefone(const AValor:string):string;
begin
  Result:=SomenteDigitos(AValor);
  if (Length(Result)=10) or (Length(Result)=11) then Result:='55'+Result;
end;

class function TPlataformaContatoService.EmailValido(const AEmail:string):Boolean;
var E:string; P:Integer;
begin
  E:=LowerCase(Trim(AEmail)); if E.IsEmpty then Exit(True); P:=Pos('@',E);
  Result:=(P>1) and (P<Length(E)-2) and (Pos('.',Copy(E,P+2,MaxInt))>0);
end;

class function TPlataformaContatoService.NormalizarEmail(const AEmail:string):string;
begin Result:=LowerCase(Trim(AEmail)); end;

class function TPlataformaContatoService.TipoDocumento(const ADocumento:string):string;
begin
  if ADocumento.IsEmpty then Exit('');
  if Length(ADocumento)=11 then Exit('CPF');
  if Length(ADocumento)=14 then Exit('CNPJ');
  Result:='';
end;

class procedure TPlataformaContatoService.ValidarDocumento(const ADocumentoNormalizado:string);
begin
  if ADocumentoNormalizado.IsEmpty then Exit;
  if not MatchText(IntToStr(Length(ADocumentoNormalizado)),['11','14']) then
    TAppErrors.RaiseBadRequest('CPF/CNPJ deve possuir 11 ou 14 dígitos.');
end;

function ParseDataISO(const S:string; out D:TDateTime):Boolean;
var Y,M,Day:Word;
begin
  Result:=False; D:=0;
  if Trim(S).IsEmpty then Exit;
  if Length(Trim(S))<>10 then Exit;
  Y:=StrToIntDef(Copy(Trim(S),1,4),0); M:=StrToIntDef(Copy(Trim(S),6,2),0); Day:=StrToIntDef(Copy(Trim(S),9,2),0);
  Result:=TryEncodeDate(Y,M,Day,D);
end;

function SplitCsv(const S:string; Delim:Char):TArray<string>;
var L:TList<string>; I:Integer; C:Char; Buf:string; Quote:Boolean;
begin
  L:=TList<string>.Create;
  try
    Buf:=''; Quote:=False; I:=1;
    while I<=Length(S) do begin C:=S[I];
      if C='"' then begin
        if Quote and (I<Length(S)) and (S[I+1]='"') then begin Buf:=Buf+'"'; Inc(I); end
        else Quote:=not Quote;
      end else if (C=Delim) and not Quote then begin L.Add(Trim(Buf)); Buf:=''; end
      else Buf:=Buf+C;
      Inc(I);
    end;
    L.Add(Trim(Buf)); Result:=L.ToArray;
  finally L.Free; end;
end;

class function TPlataformaContatoService.Listar(const ABusca,ACidade,AUF,AOrgao,AGrau,ASituacao:string;
  const AIdLista:Int64; const ATemEmail,ATemWhatsApp,APagina,APorPagina:Integer):TJSONObject;
var C:TUniConnection;
begin
  C:=NovaConexao;
  try Result:=TPlataformaContatoDAO.Listar(C,ABusca,ACidade,AUF,AOrgao,AGrau,ASituacao,AIdLista,ATemEmail,ATemWhatsApp,APagina,APorPagina);
  finally C.Free; end;
end;

class function TPlataformaContatoService.Buscar(const AId:Int64):TJSONObject;
var C:TUniConnection;
begin
  if AId<=0 then TAppErrors.RaiseBadRequest('Contato inválido.');
  C:=NovaConexao;
  try Result:=TPlataformaContatoDAO.Buscar(C,AId); if Result=nil then TAppErrors.RaiseNotFound('Contato não encontrado.');
  finally C.Free; end;
end;

class function TPlataformaContatoService.Salvar(
  const AIdUsuario,AId:Int64;
  const ADocumento,ARazaoSocial,ANomeFantasia,AResponsavel,ATelefone,AEmail,AGrau,ACidade,AUF,AOrgao,ASite,AObservacao,AFonte,ASituacao,ADataColeta:string;
  const AIP,AUserAgent:string):TJSONObject;
var C:TUniConnection; Id,OutroId:Int64; Doc,EmailN,TelN,Tipo,Sit:string; D:TDateTime; TemData:Boolean;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  if Trim(ARazaoSocial).IsEmpty and Trim(ANomeFantasia).IsEmpty and Trim(AResponsavel).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe razão social, nome fantasia ou responsável.');
  Doc:=SomenteDigitos(ADocumento); ValidarDocumento(Doc); Tipo:=TipoDocumento(Doc);
  EmailN:=NormalizarEmail(AEmail); if not EmailValido(EmailN) then TAppErrors.RaiseBadRequest('E-mail inválido.');
  TelN:=NormalizarTelefone(ATelefone); if (not TelN.IsEmpty) and ((Length(TelN)<12) or (Length(TelN)>13)) then TAppErrors.RaiseBadRequest('Telefone inválido.');
  Sit:=UpperCase(Trim(ASituacao)); if Sit.IsEmpty then Sit:='ATIVO'; if not MatchText(Sit,['ATIVO','INATIVO']) then TAppErrors.RaiseBadRequest('Situação inválida.');
  TemData:=ParseDataISO(ADataColeta,D); if (not Trim(ADataColeta).IsEmpty) and not TemData then TAppErrors.RaiseBadRequest('Data da coleta inválida. Use AAAA-MM-DD.');

  C:=NovaConexao;
  try
    if not Doc.IsEmpty then begin OutroId:=TPlataformaContatoDAO.BuscarIdPorDocumento(C,Doc); if (OutroId>0) and (OutroId<>AId) then TAppErrors.RaiseBadRequest('Já existe contato com este CPF/CNPJ.'); end;
    C.StartTransaction;
    try
      Id:=AId;
      if Id<=0 then begin
        Id:=TPlataformaContatoDAO.Inserir(C,AIdUsuario,Tipo,Trim(ADocumento),Doc,Trim(ARazaoSocial),Trim(ANomeFantasia),Trim(AResponsavel),Trim(ATelefone),TelN,Trim(AEmail),EmailN,Trim(AGrau),Trim(ACidade),UpperCase(Trim(AUF)),Trim(AOrgao),Trim(ASite),Trim(AObservacao),Trim(AFonte),D,TemData);
        TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'CONTATO_CRIADO','plataforma_contato',Id.ToString,'Contato criado na base de contatos.',AIP,AUserAgent);
      end else begin
        if TPlataformaContatoDAO.Buscar(C,Id)=nil then TAppErrors.RaiseNotFound('Contato não encontrado.');
        TPlataformaContatoDAO.Atualizar(C,Id,Tipo,Trim(ADocumento),Doc,Trim(ARazaoSocial),Trim(ANomeFantasia),Trim(AResponsavel),Trim(ATelefone),TelN,Trim(AEmail),EmailN,Trim(AGrau),Trim(ACidade),UpperCase(Trim(AUF)),Trim(AOrgao),Trim(ASite),Trim(AObservacao),Trim(AFonte),Sit,D,TemData);
        TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'CONTATO_ALTERADO','plataforma_contato',Id.ToString,'Contato alterado na base de contatos.',AIP,AUserAgent);
      end;
      C.Commit;
    except if C.InTransaction then C.Rollback; raise; end;
    Result:=TPlataformaContatoDAO.Buscar(C,Id);
  finally C.Free; end;
end;

class function TPlataformaContatoService.ListarListas:TJSONArray;
var C:TUniConnection;
begin C:=NovaConexao; try Result:=TPlataformaContatoDAO.ListarListas(C); finally C.Free; end; end;

class function TPlataformaContatoService.SalvarLista(const AIdUsuario,AId:Int64;
  const ANome,ADescricao,ACidade,AUF,AOrgao,AGrau,AFonte,AIP,AUserAgent:string):TJSONObject;
var C:TUniConnection; Id:Int64;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  if Trim(ANome).IsEmpty or (Length(Trim(ANome))>180) then TAppErrors.RaiseBadRequest('Informe um nome de lista válido.');
  C:=NovaConexao;
  try
    C.StartTransaction;
    try
      Id:=TPlataformaContatoDAO.SalvarLista(C,AIdUsuario,AId,Trim(ANome),Trim(ADescricao),Trim(ACidade),UpperCase(Trim(AUF)),Trim(AOrgao),Trim(AGrau),Trim(AFonte));
      if AId<=0 then TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'LISTA_CRIADA','plataforma_contato_lista',Id.ToString,'Lista de contatos criada.',AIP,AUserAgent)
      else TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'LISTA_ALTERADA','plataforma_contato_lista',Id.ToString,'Lista de contatos alterada.',AIP,AUserAgent);
      C.Commit;
    except if C.InTransaction then C.Rollback; raise; end;
    Result:=TJSONObject.Create; Result.AddPair('id',TJSONNumber.Create(Id)); Result.AddPair('nome',Trim(ANome));
  finally C.Free; end;
end;

type
  TCsvContato = record
    Documento,Razao,Fantasia,Responsavel,Telefone,Email,Grau,Cidade,UF,Orgao,Site,Observacao,Fonte,DataColeta:string;
  end;

procedure LerCSV(const AStream:TStream; const AProcess:TProc<TCsvContato>);
var SL:TStringList; Headers,Vals:TArray<string>; Delim:Char; I:Integer;
  IdxDoc,IdxRazao,IdxFantasia,IdxResp,IdxTel,IdxEmail,IdxGrau,IdxCidade,IdxUF,IdxOrgao,IdxSite,IdxObs,IdxFonte,IdxData:Integer; R:TCsvContato;
  function Idx(const N:string):Integer; var K:Integer; begin Result:=-1; for K:=0 to High(Headers) do if SameText(Trim(Headers[K]),N) then Exit(K); end;
  function Val(AIdx:Integer):string; begin if (AIdx>=0) and (AIdx<=High(Vals)) then Result:=Trim(Vals[AIdx]) else Result:=''; end;
begin
  if (AStream=nil) or (AStream.Size<=0) then TAppErrors.RaiseBadRequest('Arquivo CSV não informado.');
  if AStream.Size>5*1024*1024 then TAppErrors.RaiseBadRequest('O CSV deve possuir no máximo 5 MB.');
  SL:=TStringList.Create;
  try
    AStream.Position:=0; SL.LoadFromStream(AStream,TEncoding.UTF8); if SL.Count<2 then TAppErrors.RaiseBadRequest('CSV sem registros.');
    Delim:=','; if Length(SL[0])-Length(StringReplace(SL[0],';','',[rfReplaceAll])) > Length(SL[0])-Length(StringReplace(SL[0],',','',[rfReplaceAll])) then Delim:=';';
    Headers:=SplitCsv(SL[0],Delim);
    IdxDoc:=Idx('cpf_cnpj'); IdxRazao:=Idx('razao_social'); IdxFantasia:=Idx('nome_fantasia'); IdxResp:=Idx('responsavel'); IdxTel:=Idx('telefone'); IdxEmail:=Idx('email');
    IdxGrau:=Idx('grau'); IdxCidade:=Idx('cidade'); IdxUF:=Idx('uf'); IdxOrgao:=Idx('orgao'); IdxSite:=Idx('site'); IdxObs:=Idx('observacao'); IdxFonte:=Idx('fonte'); IdxData:=Idx('data_coleta');
    if (IdxRazao<0) and (IdxFantasia<0) and (IdxResp<0) then TAppErrors.RaiseBadRequest('CSV deve conter razao_social, nome_fantasia ou responsavel.');
    for I:=1 to SL.Count-1 do begin if Trim(SL[I]).IsEmpty then Continue; Vals:=SplitCsv(SL[I],Delim); FillChar(R,SizeOf(R),0);
      R.Documento:=Val(IdxDoc); R.Razao:=Val(IdxRazao); R.Fantasia:=Val(IdxFantasia); R.Responsavel:=Val(IdxResp); R.Telefone:=Val(IdxTel); R.Email:=Val(IdxEmail);
      R.Grau:=Val(IdxGrau); R.Cidade:=Val(IdxCidade); R.UF:=Val(IdxUF); R.Orgao:=Val(IdxOrgao); R.Site:=Val(IdxSite); R.Observacao:=Val(IdxObs); R.Fonte:=Val(IdxFonte); R.DataColeta:=Val(IdxData);
      AProcess(R);
    end;
  finally SL.Free; end;
end;

class function TPlataformaContatoService.ValidarCSV(const AStream:TStream; const AIdLista:Int64):TJSONObject;
var C:TUniConnection; Total,Novos,Existentes,Invalidos:Integer;
begin
  C:=NovaConexao;
  try
    if (AIdLista>0) and not TPlataformaContatoDAO.ListaExiste(C,AIdLista) then TAppErrors.RaiseBadRequest('Lista de contatos não encontrada.');
    Total:=0; Novos:=0; Existentes:=0; Invalidos:=0;
    LerCSV(AStream,
      procedure(R:TCsvContato)
      var Doc,EmailN,TelN:string; Id:Int64;
      begin
        Inc(Total); Doc:=SomenteDigitos(R.Documento); EmailN:=NormalizarEmail(R.Email); TelN:=NormalizarTelefone(R.Telefone);
        if ((not Doc.IsEmpty) and not MatchText(IntToStr(Length(Doc)),['11','14'])) or (not EmailValido(EmailN)) or
           ((not TelN.IsEmpty) and ((Length(TelN)<12) or (Length(TelN)>13))) or
           (Trim(R.Razao).IsEmpty and Trim(R.Fantasia).IsEmpty and Trim(R.Responsavel).IsEmpty) then begin Inc(Invalidos); Exit; end;
        Id:=0; if not Doc.IsEmpty then Id:=TPlataformaContatoDAO.BuscarIdPorDocumento(C,Doc) else Id:=TPlataformaContatoDAO.BuscarIdFallback(C,EmailN,TelN);
        if Id>0 then Inc(Existentes) else Inc(Novos);
      end);
    Result:=TJSONObject.Create; Result.AddPair('total',TJSONNumber.Create(Total)); Result.AddPair('novos',TJSONNumber.Create(Novos)); Result.AddPair('existentes',TJSONNumber.Create(Existentes)); Result.AddPair('invalidos',TJSONNumber.Create(Invalidos));
  finally C.Free; end;
end;

class function TPlataformaContatoService.ImportarCSV(const AIdUsuario:Int64; const AStream:TStream; const AIdLista:Int64; const AIP,AUserAgent:string):TJSONObject;
var C:TUniConnection; Total,Novos,Atualizados,Invalidos:Integer;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  C:=NovaConexao;
  try
    if (AIdLista>0) and not TPlataformaContatoDAO.ListaExiste(C,AIdLista) then TAppErrors.RaiseBadRequest('Lista de contatos não encontrada.');
    Total:=0; Novos:=0; Atualizados:=0; Invalidos:=0;
    C.StartTransaction;
    try
      LerCSV(AStream,
        procedure(R:TCsvContato)
        var Doc,Tipo,EmailN,TelN:string; Id:Int64; D:TDateTime; TemData:Boolean;
        begin
          Inc(Total); Doc:=SomenteDigitos(R.Documento); EmailN:=NormalizarEmail(R.Email); TelN:=NormalizarTelefone(R.Telefone);
          if ((not Doc.IsEmpty) and not MatchText(IntToStr(Length(Doc)),['11','14'])) or (not EmailValido(EmailN)) or
             ((not TelN.IsEmpty) and ((Length(TelN)<12) or (Length(TelN)>13))) or
             (Trim(R.Razao).IsEmpty and Trim(R.Fantasia).IsEmpty and Trim(R.Responsavel).IsEmpty) then begin Inc(Invalidos); Exit; end;
          Tipo:=TipoDocumento(Doc); TemData:=ParseDataISO(R.DataColeta,D); if Trim(R.DataColeta).IsEmpty then begin D:=Date; TemData:=True; end else if not TemData then begin Inc(Invalidos); Exit; end;
          Id:=0; if not Doc.IsEmpty then Id:=TPlataformaContatoDAO.BuscarIdPorDocumento(C,Doc) else Id:=TPlataformaContatoDAO.BuscarIdFallback(C,EmailN,TelN);
          if Id<=0 then begin
            Id:=TPlataformaContatoDAO.Inserir(C,AIdUsuario,Tipo,Trim(R.Documento),Doc,Trim(R.Razao),Trim(R.Fantasia),Trim(R.Responsavel),Trim(R.Telefone),TelN,Trim(R.Email),EmailN,Trim(R.Grau),Trim(R.Cidade),UpperCase(Trim(R.UF)),Trim(R.Orgao),Trim(R.Site),Trim(R.Observacao),Trim(R.Fonte),D,TemData); Inc(Novos);
          end else begin
            TPlataformaContatoDAO.Atualizar(C,Id,Tipo,Trim(R.Documento),Doc,Trim(R.Razao),Trim(R.Fantasia),Trim(R.Responsavel),Trim(R.Telefone),TelN,Trim(R.Email),EmailN,Trim(R.Grau),Trim(R.Cidade),UpperCase(Trim(R.UF)),Trim(R.Orgao),Trim(R.Site),Trim(R.Observacao),Trim(R.Fonte),'ATIVO',D,TemData); Inc(Atualizados);
          end;
          if AIdLista>0 then TPlataformaContatoDAO.VincularLista(C,AIdLista,Id);
        end);
      TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'CONTATOS_IMPORTADOS','plataforma_contato','',Format('CSV processado: %d novos, %d atualizados, %d inválidos.',[Novos,Atualizados,Invalidos]),AIP,AUserAgent);
      C.Commit;
    except if C.InTransaction then C.Rollback; raise; end;
    Result:=TJSONObject.Create; Result.AddPair('total',TJSONNumber.Create(Total)); Result.AddPair('novos',TJSONNumber.Create(Novos)); Result.AddPair('atualizados',TJSONNumber.Create(Atualizados)); Result.AddPair('invalidos',TJSONNumber.Create(Invalidos));
  finally C.Free; end;
end;

class function TPlataformaContatoService.AdicionarNaCampanha(const AIdUsuario,AIdCampanha,AIdLista:Int64; const AIds:TJSONArray; const AIP,AUserAgent:string):TJSONObject;
var C:TUniConnection; Inseridos:Integer;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário não identificado.');
  if AIdCampanha<=0 then TAppErrors.RaiseBadRequest('Campanha inválida.');
  if (AIdLista<=0) and ((AIds=nil) or (AIds.Count=0)) then TAppErrors.RaiseBadRequest('Informe uma lista ou contatos para adicionar.');
  C:=NovaConexao;
  try
    if not SameText(TPlataformaCampanhaDAO.BuscarSituacao(C,AIdCampanha),'RASCUNHO') then TAppErrors.RaiseBadRequest('A campanha só pode receber contatos enquanto estiver em rascunho.');
    C.StartTransaction;
    try
      if AIdLista>0 then begin if not TPlataformaContatoDAO.ListaExiste(C,AIdLista) then TAppErrors.RaiseBadRequest('Lista de contatos não encontrada.'); Inseridos:=TPlataformaContatoDAO.AdicionarContatosCampanhaPorLista(C,AIdCampanha,AIdLista); end
      else Inseridos:=TPlataformaContatoDAO.AdicionarContatosCampanhaPorIds(C,AIdCampanha,AIds);
      TPlataformaCampanhaDAO.AtualizarTotaisCampanha(C,AIdCampanha);
      TPlataformaContatoDAO.RegistrarAuditoria(C,AIdUsuario,'CONTATOS_ADICIONADOS_CAMPANHA','plataforma_campanha',AIdCampanha.ToString,Format('%d contato(s) adicionados à campanha pela base de contatos.',[Inseridos]),AIP,AUserAgent);
      C.Commit;
    except if C.InTransaction then C.Rollback; raise; end;
    Result:=TJSONObject.Create; Result.AddPair('inseridos',TJSONNumber.Create(Inseridos));
  finally C.Free; end;
end;

end.
