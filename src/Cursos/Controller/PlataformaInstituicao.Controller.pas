unit PlataformaInstituicao.Controller;

interface

type
  TPlataformaInstituicaoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.Classes,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaInstituicao.Model,
  PlataformaInstituicao.Service;

function AutorizarSuperAdmin(const Req: THorseRequest; const Res: THorseResponse;
  out AClaims: TJWTClaims): Boolean;
begin
  Result := False;
  if not TAppToken.ValidarToken(Req, Res, AClaims) then Exit;
  if not TAppToken.PossuiRole(AClaims.Roles, 'SUPER_ADMIN') then
  begin
    TAppResponse.Forbidden(Res, 'Sem permissão para administrar a plataforma.');
    Exit;
  end;
  Result := True;
end;

function InstituicaoToJson(const AModel: TPlataformaInstituicaoModel): TJSONObject;
var
  Tema, Metricas: TJSONObject;
  Modulos: TJSONArray;
  CodigoModulo: string;
begin
  Tema := TJSONObject.Create;
  Tema.AddPair('nome_exibicao', AModel.Tema.NomeExibicao);
  Tema.AddPair('logo_url', AModel.Tema.LogoUrl);
  Tema.AddPair('favicon_url', AModel.Tema.FaviconUrl);
  Tema.AddPair('imagem_login_url', AModel.Tema.ImagemLoginUrl);
  Tema.AddPair('cor_primaria', AModel.Tema.CorPrimaria);
  Tema.AddPair('cor_secundaria', AModel.Tema.CorSecundaria);
  Tema.AddPair('cor_destaque', AModel.Tema.CorDestaque);
  Tema.AddPair('cor_fundo', AModel.Tema.CorFundo);
  Tema.AddPair('cor_texto', AModel.Tema.CorTexto);

  Metricas := TJSONObject.Create;
  Metricas.AddPair('usuarios', TJSONNumber.Create(AModel.MetricasUsuarios));
  Metricas.AddPair('participantes', TJSONNumber.Create(AModel.MetricasParticipantes));
  Metricas.AddPair('cursos', TJSONNumber.Create(AModel.MetricasCursos));
  Metricas.AddPair('turmas', TJSONNumber.Create(AModel.MetricasTurmas));
  Metricas.AddPair('certificados', TJSONNumber.Create(AModel.MetricasCertificados));

  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AModel.Id));
  Result.AddPair('codigo_publico', AModel.CodigoPublico);
  Result.AddPair('slug', AModel.Slug);
  Result.AddPair('razao_social', AModel.RazaoSocial);
  Result.AddPair('nome_fantasia', AModel.NomeFantasia);
  Result.AddPair('documento', AModel.Documento);
  Result.AddPair('tipo', AModel.Tipo);
  Result.AddPair('email', AModel.Email);
  Result.AddPair('telefone', AModel.Telefone);
  Result.AddPair('site', AModel.Site);
  Result.AddPair('situacao', AModel.Situacao);
  Result.AddPair('criado_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AModel.CriadoEm));
  Result.AddPair('administrador_nome', AModel.AdministradorNome);
  Result.AddPair('administrador_email', AModel.AdministradorEmail);

  Modulos := TJSONArray.Create;
  for CodigoModulo in AModel.Modulos do
    Modulos.Add(CodigoModulo);

  Result.AddPair('modulos', Modulos);
  Result.AddPair('tema', Tema);
  Result.AddPair('metricas', Metricas);
end;

procedure PreencherFromJson(const AJson: TJSONObject; const AModel: TPlataformaInstituicaoModel);
var
  TemaValue,
  ModulosValue,
  ItemModulo: TJSONValue;
  Tema: TJSONObject;
  ModulosArray: TJSONArray;
begin
  AModel.Slug := TAppClasses.GetJsonString(AJson, 'slug');
  AModel.RazaoSocial := TAppClasses.GetJsonString(AJson, 'razao_social');
  AModel.NomeFantasia := TAppClasses.GetJsonString(AJson, 'nome_fantasia');
  AModel.Documento := TAppClasses.GetJsonString(AJson, 'documento');
  AModel.Tipo := TAppClasses.GetJsonString(AJson, 'tipo', 'PRIVADA');
  AModel.Email := TAppClasses.GetJsonString(AJson, 'email');
  AModel.Telefone := TAppClasses.GetJsonString(AJson, 'telefone');
  AModel.Site := TAppClasses.GetJsonString(AJson, 'site');
  AModel.Situacao := TAppClasses.GetJsonString(AJson, 'situacao', 'IMPLANTACAO');
  AModel.AdministradorNome := TAppClasses.GetJsonString(AJson, 'administrador_nome');
  AModel.AdministradorEmail := TAppClasses.GetJsonString(AJson, 'administrador_email');

  AModel.Modulos.Clear;
  ModulosValue := AJson.GetValue('modulos');
  if ModulosValue is TJSONArray then
  begin
    ModulosArray := ModulosValue as TJSONArray;

    for ItemModulo in ModulosArray do
      if not (ItemModulo is TJSONNull) and
         not Trim(ItemModulo.Value).IsEmpty then
        AModel.Modulos.Add(
          UpperCase(
            Trim(
              ItemModulo.Value
            )
          )
        );
  end;

  TemaValue := AJson.GetValue('tema');
  if (TemaValue <> nil) and (TemaValue is TJSONObject) then
  begin
    Tema := TemaValue as TJSONObject;
    AModel.Tema.NomeExibicao := TAppClasses.GetJsonString(Tema, 'nome_exibicao', AModel.NomeFantasia);
    AModel.Tema.LogoUrl := TAppClasses.GetJsonString(Tema, 'logo_url');
    AModel.Tema.FaviconUrl := TAppClasses.GetJsonString(Tema, 'favicon_url');
    AModel.Tema.ImagemLoginUrl := TAppClasses.GetJsonString(Tema, 'imagem_login_url');
    AModel.Tema.CorPrimaria := TAppClasses.GetJsonString(Tema, 'cor_primaria', '#2563EB');
    AModel.Tema.CorSecundaria := TAppClasses.GetJsonString(Tema, 'cor_secundaria', '#1E40AF');
    AModel.Tema.CorDestaque := TAppClasses.GetJsonString(Tema, 'cor_destaque', '#F59E0B');
    AModel.Tema.CorFundo := TAppClasses.GetJsonString(Tema, 'cor_fundo', '#F8FAFC');
    AModel.Tema.CorTexto := TAppClasses.GetJsonString(Tema, 'cor_texto', '#0F172A');
  end
  else
    AModel.Tema.NomeExibicao := AModel.NomeFantasia;
end;

class procedure TPlataformaInstituicaoController.Registry;
begin
  // Lista todas as instituições administradas pela MoviSystem.
  THorse.Get('/v1/certifica/plataforma/instituicoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TPlataformaInstituicaoModel>;
      Item: TPlataformaInstituicaoModel;
      Arr: TJSONArray;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then Exit;
        Lista := TPlataformaInstituicaoService.Listar(Req.Query['pesquisa'], Req.Query['situacao']);
        try
          Arr := TJSONArray.Create;
          for Item in Lista do Arr.AddElement(InstituicaoToJson(Item));
          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  // Cadastra o tenant, identidade visual e administrador principal em uma única transação.
  THorse.Post('/v1/certifica/plataforma/instituicoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      Entrada, Salva: TPlataformaInstituicaoModel;
      Dados: TJSONObject;
      SenhaTemporaria: string;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then Exit;
        Body := Req.Body<TJSONObject>;
        if Body = nil then TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Entrada := TPlataformaInstituicaoModel.Create;
        try
          PreencherFromJson(Body, Entrada);
          Salva := TPlataformaInstituicaoService.Criar(Entrada, Claims.UserId,
            TAppRequestInfo.GetIP(Req), TAppRequestInfo.GetUserAgent(Req), SenhaTemporaria);
          try
            Dados := InstituicaoToJson(Salva);
            if not SenhaTemporaria.IsEmpty then
              Dados.AddPair('senha_temporaria_administrador', SenhaTemporaria);
            TAppResponse.Created(Res, Dados, 'Instituição cadastrada com sucesso.');
          finally
            Salva.Free;
          end;
        finally
          Entrada.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  // Retorna todos os dados necessários para a tela de detalhe/edição do tenant.
  THorse.Get('/v1/certifica/plataforma/instituicoes/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Id: Int64;
      Item: TPlataformaInstituicaoModel;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then Exit;
        Id := StrToInt64Def(Req.Params['id'], 0);
        Item := TPlataformaInstituicaoService.Buscar(Id);
        try
          TAppResponse.Ok(Res, InstituicaoToJson(Item));
        finally
          Item.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  // Atualiza cadastro, identidade visual e administrador principal.
  THorse.Put('/v1/certifica/plataforma/instituicoes/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Id: Int64;
      Body: TJSONObject;
      Entrada, Salva: TPlataformaInstituicaoModel;
      Dados: TJSONObject;
      SenhaTemporaria: string;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then Exit;
        Id := StrToInt64Def(Req.Params['id'], 0);
        Body := Req.Body<TJSONObject>;
        if Body = nil then TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Entrada := TPlataformaInstituicaoModel.Create;
        try
          PreencherFromJson(Body, Entrada);
          Salva := TPlataformaInstituicaoService.Atualizar(Id, Entrada, Claims.UserId,
            TAppRequestInfo.GetIP(Req), TAppRequestInfo.GetUserAgent(Req), SenhaTemporaria);
          try
            Dados := InstituicaoToJson(Salva);
            if not SenhaTemporaria.IsEmpty then
              Dados.AddPair('senha_temporaria_administrador', SenhaTemporaria);
            TAppResponse.Ok(Res, Dados, 'Instituição atualizada com sucesso.');
          finally
            Salva.Free;
          end;
        finally
          Entrada.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
