unit Eleicao.Service;

interface

Uses Uni,
  System.SysUtils,
  System.Generics.Collections,
  Eleicao.Model,
  Eleicao.DAO,
  App.Config,
  Database.Connection,
  APP.Errors,
  App.JWT,
  App.Classes, JOSE.Types.JSON;

type
  TCadastroEleicaoResult = record
    IdEleicao : Integer;
end;


Type
TEleicaoService = Class
  private
    //Eleicao
    class procedure ValidarCadastroEleicao(const ADoc: TEleicaoModel); static;

    //Config
    class procedure ValidarCadastroEleicaoConfig(const ADoc: TEleicaoConfigModel); static;

    //Chapa
    class procedure ValidarCadastroChapa(const ADoc: TEleicaoChapaModel); static;

    //Membros
    class procedure ValidarCadastroMembros(const ADoc: TEleicaoChapaMembrosModel); static;

    //Comissao
    class procedure ValidarCadastroComissao(const ADoc: TEleicaoComissaoModel); static;

    //Questao
    class procedure ValidarCadastroQuestao(const ADoc: TEleicaoQuestaoModel); static;
    class procedure ValidarCadastroQuestaoOpcao(const ADoc: TEleicaoQuestaoOpcaoModel); static;

  public
    //Eleicao
    class function InserirEleicao(const AEmpresaId:Integer; const ADoc: TEleicaoModel): TCadastroEleicaoResult; static;
    class function BuscarStatusIntegracao(const AIdEmpresa: Integer): TJSONArray; static;


    //Config
    class function InserirEleicaoConfig(const AEmpresaId:Integer; const ADoc: TEleicaoConfigModel): Boolean; static;

    //Chapa
    class function InserirEleicaoChapa(const AEmpresaId:Integer; const ADoc: TEleicaoChapaModel): Boolean; static;

    //Membros
    class function InserirEleicaoChapaMembros(const AEmpresaId:Integer; const ADoc: TEleicaoChapaMembrosModel): Boolean; static;

    //Comissao
    class function InserirEleicaoComissao(const AEmpresaId:Integer; const ADoc: TEleicaoComissaoModel): Boolean; static;

    //Questao
    class function InserirEleicaoQuestao(const AEmpresaId:Integer; const ADoc: TEleicaoQuestaoModel): Boolean; static;
    class function InserirEleicaoQuestaoOpcao(const AEmpresaId:Integer; const ADoc: TEleicaoQuestaoOpcaoModel): Boolean; static;

End;

implementation

{ TEleicaoService }

{$REGION 'Eleicao'}

class function TEleicaoService.BuscarStatusIntegracao(
  const AIdEmpresa: Integer): TJSONArray;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Lista: TArray<TEleicaoRetornoDados>;
  Item: TEleicaoRetornoDados;
  Json: TJSONObject;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não informada.');

  Result := TJSONArray.Create;
  Conn := nil;

  try
    try
      Config := TAppConfig.Carregar(
        ExtractFilePath(ParamStr(0)) + 'Config.ini'
      );

      Conn := TDatabaseConnection.NewConnection(
        Config.Database
      );

      Lista := TEleicaoDao.BuscarStatusIntegracao(
        Conn,
        AIdEmpresa
      );

      for Item in Lista do
      begin
        Json := TJSONObject.Create;

        Json.AddPair(
          'id_eleicao_int',
          TJSONNumber.Create(Item.IdEleicaoInt)
        );

        Json.AddPair(
          'situacao',
          Item.Situacao
        );

        Result.AddElement(Json);
      end;

    except
      Result.Free;
      Result := nil;
      raise;
    end;

  finally
    Conn.Free;
  end;
end;

class function TEleicaoService.InserirEleicao(const AEmpresaId: Integer;
                            const ADoc: TEleicaoModel): TCadastroEleicaoResult;
var
  Conn      : TUniConnection;
  Config    : TAppApiConfig;
