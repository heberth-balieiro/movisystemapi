unit PlataformaContatoRelatorio.Controller;

interface

type
  TPlataformaContatoRelatorioController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaContatoRelatorio.Model,
  PlataformaContatoRelatorio.Service;

function AutorizarSuperAdmin(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if not TAppToken.PossuiRole(AClaims.Roles, 'SUPER_ADMIN') then
  begin
    TAppResponse.Forbidden(
      Res,
      'Sem permissão para visualizar relatórios de contatos.'
    );
    Exit;
  end;

  Result := True;
end;

function QueryFlag(const S: string): Integer;
begin
  if Trim(S).IsEmpty then
    Exit(-1);

  if SameText(Trim(S), '1') or
     SameText(Trim(S), 'true') or
     SameText(Trim(S), 'sim') then
    Exit(1);

  if SameText(Trim(S), '0') or
     SameText(Trim(S), 'false') or
     SameText(Trim(S), 'nao') then
    Exit(0);

  Result := -1;
end;

function LerFiltro(
  const Req: THorseRequest
): TPlataformaContatoRelatorioFiltro;
begin
  Result := Default(TPlataformaContatoRelatorioFiltro);
  Result.Tipo := Req.Query.Items['tipo'];
  Result.UF := Req.Query.Items['uf'];
  Result.Municipio := Req.Query.Items['municipio'];
  Result.Partido := Req.Query.Items['partido'];
  Result.Situacao := Req.Query.Items['situacao'];
  Result.EmExercicio := QueryFlag(Req.Query.Items['em_exercicio']);
  Result.TemEmail := QueryFlag(Req.Query.Items['tem_email']);
end;

procedure AddNullable(
  const AObj: TJSONObject;
  const ANome, AValor: string
);
begin
  if Trim(AValor).IsEmpty then
    AObj.AddPair(ANome, TJSONNull.Create)
  else
    AObj.AddPair(ANome, AValor);
end;

function ItemParaJson(
  const AItem: TPlataformaContatoRelatorioItem
): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  AddNullable(Result, 'documento', AItem.Documento);
  AddNullable(Result, 'razao_social', AItem.RazaoSocial);
  AddNullable(Result, 'nome_fantasia', AItem.NomeFantasia);
  AddNullable(Result, 'responsavel', AItem.Responsavel);
  AddNullable(Result, 'telefone', AItem.Telefone);
  AddNullable(Result, 'email', AItem.Email);
  AddNullable(Result, 'grau', AItem.Grau);
  AddNullable(Result, 'cidade', AItem.Cidade);
  AddNullable(Result, 'uf', AItem.UF);
  AddNullable(Result, 'orgao', AItem.Orgao);
  AddNullable(Result, 'site', AItem.Site);
  AddNullable(Result, 'fonte', AItem.Fonte);
  AddNullable(Result, 'data_coleta', AItem.DataColeta);
  AddNullable(Result, 'cargo', AItem.Cargo);
  AddNullable(Result, 'partido', AItem.Partido);
  AddNullable(Result, 'id_externo', AItem.IdExterno);
  AddNullable(Result, 'fonte_dados', AItem.FonteDados);
  AddNullable(Result, 'url_perfil', AItem.UrlPerfil);
  Result.AddPair(
    'unale_associado',
    TJSONBool.Create(AItem.UnaleAssociado)
  );
  Result.AddPair(
    'em_exercicio',
    TJSONBool.Create(AItem.EmExercicio)
  );
  Result.AddPair('situacao', AItem.Situacao);
end;

class procedure TPlataformaContatoRelatorioController.Registry;
begin
  THorse.Get(
    '/v1/certifica/plataforma/relatorios/contatos',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtro: TPlataformaContatoRelatorioFiltro;
      Resultado: TPlataformaContatoRelatorioResultado;
      Item: TPlataformaContatoRelatorioItem;
      Dados, Filtros: TJSONObject;
      Itens: TJSONArray;
    begin
      Res.RawWebResponse.SetCustomHeader(
        'Cache-Control',
        'private, no-store'
      );

      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Filtro := LerFiltro(Req);
        Resultado := TPlataformaContatoRelatorioService.Listar(
          Claims.UserId,
          Filtro,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req)
        );
        try
          Itens := TJSONArray.Create;
          for Item in Resultado.Itens do
            Itens.AddElement(ItemParaJson(Item));

          Filtros := TJSONObject.Create;
          Filtros.AddPair('tipo', UpperCase(Trim(Filtro.Tipo)));
          AddNullable(Filtros, 'uf', UpperCase(Trim(Filtro.UF)));
          AddNullable(Filtros, 'municipio', Trim(Filtro.Municipio));
          AddNullable(Filtros, 'partido', UpperCase(Trim(Filtro.Partido)));
          AddNullable(Filtros, 'situacao', UpperCase(Trim(Filtro.Situacao)));

          Dados := TJSONObject.Create;
          Dados.AddPair('tipo', UpperCase(Trim(Filtro.Tipo)));
          Dados.AddPair('total', TJSONNumber.Create(Resultado.Total));
          Dados.AddPair('limite', TJSONNumber.Create(Resultado.Limite));
          Dados.AddPair('filtros', Filtros);
          Dados.AddPair('itens', Itens);

          TAppResponse.Ok(
            Res,
            Dados,
            'Relatório de contatos carregado com sucesso.'
          );
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
