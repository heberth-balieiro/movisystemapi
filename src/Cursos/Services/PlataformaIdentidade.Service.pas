unit PlataformaIdentidade.Service;

interface

uses
  System.Classes,
  PlataformaIdentidade.Model;

type
  TPlataformaIdentidadeService = class
  private
    class function DetectarExtensaoImagem(const AStream: TStream): string; static;
    class function NovoNomeArquivo(const AExtensao: string): string; static;
    class function DiretorioLogo: string; static;
  public
    class function Buscar: TPlataformaIdentidadeConfig; static;
    class function Atualizar(
      const AIdUsuario: Int64;
      const ADados: TPlataformaIdentidadeInput;
      const AIP,AUserAgent: string
    ): TPlataformaIdentidadeConfig; static;
    class function SalvarLogo(
      const AIdUsuario: Int64;
      const ABaseUrl: string;
      const AStream: TStream;
      const AIP,AUserAgent: string
    ): TPlataformaIdentidadeConfig; static;
    class function ResolverLogoPublica(const AArquivo: string): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaIdentidade.DAO;

const
  MAX_IMAGE_SIZE = 5 * 1024 * 1024;

class function TPlataformaIdentidadeService.Buscar: TPlataformaIdentidadeConfig;
var Cfg:TAppApiConfig; Conn:TUniConnection;
begin
  Cfg:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn:=TDatabaseConnection.NewConnection(Cfg.Database);
  try Result:=TPlataformaIdentidadeDAO.Buscar(Conn); finally Conn.Free; end;
end;

class function TPlataformaIdentidadeService.Atualizar(
  const AIdUsuario: Int64;
  const ADados: TPlataformaIdentidadeInput;
  const AIP,AUserAgent: string
): TPlataformaIdentidadeConfig;
var Cfg:TAppApiConfig; Conn:TUniConnection; D:TPlataformaIdentidadeInput;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário responsável não identificado.');
  D:=ADados;
  D.NomePlataforma:=Trim(D.NomePlataforma);
  D.TituloLogin:=Trim(D.TituloLogin);
  D.SubtituloLogin:=Trim(D.SubtituloLogin);
  D.TituloDestaqueLogin:=Trim(D.TituloDestaqueLogin);
  D.DescricaoLogin:=Trim(D.DescricaoLogin);

  if D.NomePlataforma.IsEmpty then TAppErrors.RaiseBadRequest('Informe o nome da plataforma.');
  if Length(D.NomePlataforma)>120 then TAppErrors.RaiseBadRequest('Nome da plataforma muito longo.');
  if Length(D.TituloLogin)>120 then TAppErrors.RaiseBadRequest('Título do login muito longo.');
  if Length(D.SubtituloLogin)>180 then TAppErrors.RaiseBadRequest('Subtítulo do login muito longo.');
  if Length(D.TituloDestaqueLogin)>300 then TAppErrors.RaiseBadRequest('Título de destaque muito longo.');
  if Length(D.DescricaoLogin)>1000 then TAppErrors.RaiseBadRequest('Descrição do login muito longa.');

  Cfg:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn:=TDatabaseConnection.NewConnection(Cfg.Database);
  try
    Conn.StartTransaction;
    try
      TPlataformaIdentidadeDAO.Salvar(Conn,D,AIdUsuario);
      TPlataformaIdentidadeDAO.RegistrarAuditoria(Conn,AIdUsuario,'PLATAFORMA_IDENTIDADE_ALTERADA',
        'Identidade visual da plataforma atualizada.',AIP,AUserAgent);
      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;
    Result:=TPlataformaIdentidadeDAO.Buscar(Conn);
  finally Conn.Free; end;
end;