begin
  Result.IdEleicao := 0;

  ValidarCadastroEleicao(Adoc);
  Config      := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn        := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;

    try
      if TEleicaoDao.ExisteEleicao(Conn, AEmpresaId, Adoc.id_eleicao_int) then
      begin
        TEleicaoDao.Atualizar(Conn, AEmpresaId, Adoc);
      end
      else
      begin
        Result.IdEleicao      := TEleicaoDao.Inserir(Conn, AEmpresaId, ADoc);
      end;
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoService.ValidarCadastroEleicao(const ADoc: TEleicaoModel);
begin
  if ADoc = nil then
    TAppErrors.RaiseBadRequest('Dados da eleição não informado.');

  if ADoc.nome.IsEmpty then
    TAppErrors.RaiseBadRequest('Nome da eleição não informado.');

  if ADoc.id_eleicao_int <=0 then
    TAppErrors.RaiseBadRequest('ID eleição não informado.');

  if ADoc.ativo.IsEmpty then
    TAppErrors.RaiseBadRequest('Campo ativo não informado.');

  Adoc.ativo          := TAppClasses.NormalizarSN(Adoc.ativo,'N');

end;


{$ENDREGION}

{$REGION 'Config'}

class procedure TEleicaoService.ValidarCadastroEleicaoConfig(const ADoc: TEleicaoConfigModel);
begin
  if ADoc = nil then
    TAppErrors.RaiseBadRequest('Dados da configuração da eleição não informados.');

  if ADoc.EleicaoId <= 0 then
    TAppErrors.RaiseBadRequest('ID da eleição não informado.');

  if ADoc.IdConfig <= 0 then
    TAppErrors.RaiseBadRequest('ID da configuração não informado.');

  if Trim(ADoc.Slug).IsEmpty then
    TAppErrors.RaiseBadRequest('Slug da eleição não informado.');

  if Trim(ADoc.PaginaPublicar).IsEmpty then
    TAppErrors.RaiseBadRequest('Campo publicação não informado.');

  ADoc.PaginaPublicar := TAppClasses.NormalizarSN(ADoc.PaginaPublicar,'N');

  if ADoc.DataHoraInicio <= 0 then
    TAppErrors.RaiseBadRequest('Data/hora de início da eleição não informada.');

  if ADoc.DataHoraFim <= 0 then
    TAppErrors.RaiseBadRequest('Data/hora de término da eleição não informada.');

  if ADoc.DataHoraFim <= ADoc.DataHoraInicio then
    TAppErrors.RaiseBadRequest('Data/hora de término deve ser maior que a data/hora de início.');
end;

class function TEleicaoService.InserirEleicaoConfig(const AEmpresaId: Integer; const ADoc: TEleicaoConfigModel): Boolean;
var
  Conn      : TUniConnection;
  Config    : TAppApiConfig;
  IdEleicao: Integer;
  AId       : Integer;
begin
  Result := False;

  if AEmpresaId <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  ValidarCadastroEleicaoConfig(ADoc);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;
    try
      // ADoc.EleicaoId chega como ID da eleição no retaguarda.
      IdEleicao := TEleicaoDao.RetornoIDeleicaoAPI(Conn,AEmpresaId,ADoc.EleicaoId);

      if IdEleicao <= 0 then
        TAppErrors.RaiseBadRequest('Eleição não encontrada para a empresa informada.');

      // A partir daqui trabalha somente com o ID interno da API.
      ADoc.EleicaoId := IdEleicao;

      if TEleicaoDao.ExisteEleicaoConfig(Conn,AEmpresaId,ADoc.IdConfig) then
        Result := TEleicaoDao.AtualizarConfig(Conn,AEmpresaId,ADoc)
      else
      begin
        AId := TEleicaoDao.InserirConfig(Conn,AEmpresaId,ADoc);
        Result := AId > 0;
      end;

      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

{$ENDREGION}

{$REGION 'Chapa'}

