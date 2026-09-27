unit Empresa.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Empresa.Model,
  CatalogoConfig.Model;

type
  TCadastroEmpresaResult = record
    IdEmpresa: Int64;
    IdUsuario: Int64;
end;

TEmpresaService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure ValidarCadastroEmpresa(const AEmpresa: TEmpresaModel; const ASenha: string); static;
    class procedure ValidarEmpresaAdmin(const AEmpresa: TEmpresaModel); static;
  public
    class function CadastrarEmpresa(const AEmpresa: TEmpresaModel;const ASenha: string): TCadastroEmpresaResult; static;

    class function ListarEmpresas(const APesquisa: string = ''): TObjectList<TEmpresaModel>; static;

    class function BuscarEmpresa(const AIdEmpresa: Int64): TEmpresaModel; static;

    class procedure AtualizarEmpresa(const AIdEmpresa: Int64;const AEmpresa: TEmpresaModel); static;

    class procedure AtivarEmpresa(const AIdEmpresa: Int64); static;

    class procedure InativarEmpresa(const AIdEmpresa: Int64); static;

    class procedure LiberarEmpresa(const AIdEmpresa: Int64;const ADataValidade: TDate); static;

    class procedure ExcluirEmpresa(const AIdEmpresa: Int64); static;
  end;

implementation

uses
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  Empresa.DAO,
  Usuario.Model,
  Usuario.Service,
  CatalogoConfig.Service,
  System.DateUtils,
  Assinatura.Service;

function RemoverAcentosSlug(const ATexto: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(ATexto));
  S := StringReplace(S, 'á', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'à', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'ã', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'â', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'ä', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'é', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'è', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'ê', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'ë', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'í', 'i', [rfReplaceAll]);
  S := StringReplace(S, 'ì', 'i', [rfReplaceAll]);
  S := StringReplace(S, 'î', 'i', [rfReplaceAll]);
  S := StringReplace(S, 'ï', 'i', [rfReplaceAll]);
  S := StringReplace(S, 'ó', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ò', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'õ', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ô', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ö', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ú', 'u', [rfReplaceAll]);
  S := StringReplace(S, 'ù', 'u', [rfReplaceAll]);
  S := StringReplace(S, 'û', 'u', [rfReplaceAll]);
  S := StringReplace(S, 'ü', 'u', [rfReplaceAll]);
  S := StringReplace(S, 'ç', 'c', [rfReplaceAll]);
  Result := S;
end;

function GerarSlugEmpresa(const ANome: string; const AIdEmpresa: Int64): string;
var
  S: string;
  I: Integer;
  C: Char;