class function TPlataformaIdentidadeService.DetectarExtensaoImagem(const AStream:TStream):string;
var B:array[0..11] of Byte; P:Int64; L:Integer;
begin
  if (AStream=nil) or (AStream.Size<=0) then TAppErrors.RaiseBadRequest('Arquivo não informado.');
  if AStream.Size>MAX_IMAGE_SIZE then TAppErrors.RaiseBadRequest('A imagem deve possuir no máximo 5 MB.');
  P:=AStream.Position;
  try
    AStream.Position:=0; FillChar(B,SizeOf(B),0); L:=AStream.Read(B,SizeOf(B));
    if (L>=8) and (B[0]=$89) and (B[1]=$50) and (B[2]=$4E) and (B[3]=$47) then Exit('.png');
    if (L>=3) and (B[0]=$FF) and (B[1]=$D8) and (B[2]=$FF) then Exit('.jpg');
    if (L>=12) and (B[0]=Ord('R')) and (B[1]=Ord('I')) and (B[2]=Ord('F')) and (B[3]=Ord('F')) and
       (B[8]=Ord('W')) and (B[9]=Ord('E')) and (B[10]=Ord('B')) and (B[11]=Ord('P')) then Exit('.webp');
    TAppErrors.RaiseBadRequest('Formato inválido. Utilize PNG, JPG ou WEBP.');
  finally AStream.Position:=P; end;
end;

class function TPlataformaIdentidadeService.NovoNomeArquivo(const AExtensao:string):string;
var G:TGUID;
begin
  CreateGUID(G);
  Result:=LowerCase(StringReplace(StringReplace(StringReplace(GUIDToString(G),'{','',[rfReplaceAll]),'}','',[rfReplaceAll]),'-','',[rfReplaceAll]))+AExtensao;
end;

class function TPlataformaIdentidadeService.DiretorioLogo:string;
begin
  Result:=TPath.Combine(TPath.Combine(TPath.Combine(ExtractFilePath(ParamStr(0)),'uploads'),'plataforma'),'identidade');
end;

class function TPlataformaIdentidadeService.SalvarLogo(
  const AIdUsuario:Int64; const ABaseUrl:string; const AStream:TStream; const AIP,AUserAgent:string
):TPlataformaIdentidadeConfig;
var Ext,Nome,Dir,Caminho,Url:string; F:TFileStream; Cfg:TAppApiConfig; Conn:TUniConnection;
begin
  if AIdUsuario<=0 then TAppErrors.RaiseForbidden('Usuário responsável não identificado.');
  Ext:=DetectarExtensaoImagem(AStream); Nome:=NovoNomeArquivo(Ext); Dir:=DiretorioLogo;
  ForceDirectories(Dir); Caminho:=TPath.Combine(Dir,Nome); AStream.Position:=0;
  F:=TFileStream.Create(Caminho,fmCreate);
  try F.CopyFrom(AStream,0); finally F.Free; end;

  Url:=ABaseUrl; while Url.EndsWith('/') do Delete(Url,Length(Url),1);
  Url:=Url+'/v1/certifica/publico/plataforma/identidade/logo/'+Nome;

  Cfg:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn:=TDatabaseConnection.NewConnection(Cfg.Database);
  try
    Conn.StartTransaction;
    try
      TPlataformaIdentidadeDAO.AtualizarLogo(Conn,Url,AIdUsuario);
      TPlataformaIdentidadeDAO.RegistrarAuditoria(Conn,AIdUsuario,'PLATAFORMA_IDENTIDADE_LOGO_ALTERADA',
        'Logo da plataforma atualizado.',AIP,AUserAgent);
      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;
    Result:=TPlataformaIdentidadeDAO.Buscar(Conn);
  finally Conn.Free; end;
end;

class function TPlataformaIdentidadeService.ResolverLogoPublica(const AArquivo:string):string;
var Nome:string;
begin
  Nome:=ExtractFileName(Trim(AArquivo));
  if (Nome='') or (Nome<>Trim(AArquivo)) then TAppErrors.RaiseBadRequest('Arquivo inválido.');
  Result:=TPath.Combine(DiretorioLogo,Nome);
  if not TFile.Exists(Result) then TAppErrors.RaiseBadRequest('Logo não encontrada.');
end;

end.