class procedure TEleicaoService.ValidarCadastroChapa(const ADoc: TEleicaoChapaModel);
begin
  if ADoc = nil then
    TAppErrors.RaiseBadRequest('Dados da chapa não informados.');

  if ADoc.EleicaoId <= 0 then
    TAppErrors.RaiseBadRequest('ID da eleição não informado.');

  if ADoc.id_chapa_int <= 0 then
    TAppErrors.RaiseBadRequest('ID da chapa não informado.');

  if Trim(ADoc.NomeChapa).IsEmpty then
    TAppErrors.RaiseBadRequest('Nome da chapa não informado.');

  if Trim(ADoc.Ativo).IsEmpty then
    TAppErrors.RaiseBadRequest('Campo ativo não informado.');

  ADoc.Ativo := TAppClasses.NormalizarSN(ADoc.Ativo,'N');
end;

class function TEleicaoService.InserirEleicaoChapa(const AEmpresaId: Integer; const ADoc: TEleicaoChapaModel): Boolean;
var
  Conn      : TUniConnection;
  Config    : TAppApiConfig;
  IdEleicao : Integer;
  AId       : Integer;
begin
  Result := False;

  if AEmpresaId <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  ValidarCadastroChapa(ADoc);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;
    try
      // EleicaoId chega como ID da eleição no retaguarda.
      IdEleicao := TEleicaoDao.RetornoIDeleicaoAPI(Conn,AEmpresaId,ADoc.EleicaoId);

      if IdEleicao <= 0 then
        TAppErrors.RaiseBadRequest('Eleição não encontrada para a empresa informada.');

      // A partir daqui utiliza o ID interno da API.
      ADoc.EleicaoId := IdEleicao;

      if TEleicaoDao.ExisteChapa(Conn,AEmpresaId,ADoc.id_chapa_int) then
        Result := TEleicaoDao.AtualizarChapa(Conn,AEmpresaId,ADoc)
      else
      begin
        AId := TEleicaoDao.InserirChapa(Conn,AEmpresaId,ADoc);
        Result := AId > 0;
      end;

      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

{$ENDREGION}

{$REGION 'Membros'}

class procedure TEleicaoService.ValidarCadastroMembros(const ADoc: TEleicaoChapaMembrosModel);
begin
  if ADoc = nil then TAppErrors.RaiseBadRequest('Dados do membro não informados.');

  if ADoc.EleicaoId <= 0 then
    TAppErrors.RaiseBadRequest('[API] ID da eleição não informado.');

  if ADoc.EleicaoChapaId <= 0 then
    TAppErrors.RaiseBadRequest('[API] ID da chapa não informado.');

  if ADoc.id_membro_int <= 0 then
    TAppErrors.RaiseBadRequest('[API] ID do membro não informado.');

  if Trim(ADoc.Nome).IsEmpty then
    TAppErrors.RaiseBadRequest('[API] Nome do membro não informado.');

  if Trim(ADoc.Cpf).IsEmpty then
    TAppErrors.RaiseBadRequest('[API] CPF não informado.');

  if Trim(ADoc.Ativo).IsEmpty then
    TAppErrors.RaiseBadRequest('[API] Campo ativo não informado.');

  ADoc.Ativo := TAppClasses.NormalizarSN(ADoc.Ativo,'N');
end;

class function TEleicaoService.InserirEleicaoChapaMembros(const AEmpresaId: Integer; const ADoc: TEleicaoChapaMembrosModel): Boolean;
var
  Conn          : TUniConnection;
  Config        : TAppApiConfig;
  IdEleicao     : Integer;
  IdChapa       : Integer;
  AId           : Integer;
begin
  Result := False;

  if AEmpresaId <= 0 then TAppErrors.RaiseBadRequest('Empresa não informada.');

  ValidarCadastroMembros(ADoc);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;
    try
      // IDs recebidos são os IDs do retaguarda.
      IdEleicao := TEleicaoDao.RetornoIDeleicaoAPI(Conn,AEmpresaId,ADoc.EleicaoId);
      if IdEleicao <= 0 then TAppErrors.RaiseBadRequest('Eleição não encontrada para a empresa informada.');

      IdChapa := TEleicaoDao.RetornoIDChapaAPI(Conn,AEmpresaId,ADoc.EleicaoChapaId);
      if IdChapa <= 0 then TAppErrors.RaiseBadRequest('Chapa não encontrada para a empresa informada.');

      // Daqui para frente somente IDs internos da API.
      ADoc.EleicaoId := IdEleicao;
      ADoc.EleicaoChapaId := IdChapa;

      if TEleicaoDao.ExisteMembros(Conn,AEmpresaId,ADoc.id_membro_int) then
        Result := TEleicaoDao.AtualizarMembros(Conn,AEmpresaId,ADoc)
      else
      begin
        AId := TEleicaoDao.InserirMembros(Conn,AEmpresaId,ADoc);
        Result := AId > 0;
      end;

      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