begin
  S := RemoverAcentosSlug(ANome);
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if CharInSet(C, ['a'..'z', '0'..'9']) then
      Result := Result + C
    else if CharInSet(C, [' ', '-', '_', '.', '/', '\']) then
      Result := Result + '-';
  end;
  while Pos('--', Result) > 0 do
    Result := StringReplace(Result, '--', '-', [rfReplaceAll]);
  Result := Trim(Result);
  while (Length(Result) > 0) and (Result[1] = '-') do
    Delete(Result, 1, 1);
  while (Length(Result) > 0) and (Result[Length(Result)] = '-') do
    Delete(Result, Length(Result), 1);
  if Result.IsEmpty then
    Result := 'catalogo';
  Result := Result + '-' + AIdEmpresa.ToString;
end;

class function TEmpresaService.NormalizarSN(const AValor, APadrao: string): string;
var
  Valor: string;
begin
  Valor := UpperCase(Trim(AValor));

  if Valor.IsEmpty then
    Valor := UpperCase(Trim(APadrao));

  if (Valor <> 'S') and (Valor <> 'N') then
    Valor := UpperCase(Trim(APadrao));

  if Valor.IsEmpty then
    Valor := 'N';

  Result := Valor;
end;

class procedure TEmpresaService.ValidarCadastroEmpresa(const AEmpresa: TEmpresaModel;const ASenha: string);
begin
  if AEmpresa = nil then
    TAppErrors.RaiseBadRequest('Dados da empresa não informados.');

  if Trim(AEmpresa.Nome).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome da empresa.');

  if Trim(AEmpresa.Cnpj).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o CNPJ da empresa.');

  if Trim(AEmpresa.Email).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o email da empresa.');

  if Trim(AEmpresa.NomeResponsavel).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome do responsável.');

  if Trim(ASenha).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a senha de acesso.');

  if Length(Trim(ASenha)) < 6 then
    TAppErrors.RaiseBadRequest('A senha deve possuir no mínimo 6 caracteres.');

  if (not Trim(AEmpresa.Uf).IsEmpty) and (Length(Trim(AEmpresa.Uf)) <> 2) then
    TAppErrors.RaiseBadRequest('UF inválida. Informe apenas 2 caracteres.');

  if AEmpresa.idplano <=0 then
    TAppErrors.RaiseBadRequest('Selecione um plano.');

  if AEmpresa.idsegmento <=0 then
    TAppErrors.RaiseBadRequest('Selecione um segmento.');


end;

class procedure TEmpresaService.ValidarEmpresaAdmin(const AEmpresa: TEmpresaModel);
begin
  if AEmpresa = nil then
    TAppErrors.RaiseBadRequest('Dados da empresa não informados.');

  if Trim(AEmpresa.Nome).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome da empresa.');

  if Trim(AEmpresa.Cnpj).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o CNPJ da empresa.');

  if Trim(AEmpresa.Email).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o email da empresa.');

  if Trim(AEmpresa.NomeResponsavel).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome do responsável.');

  if (not Trim(AEmpresa.Uf).IsEmpty) and (Length(Trim(AEmpresa.Uf)) <> 2) then
    TAppErrors.RaiseBadRequest('UF inválida. Informe apenas 2 caracteres.');

  AEmpresa.Nome                     := Trim(AEmpresa.Nome);
  AEmpresa.Cnpj                     := Trim(AEmpresa.Cnpj);
  AEmpresa.Cep                      := Trim(AEmpresa.Cep);
  AEmpresa.Endereco                 := Trim(AEmpresa.Endereco);
  AEmpresa.Numero                   := Trim(AEmpresa.Numero);
  AEmpresa.Complemento              := Trim(AEmpresa.Complemento);
  AEmpresa.Bairro                   := Trim(AEmpresa.Bairro);
  AEmpresa.Cidade                   := Trim(AEmpresa.Cidade);
  AEmpresa.Uf                       := UpperCase(Trim(AEmpresa.Uf));
  AEmpresa.Whatsapp                 := Trim(AEmpresa.Whatsapp);
  AEmpresa.Email                    := LowerCase(Trim(AEmpresa.Email));
  AEmpresa.NomeResponsavel          := Trim(AEmpresa.NomeResponsavel);

  AEmpresa.Ativo                    := NormalizarSN(AEmpresa.Ativo, 'S');
  AEmpresa.NotificarPedidoWhatsapp  := NormalizarSN(AEmpresa.NotificarPedidoWhatsapp, 'S');
  AEmpresa.NotificarPedidoEmail     := NormalizarSN(AEmpresa.NotificarPedidoEmail, 'S');
  AEmpresa.ResumoDiario             := NormalizarSN(AEmpresa.ResumoDiario, 'N');
  AEmpresa.MensagemModelo           := Trim(AEmpresa.MensagemModelo);

  if AEmpresa.DataValidade <= 0 then
    AEmpresa.DataValidade := IncDay(Date, 30);

  AEmpresa.IdPlano                   := AEmpresa.idplano;
end;

function Sim(const AValor: string): Boolean;
begin
  Result := SameText(AValor, 'S');
end;


class function TEmpresaService.CadastrarEmpresa(const AEmpresa: TEmpresaModel;const ASenha: string): TCadastroEmpresaResult;
var
  Config    : TAppApiConfig;
  Conn      : TUniConnection;
  Usuario   : TUsuarioModel;
  ConfigCat : TCatalogoConfigModel;
  LPlano    : TRecPlano;
begin
  Result.IdEmpresa := 0;
  Result.IdUsuario := 0;

  ValidarCadastroEmpresa(AEmpresa, ASenha);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;

    try

      if TEmpresaDAO.ExisteCnpj(Conn, AEmpresa.Cnpj) then
        TAppErrors.RaiseBadRequest('CNPJ já cadastrado.');

      if TEmpresaDAO.ExisteEmail(Conn, AEmpresa.Email) then
        TAppErrors.RaiseBadRequest('Email já cadastrado para outra empresa.');

      LPlano  := TEmpresaDAO.ValidarPlano(Conn, AEmpresa.idplano);

      if not LPlano.Encontrado then
        TAppErrors.RaiseBadRequest('Plano informado não foi encontrado.');

      if Sim(LPlano.PermitePedido) then
      begin
        AEmpresa.NotificarPedidoWhatsapp  := 'S';
        AEmpresa.NotificarPedidoEmail     := 'S';
        AEmpresa.ResumoDiario             := 'S';
      end
      else
      begin
        AEmpresa.NotificarPedidoWhatsapp  := 'N';
        AEmpresa.NotificarPedidoEmail     := 'N';
        AEmpresa.ResumoDiario             := 'N';
      end;

      Result.IdEmpresa                    := TEmpresaDAO.Inserir(Conn, AEmpresa);

      //Cria o Usuario
      Usuario := TUsuarioModel.Create;
      try
        Usuario.IdEmpresa       := Result.IdEmpresa;
        Usuario.Nome            := AEmpresa.NomeResponsavel;
        Usuario.Email           := AEmpresa.Email;
        Usuario.Perfil          := 'CLIENTE';
        Usuario.Ativo           := 'S';

        Result.IdUsuario        := TUsuarioService.CriarUsuario(Conn, Usuario, ASenha);
      finally
        Usuario.Free;
      end;

      //Cria a Config
      ConfigCat     :=  TCatalogoConfigModel.Create;
      Try
        ConfigCat.IdConfig            := 0;
        ConfigCat.IdEmpresa           := Result.IdEmpresa;
        ConfigCat.Slug                := GerarSlugEmpresa(AEmpresa.Nome, Result.IdEmpresa);
        ConfigCat.TituloCatalogo      := 'Catálogo da ' + AEmpresa.Nome;
        ConfigCat.Descricao           := 'Confira os produtos disponíveis no catálogo digital da ' + AEmpresa.Nome + '.';
        ConfigCat.CorPrimaria         := '#FF6600';
        ConfigCat.CorSecundaria       := '#222222';
        ConfigCat.LogoUrl             := '';
        ConfigCat.BannerUrl           := '';
        ConfigCat.MostrarPreco        := 'N';
        ConfigCat.PermitirObservacao  := 'N';
        ConfigCat.PermitirRetirada    := 'N';
        ConfigCat.PermitirEntrega     := 'N';
        ConfigCat.ValorMinimoPedido   := 0;
        ConfigCat.Ativo               := 'S';
        ConfigCat.url_whatsapp        := '';
        ConfigCat.instancia_whatsapp  := '';
        ConfigCat.token_whatsapp      := '';
        ConfigCat.permitirficha       := 'N';

        ConfigCat.Ecommerce           := 'N';
        ConfigCat.PagSeguro           := 'N';
        ConfigCat.PagSeguroToken      := '';
        ConfigCat.PagSeguroAmbiente   := 'SANDBOX';

        ConfigCat.CompraSemCadastro   := 'S';
        ConfigCat.ExigirClienteCadastrado := 'N';
        ConfigCat.PermitirConsignado  := 'N';
        ConfigCat.tipo_catalogo       := LPlano.TipoCatalogo;
        ConfigCat.idsegmento          := AEmpresa.idsegmento;

        TCatalogoConfigService.InserirConfig(Conn, Result.IdEmpresa, ConfigCat);

        TAssinaturaService.CriarTrialEmpresa(Conn, Result.IdEmpresa, AEmpresa.IdPlano,'MENSAL');

      Finally
        ConfigCat.Free;
      End;

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class function TEmpresaService.ListarEmpresas(const APesquisa: string): TObjectList<TEmpresaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TEmpresaDAO.Listar(Conn, APesquisa);
  finally
    Conn.Free;
  end;

end;

class function TEmpresaService.BuscarEmpresa(const AIdEmpresa: Int64): TEmpresaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TEmpresaDAO.BuscarPorId(Conn, AIdEmpresa);

    if Result = nil then
      TAppErrors.RaiseNotFound('Empresa não encontrada.');
  finally
    Conn.Free;
  end;
end;

class procedure TEmpresaService.AtualizarEmpresa(const AIdEmpresa: Int64;const AEmpresa: TEmpresaModel
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  EmpresaAtual: TEmpresaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  if AEmpresa = nil then
    TAppErrors.RaiseBadRequest('Dados da empresa não informados.');

  AEmpresa.IdEmpresa := AIdEmpresa;
  ValidarEmpresaAdmin(AEmpresa);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    EmpresaAtual := TEmpresaDAO.BuscarPorId(Conn, AIdEmpresa);
    try
      if EmpresaAtual = nil then
        TAppErrors.RaiseNotFound('Empresa não encontrada.');

      if TEmpresaDAO.ExisteCnpj(Conn, AEmpresa.Cnpj, AIdEmpresa) then
        TAppErrors.RaiseBadRequest('Já existe outra empresa com este CNPJ.');

      if TEmpresaDAO.ExisteEmail(Conn, AEmpresa.Email, AIdEmpresa) then
        TAppErrors.RaiseBadRequest('Já existe outra empresa com este email.');

      TEmpresaDAO.Atualizar(Conn, AEmpresa);
    finally
      EmpresaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TEmpresaService.AtivarEmpresa(const AIdEmpresa: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  EmpresaAtual: TEmpresaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    EmpresaAtual := TEmpresaDAO.BuscarPorId(Conn, AIdEmpresa);
    try
      if EmpresaAtual = nil then
        TAppErrors.RaiseNotFound('Empresa não encontrada.');

      TEmpresaDAO.AlterarAtivo(Conn, AIdEmpresa, 'S');
    finally
      EmpresaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TEmpresaService.InativarEmpresa(const AIdEmpresa: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  EmpresaAtual: TEmpresaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    EmpresaAtual := TEmpresaDAO.BuscarPorId(Conn, AIdEmpresa);
    try
      if EmpresaAtual = nil then
        TAppErrors.RaiseNotFound('Empresa não encontrada.');

      TEmpresaDAO.AlterarAtivo(Conn, AIdEmpresa, 'N');
    finally
      EmpresaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TEmpresaService.LiberarEmpresa(const AIdEmpresa: Int64;const ADataValidade: TDate);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  EmpresaAtual: TEmpresaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  if ADataValidade <= 0 then
    TAppErrors.RaiseBadRequest('Data de validade não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    EmpresaAtual := TEmpresaDAO.BuscarPorId(Conn, AIdEmpresa);
    try
      if EmpresaAtual = nil then
        TAppErrors.RaiseNotFound('Empresa não encontrada.');

      TEmpresaDAO.LiberarAcesso(Conn, AIdEmpresa, ADataValidade);
    finally
      EmpresaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TEmpresaService.ExcluirEmpresa(const AIdEmpresa: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  EmpresaAtual: TEmpresaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    EmpresaAtual := TEmpresaDAO.BuscarPorId(Conn, AIdEmpresa);
    try
      if EmpresaAtual = nil then
        TAppErrors.RaiseNotFound('Empresa não encontrada.');

      TEmpresaDAO.Excluir(Conn, AIdEmpresa);
    finally
      EmpresaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
