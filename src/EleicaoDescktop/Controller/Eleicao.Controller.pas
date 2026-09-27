//Integracao

unit Eleicao.Controller;

interface

Uses EasyOneIntegracao.Service;

type
  TEleicaoController = class
  public
    class procedure Registry;
    class procedure RegistryConfig;
    class procedure RegistryChapa;
    class procedure RegistryMembros;
    class procedure RegistryQuestao;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.Config,
  Eleicao.Model,
  eleicao.Service,
  App.Response,
  APP.Errors,
  App.Classes;

{$REGION 'Eleicao'}

procedure PreencherEleicaoFromJson(const AJson: TJSONObject; const ADoc: TEleicaoModel);
begin
  ADoc.id_eleicao_int   := TAppClasses.GetJsonInt(AJson, 'id_eleicao_int',0);
  ADoc.Codigo           := TAppClasses.GetJsonInt(AJson, 'codigo',0);
  ADoc.nome             := TAppClasses.GetJsonString(AJson, 'nome');
  ADoc.descricao        := TAppClasses.GetJsonString(AJson, 'descricao');
  ADoc.ano              := TAppClasses.GetJsonInt(AJson, 'ano',0);
  ADoc.ativo            := TAppClasses.GetJsonString(AJson, 'ativo','S');
  ADoc.ano_fim          := TAppClasses.GetJsonInt(AJson, 'ano_fim',0);
  ADoc.Tipo             := TAppClasses.GetJsonString(AJson, 'tipo');
  ADoc.situacao         := TAppClasses.GetJsonString(AJson, 'situacao');
  Adoc.operacao         := TAppClasses.GetJsonString(AJson, 'operacao');
end;

class procedure TEleicaoController.Registry;
begin
  //para cadastro de eleicao retorno de apenas um objeto

  {$REGION 'Post'}

  THorse.Post('/v1/integracao/eleicao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body      : TJSONObject;
      ADoc      : TEleicaoModel;
      Resultado : TCadastroEleicaoResult;
      Retorno   : TJSONObject;
      Contexto  : TEasyOneIntegracaoContexto;
      UUID      : String;
      APIKey    : String;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);

        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        ADoc                := TEleicaoModel.Create;
        try
          PreencherEleicaoFromJson(Body, Adoc);
          Resultado         := TEleicaoService.InserirEleicao(Contexto.IdEmpresaAPI,Adoc);
          Retorno           := TJSONObject.Create;

          if Resultado.IdEleicao > 0 then
          Retorno.AddPair('id', TJSONNumber.Create(Resultado.IdEleicao));

          TAppResponse.Created(Res, Retorno, 'Eleição sincronizada com sucesso.');
        finally
          Adoc.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

  {$REGION 'Get Eleicao'}

    THorse.Get('/v1/integracao/easyone/eleicoes/status',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Contexto  : TEasyOneIntegracaoContexto;
      Dados     : TJSONArray;
      UUID      : String;
      APIKey    : String;
    begin
      try
        UUID      := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey    := Trim(Req.Headers['X-EasyOne-Key']);
        Contexto  := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);
        //Retorno para retaguarda
        Dados   := TEleicaoService.BuscarStatusIntegracao(Contexto.IdEmpresaAPI);
        
        try
          //Retorno.AddPair('dados',Dados);
          TAppResponse.Ok(res,Dados);
          Dados   := nil;
        finally
          Dados.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

end;

{$ENDREGION}

{$REGION 'Config'}