{$ENDREGION}


{$REGION 'Comissao'}

class procedure TEleicaoService.ValidarCadastroComissao(const ADoc: TEleicaoComissaoModel);
begin
  if ADoc = nil then
    TAppErrors.RaiseBadRequest('Dados da comissão não informados.');

  if ADoc.IdComissaoInt <= 0 then
    TAppErrors.RaiseBadRequest('ID da comissão não informado.');

  if ADoc.IdEleicaoInt <= 0 then
    TAppErrors.RaiseBadRequest('ID da eleição não informado.');

  if Trim(ADoc.Nome).IsEmpty then
    TAppErrors.RaiseBadRequest('Nome da comissão não informado.');

  if Trim(ADoc.CPF).IsEmpty then
    TAppErrors.RaiseBadRequest('CPF da comissão não informado.');

  if Trim(ADoc.Email).IsEmpty then
    TAppErrors.RaiseBadRequest('E-mail da comissão não informado.');

  if Trim(ADoc.SenhaHash).IsEmpty then
    TAppErrors.RaiseBadRequest('Senha da comissão não informada.');

  ADoc.Ativo := TAppClasses.NormalizarSN(ADoc.Ativo,'S');
end;

class function TEleicaoService.InserirEleicaoComissao(const AEmpresaId: Integer;
  const ADoc: TEleicaoComissaoModel): Boolean;
var
  Conn: TUniConnection;
  Config: TAppApiConfig;
  IdEleicao, UsuarioId, IdComissao: Integer;
begin
  Result := False;

  if AEmpresaId <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  ValidarCadastroComissao(ADoc);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      IdEleicao := TEleicaoDao.RetornoIDeleicaoAPI(Conn, AEmpresaId, ADoc.IdEleicaoInt);
      if IdEleicao <= 0 then
        TAppErrors.RaiseBadRequest('Eleição não encontrada para a empresa informada.');

      ADoc.EleicaoId := IdEleicao;

      UsuarioId := TEleicaoDao.BuscarUsuarioComissao(Conn, AEmpresaId, ADoc.CPF);
      if UsuarioId <= 0 then
        UsuarioId := TEleicaoDao.InserirUsuarioComissao(Conn, AEmpresaId, ADoc)
      else
        TEleicaoDao.AtualizarUsuarioComissao(Conn, AEmpresaId, UsuarioId, ADoc);

      if UsuarioId <= 0 then
        TAppErrors.RaiseBadRequest('Não foi possível criar o usuário da comissão.');

      ADoc.UsuarioId := UsuarioId;

      if TEleicaoDao.ExisteComissao(
        Conn, AEmpresaId, ADoc.IdEleicaoInt, ADoc.IdComissaoInt) then
      begin
        TEleicaoDao.AtualizarComissao(Conn, AEmpresaId, ADoc);
        Result := True;
      end
      else
      begin
        IdComissao := TEleicaoDao.InserirComissao(Conn, AEmpresaId, ADoc);
        Result := IdComissao > 0;
      end;

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

{$ENDREGION}

{$REGION}

class procedure TEleicaoService.ValidarCadastroQuestao(const ADoc: TEleicaoQuestaoModel);
begin
  if ADoc = nil then
    TAppErrors.RaiseBadRequest('Dados da questão não informados.');

  if ADoc.id_eleicao_int <= 0 then
    TAppErrors.RaiseBadRequest('ID da eleição não informado.');

  if ADoc.id_questao_int <= 0 then
    TAppErrors.RaiseBadRequest('ID da questão não informado.');

  if Trim(ADoc.titulo).IsEmpty then
    TAppErrors.RaiseBadRequest('Título da questão não informado.');

  if Trim(ADoc.Ativo).IsEmpty then
    TAppErrors.RaiseBadRequest('Campo ativo não informado.');

  ADoc.Ativo := TAppClasses.NormalizarSN(ADoc.Ativo,'N');
