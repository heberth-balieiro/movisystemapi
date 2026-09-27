unit PublicoInstituicao.Controller;

interface

type
  TPublicoInstituicaoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Response,
  APP.Errors,
  PublicoInstituicao.Model,
  PublicoInstituicao.Service;

function NullableString(const AValue: string): TJSONValue;
begin
  if Trim(AValue) = '' then
    Result := TJSONNull.Create
  else
    Result := TJSONString.Create(AValue);
end;

function ISODateTime(const AValue: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', AValue);
end;

function InstituicaoJson(const AItem: TPublicoInstituicao): TJSONObject;
var
  Tema: TJSONObject;
begin
  Tema := TJSONObject.Create;
  Tema.AddPair('nome_exibicao', AItem.NomeExibicao);
  Tema.AddPair('logo_url', NullableString(AItem.LogoUrl));
  Tema.AddPair('favicon_url', NullableString(AItem.FaviconUrl));
  Tema.AddPair('imagem_login_url', NullableString(AItem.ImagemLoginUrl));
  Tema.AddPair('cor_primaria', AItem.CorPrimaria);
  Tema.AddPair('cor_secundaria', AItem.CorSecundaria);
  Tema.AddPair('cor_destaque', AItem.CorDestaque);
  Tema.AddPair('cor_fundo', AItem.CorFundo);
  Tema.AddPair('cor_texto', AItem.CorTexto);

  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  Result.AddPair('slug', AItem.Slug);
  Result.AddPair('nome', AItem.Nome);
  Result.AddPair('razao_social', AItem.RazaoSocial);
  Result.AddPair('cnpj', NullableString(AItem.Cnpj));
  Result.AddPair('descricao', AItem.Descricao);
  Result.AddPair('email', AItem.Email);
  Result.AddPair('telefone', AItem.Telefone);
  Result.AddPair('site', NullableString(AItem.Site));
  Result.AddPair('tema', Tema);
end;

function CursoJson(const AItem: TPublicoCurso): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_turma', TJSONNumber.Create(AItem.IdTurma));
  Result.AddPair('codigo_turma', AItem.CodigoTurma);
  Result.AddPair('turma_nome', AItem.TurmaNome);
  Result.AddPair('id_curso', TJSONNumber.Create(AItem.IdCurso));
  Result.AddPair('codigo_curso', AItem.CodigoCurso);
  Result.AddPair('curso_nome', AItem.CursoNome);
  Result.AddPair('curso_descricao', AItem.CursoDescricao);
  Result.AddPair('modalidade', AItem.Modalidade);
  Result.AddPair('imagem_url', NullableString(AItem.ImagemUrl));
  Result.AddPair('data_hora_inicio', ISODateTime(AItem.DataHoraInicio));
  Result.AddPair('data_hora_fim', ISODateTime(AItem.DataHoraFim));

  if AItem.TemInscricaoFim then
    Result.AddPair('inscricao_fim', ISODateTime(AItem.InscricaoFim))
  else
    Result.AddPair('inscricao_fim', TJSONNull.Create);

  if AItem.TemLimiteParticipantes then
    Result.AddPair('limite_participantes', TJSONNumber.Create(AItem.LimiteParticipantes))
  else
    Result.AddPair('limite_participantes', TJSONNull.Create);

  Result.AddPair('inscritos_confirmados', TJSONNumber.Create(AItem.InscritosConfirmados));

  if AItem.TemVagasDisponiveis then
    Result.AddPair('vagas_disponiveis', TJSONNumber.Create(AItem.VagasDisponiveis))
  else
    Result.AddPair('vagas_disponiveis', TJSONNull.Create);

  Result.AddPair('local', NullableString(AItem.Local));
  Result.AddPair('carga_horaria_minutos', TJSONNumber.Create(AItem.CargaHorariaMinutos));
end;

class procedure TPublicoInstituicaoController.Registry;
begin
  THorse.Get(
    '/v1/certifica/publico/instituicoes/:slug',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Item: TPublicoInstituicao;
    begin
      try
        Item := TPublicoInstituicaoService.BuscarPorSlug(Req.Params.Items['slug']);
        try
          TAppResponse.Ok(Res, InstituicaoJson(Item), 'Instituição carregada com sucesso.');
        finally
          Item.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/publico/instituicoes/:slug/cursos-disponiveis',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Lista: TPublicoCursoLista;
      Item: TPublicoCurso;
      Arr: TJSONArray;
      Dados, Paginacao: TJSONObject;
      TotalPaginas: Integer;
    begin
      try
        Lista := TPublicoInstituicaoService.ListarCursosDisponiveis(
          Req.Params.Items['slug'],
          StrToIntDef(Req.Query.Items['page'], 1),
          StrToIntDef(Req.Query.Items['page_size'], 6)
        );
        try
          Arr := TJSONArray.Create;
          for Item in Lista.Itens do
            Arr.AddElement(CursoJson(Item));

          if Lista.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas := (Lista.Total + Lista.PorPagina - 1) div Lista.PorPagina;

          Paginacao := TJSONObject.Create;
          Paginacao.AddPair('pagina', TJSONNumber.Create(Lista.Pagina));
          Paginacao.AddPair('por_pagina', TJSONNumber.Create(Lista.PorPagina));
          Paginacao.AddPair('total', TJSONNumber.Create(Lista.Total));
          Paginacao.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', Arr);
          Dados.AddPair('paginacao', Paginacao);

          TAppResponse.Ok(Res, Dados, 'Cursos públicos carregados com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