procedure PreencherEleicaoConfigFromJson(const AJson: TJSONObject; const ADoc: TEleicaoConfigModel);
begin

  ADoc.EleicaoId          := TAppClasses.GetJsonInt(AJson, 'eleicao_id',0);
  ADoc.IdConfig           := TAppClasses.GetJsonInt(AJson, 'id_config',0);
  ADoc.Slug               := TAppClasses.GetJsonString(AJson, 'slug');
  ADoc.NomeExibicao       := TAppClasses.GetJsonString(AJson, 'nome_exibicao');
  ADoc.Logo               := TAppClasses.GetJsonString(AJson, 'logo');
  ADoc.Banner             := TAppClasses.GetJsonString(AJson, 'banner');
  ADoc.MensagemBoasVindas := TAppClasses.GetJsonString(AJson, 'mensagem_boas_vindas');
  ADoc.Url_Publica        := TAppClasses.GetJsonString(AJson, 'url_publica');
  ADoc.Email              := TAppClasses.GetJsonString(AJson, 'email');
  ADoc.Telefone           := TAppClasses.GetJsonString(AJson, 'telefone');
  ADoc.CorPrimaria        := TAppClasses.GetJsonString(AJson, 'cor_primaria');
  ADoc.CorSecundaria      := TAppClasses.GetJsonString(AJson, 'cor_secundaria');
  ADoc.UrlInstagram       := TAppClasses.GetJsonString(AJson, 'url_instagram');
  ADoc.UrlFacebook        := TAppClasses.GetJsonString(AJson, 'url_facebook');
  ADoc.UrlYoutube         := TAppClasses.GetJsonString(AJson, 'url_youtube');
  ADoc.PaginaPublicar     := TAppClasses.GetJsonString(AJson, 'pagina_publicar');
  ADoc.DataHoraInicio     := TAppClasses.GetJsonDateTimeISO(AJson,'data_hora_inicio');
  ADoc.DataHoraFim        := TAppClasses.GetJsonDateTimeISO(AJson,'data_hora_fim');
  Adoc.abertura_automatica     :=TAppClasses.GetJsonString(AJson, 'abertura_automatica','S');
  Adoc.encerramento_automatico :=TAppClasses.GetJsonString(AJson, 'encerramento_automatico','S');

  Adoc.votacao_secreta            :=TAppClasses.GetJsonString(AJson, 'votacao_secreta','N');
  Adoc.exibir_resultado_parcial   :=TAppClasses.GetJsonString(AJson, 'exibir_resultado_parcial','N');
  Adoc.publicacao_resultado       :=TAppClasses.GetJsonString(AJson, 'publicacao_resultado','N');
  Adoc.controlar_quorum           :=TAppClasses.GetJsonString(AJson, 'controlar_quorum','N');
  Adoc.tipo_quorum                :=TAppClasses.GetJsonString(AJson, 'tipo_quorum');
  Adoc.quorum_minimo              :=TAppClasses.GetJsonInt(AJson, 'quorum_minimo',0);
  Adoc.quorum_percentual          :=TAppClasses.GetJsonCurrency(AJson,'quorum_percentual',0);
  Adoc.quorum_base                :=TAppClasses.GetJsonString(AJson, 'quorum_base');
  Adoc.controlar_presenca         :=TAppClasses.GetJsonString(AJson, 'controlar_presenca','N');
  Adoc.exigir_presenca_votacao    :=TAppClasses.GetJsonString(AJson, 'exigir_presenca_votacao','N');


end;

class procedure TEleicaoController.RegistryConfig;
begin

  {$REGION 'Post'}

  THorse.Post('/v1/integracao/eleicaoconfig',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body      : TJSONObject;
      ADoc      : TEleicaoConfigModel;
      Retorno   : TJSONObject;
      Contexto  : TEasyOneIntegracaoContexto;
      UUID      : String;
      APIKey    : String;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);

        Body    := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        ADoc              := TEleicaoConfigModel.Create;
        try
          PreencherEleicaoConfigFromJson(Body, Adoc);
          if TEleicaoService.InserirEleicaoConfig(Contexto.IdEmpresaAPI,Adoc) then
          Retorno           := TJSONObject.Create;
          Retorno.AddPair('', '');

          TAppResponse.Created(Res, Retorno, 'Eleição sincronizada com sucesso.');
        finally
          Adoc.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

end;

{$ENDREGION}

{$REGION 'Chapa'}

procedure PreencherEleicaoChapaFromJson(const AJson: TJSONObject; const ADoc: TEleicaoChapaModel);
begin
  Adoc.EleicaoId        := TAppClasses.GetJsonInt(AJson, 'eleicao_id',0);
  Adoc.id_chapa_int     := TAppClasses.GetJsonInt(AJson, 'id_chapa_int',0);
  Adoc.Codigo           := TAppClasses.GetJsonInt(AJson, 'codigo',0);
  Adoc.Situacao          := TAppClasses.GetJsonString(AJson, 'situacao');
  Adoc.NumChapa         := TAppClasses.GetJsonInt(AJson, 'num_chapa',0);
  Adoc.NomeChapa        := TAppClasses.GetJsonString(AJson, 'nome_chapa');
  Adoc.Slogan           := TAppClasses.GetJsonString(AJson, 'slogan');
  Adoc.Obs              := TAppClasses.GetJsonString(AJson, 'obs');
  Adoc.Ativo            := TAppClasses.GetJsonString(AJson, 'ativo','N');

end;

class procedure TEleicaoController.RegistryChapa;
begin

  {$REGION 'Post'}

  THorse.Post('/v1/integracao/eleicao/chapa',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body      : TJSONObject;
      ADoc      : TEleicaoChapaModel;
      Retorno   : TJSONObject;
      Contexto  : TEasyOneIntegracaoContexto;
      UUID      : String;
      APIKey    : String;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);
        Body    := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        ADoc              := TEleicaoChapaModel.Create;
        try
          PreencherEleicaoChapaFromJson(Body, Adoc);
          if TEleicaoService.InserirEleicaoChapa(Contexto.IdEmpresaAPI,Adoc) then
          Retorno           := TJSONObject.Create;
          Retorno.AddPair('', '');

          TAppResponse.Created(Res, Retorno, 'Chapa sincronizado com sucesso.');
        finally
          Adoc.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

end;


{$ENDREGION}

{$REGION 'Membros'}