end;

class function TEleicaoService.InserirEleicaoQuestao(const AEmpresaId:Integer; const ADoc: TEleicaoQuestaoModel): Boolean;
var
  Conn      : TUniConnection;
  Config    : TAppApiConfig;
  IdEleicao : Integer;
  AId       : Integer;
begin
  Result := False;

  if AEmpresaId <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  ValidarCadastroQuestao(ADoc);

  Config  := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn    := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;
    try
      // EleicaoId chega como ID da eleição no retaguarda.
      IdEleicao := TEleicaoDao.RetornoIDeleicaoAPI(Conn, AEmpresaId, ADoc.id_eleicao_int);

      if IdEleicao <= 0 then
        TAppErrors.RaiseBadRequest('Eleição não encontrada para a empresa informada.');

      // A partir daqui utiliza o ID interno da API.
      ADoc.eleicao_id := IdEleicao;

      if TEleicaoDao.ExisteQuestao(Conn, AEmpresaId, ADoc.id_questao_int) then
      begin
        TEleicaoDao.AtualizarQuestao(Conn, AEmpresaId,ADoc);
        Result := True;
      end
      else
      begin
        AId := TEleicaoDao.InserirQuestao(Conn, AEmpresaId, ADoc);
        Result := AId > 0;
      end;

      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;


class procedure TEleicaoService.ValidarCadastroQuestaoOpcao(const ADoc: TEleicaoQuestaoOpcaoModel);
begin
  if ADoc = nil then
    TAppErrors.RaiseBadRequest('Dados da opção da questão não informados.');

  if ADoc.id_opcao_int <= 0 then
    TAppErrors.RaiseBadRequest('ID da opção não informado.');

  if ADoc.id_questao_int <= 0 then
    TAppErrors.RaiseBadRequest('ID da questão não informado.');

  if ADoc.id_eleicao_int <= 0 then
    TAppErrors.RaiseBadRequest('ID da eleição não informado.');

  if Trim(ADoc.descricao).IsEmpty then
    TAppErrors.RaiseBadRequest('Descrição da opção não informada.');

  ADoc.ativo := TAppClasses.NormalizarSN(ADoc.ativo,'S');
end;

class function TEleicaoService.InserirEleicaoQuestaoOpcao(const AEmpresaId: Integer;
  const ADoc: TEleicaoQuestaoOpcaoModel): Boolean;
var
  Conn: TUniConnection;
  Config: TAppApiConfig;
  IdEleicao, IdQuestao: Integer;
  AId: Int64;
begin
  Result := False;

  if AEmpresaId <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  ValidarCadastroQuestaoOpcao(ADoc);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      IdEleicao := TEleicaoDao.RetornoIDeleicaoAPI(Conn, AEmpresaId, ADoc.id_eleicao_int);
      if IdEleicao <= 0 then
        TAppErrors.RaiseBadRequest('Eleição não encontrada para a empresa informada.');

      IdQuestao := TEleicaoDao.RetornoIDQuestaoAPI(Conn, AEmpresaId, ADoc.id_questao_int);
      if IdQuestao <= 0 then
        TAppErrors.RaiseBadRequest('Questão não encontrada para a empresa informada.');

      ADoc.eleicao_id := IdEleicao;
      ADoc.questao_id := IdQuestao;

      if TEleicaoDao.ExisteQuestaoOpcao(
        Conn, AEmpresaId, ADoc.id_eleicao_int, ADoc.id_questao_int, ADoc.id_opcao_int) then
      begin
        TEleicaoDao.AtualizarQuestaoOpcao(Conn, AEmpresaId, ADoc);
        Result := True;
      end
      else
      begin
        AId := TEleicaoDao.InserirQuestaoOpcao(Conn, AEmpresaId, ADoc);
        Result := AId > 0;
      end;

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

{$ENDREGION}

end.