procedure PreencherEleicaoChapaMembrosFromJson(const AJson: TJSONObject; const ADoc: TEleicaoChapaMembrosModel);
begin
  Adoc.EleicaoId          := TAppClasses.GetJsonInt(AJson, 'eleicao_id',0);
  Adoc.EleicaoChapaId     := TAppClasses.GetJsonInt(AJson, 'eleicao_chapa_id',0);
  Adoc.id_membro_int      := TAppClasses.GetJsonInt(AJson, 'id_membro_int',0);
  Adoc.Codigo             := TAppClasses.GetJsonInt(AJson, 'codigo',0);
  Adoc.Nome               := TAppClasses.GetJsonString(AJson, 'nome');
  Adoc.Cpf                := TAppClasses.GetJsonString(AJson, 'cpf');
  Adoc.Telefone           := TAppClasses.GetJsonString(AJson, 'telefone');
  Adoc.Email              := TAppClasses.GetJsonString(AJson, 'email');
  Adoc.Ativo              := TAppClasses.GetJsonString(AJson, 'ativo','N');
  Adoc.Cargo              := TAppClasses.GetJsonString(AJson, 'cargo');
  Adoc.Tipo               := TAppClasses.GetJsonString(AJson, 'tipo');
  Adoc.Observacao         := TAppClasses.GetJsonString(AJson, 'observacao');
  Adoc.ArquivoFoto        := TAppClasses.GetJsonString(AJson, 'arquivo_foto');
  Adoc.ExtensaoFoto       := TAppClasses.GetJsonString(AJson, 'extensao_foto');

  //Writeln('chapa id: ' + InttoStr(Adoc.EleicaoChapaId));
end;

class procedure TEleicaoController.RegistryMembros;
begin

  {$REGION 'Post'}

  THorse.Post('/v1/integracao/eleicao/chapa/membros',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body      : TJSONObject;
      ADoc      : TEleicaoChapaMembrosModel;
      Retorno   : TJSONObject;
      Contexto  : TEasyOneIntegracaoContexto;
      UUID      : String;
      APIKey    : String;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);

        Body    := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        ADoc              := TEleicaoChapaMembrosModel.Create;
        try
          PreencherEleicaoChapamembrosFromJson(Body, Adoc);
          if TEleicaoService.InserirEleicaoChapaMembros(Contexto.IdEmpresaAPI,Adoc) then
          Retorno           := TJSONObject.Create;
          Retorno.AddPair('', '');

          TAppResponse.Created(Res, Retorno, 'Membros sincronizado com sucesso.');
        finally
          Adoc.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

end;




{$ENDREGION}

{$REGION 'Questao'}

procedure PreencherEleicaoQuestaoFromJson(const AJson: TJSONObject; const ADoc: TEleicaoQuestaoModel);
begin
  ADoc.id_questao_int       :=TAppClasses.GetJsonInt(AJson, 'xxxxxx',0);
  Adoc.eleicao_id           :=TAppClasses.GetJsonInt(AJson, 'xxxxxx',0);
  Adoc.id_eleicao_int       :=TAppClasses.GetJsonInt(AJson, 'xxxxxx',0);
  Adoc.empresa_id           :=TAppClasses.GetJsonInt(AJson, 'xxxxxx',0);
  Adoc.titulo               :=TAppClasses.GetJsonString(AJson, 'xxxxx');
  Adoc.descricao            :=TAppClasses.GetJsonString(AJson, 'xxxxx');
  Adoc.ordem                :=TAppClasses.GetJsonInt(AJson, 'xxxxxx',0);
  Adoc.tipo_resposta        :=TAppClasses.GetJsonString(AJson, 'xxxxx');
  Adoc.obrigatoria          :=TAppClasses.GetJsonString(AJson, 'xxxxx');
  Adoc.ativo                :=TAppClasses.GetJsonString(AJson, 'xxxxx','N');
end;

class procedure TEleicaoController.RegistryQuestao;
begin

  {$REGION 'Post'}

  THorse.Post('/v1/integracao/eleicao/questao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body      : TJSONObject;
      ADoc      : TEleicaoQuestaoModel;
      Retorno   : TJSONObject;
      Contexto  : TEasyOneIntegracaoContexto;
      UUID      : String;
      APIKey    : String;
    begin
      try
        UUID      := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey    := Trim(Req.Headers['X-EasyOne-Key']);
        Contexto  := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);
        Body      := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        ADoc              := TEleicaoQuestaoModel.Create;

        try

          PreencherEleicaoQuestaoFromJson(Body, Adoc);
          if TEleicaoService.InserirEleicaoQuestao(Contexto.IdEmpresaAPI,Adoc) then
          Retorno           := TJSONObject.Create;
          Retorno.AddPair('', '');

          TAppResponse.Created(Res, Retorno, '[API] Questão sincronizado com sucesso.');
        finally
          Adoc.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}


end;

{$ENDREGION}

end.


