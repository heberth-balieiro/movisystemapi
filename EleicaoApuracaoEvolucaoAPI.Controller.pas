unit EleicaoApuracaoEvolucaoAPI.Controller;

interface

type
  TEleicaoApuracaoEvolucaoAPIController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  Uni,
  App.Config,
  App.Errors,
  App.Response,
  App.Token,
  App.JWT,
  Database.Connection;

class procedure TEleicaoApuracaoEvolucaoAPIController.Registry;
begin
  THorse.Get(
    '/api/v1/eleicao/:slug/admin/evolucao-apuracao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug: string;
      Config: TAppApiConfig;
      Conn: TUniConnection;
      Qry: TUniQuery;
      IdEleicao: Integer;
      Situacao: string;
      Dados: TJSONObject;
      Lista: TJSONArray;
      Item: TJSONObject;
      ApuracaoDisponivel: Boolean;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Slug := Trim(Req.Params['slug']);
        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');

        if not TAppToken.PodeAdministrarEleicao(Claims.Roles) then
          TAppErrors.RaiseUnauthorized('Usuário não autorizado.');

        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

        Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
        Conn := TDatabaseConnection.NewConnection(Config.Database);
        try
          Qry := TUniQuery.Create(nil);
          try
            Qry.Connection := Conn;
            Qry.SQL.Text :=
              'SELECT e.id, e.situacao ' +
              'FROM eleicao e ' +
              'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id = e.id AND ec.empresa_id = e.empresa_id ' +
              'WHERE e.empresa_id = :idempresa ' +
              '  AND LOWER(TRIM(ec.slug)) = LOWER(TRIM(:slug)) ' +
              '  AND e.ativo = ''S'' ' +
              'LIMIT 1';
            Qry.ParamByName('idempresa').AsInteger := Claims.IdEmpresa;
            Qry.ParamByName('slug').AsString := Slug;
            Qry.Open;

            if Qry.IsEmpty then
              TAppErrors.RaiseNotFound('Eleição não encontrada.');

            IdEleicao := Qry.FieldByName('id').AsInteger;
            Situacao := Qry.FieldByName('situacao').AsString;

            ApuracaoDisponivel :=
              SameText(Situacao, 'EM_APURACAO') or
              SameText(Situacao, 'APURADA') or
              SameText(Situacao, 'PUBLICADA');

            Dados := TJSONObject.Create;
            Lista := TJSONArray.Create;
            Dados.AddPair('situacao', Situacao);
            Dados.AddPair('apuracao_disponivel', TJSONBool.Create(ApuracaoDisponivel));
            Dados.AddPair('itens', Lista);

            if not ApuracaoDisponivel then
            begin
              TAppResponse.Ok(Res, Dados, '');
              Exit;
            end;

            Qry.Close;
            Qry.SQL.Text :=
              'SELECT ' +
              '  DATE_FORMAT(v.criado_em, ''%H:00'') AS hora, ' +
              '  c.id AS id_chapa, ' +
              '  c.num_chapa AS numero, ' +
              '  c.nome_chapa AS nome, ' +
              '  COUNT(v.id) AS quantidade_hora ' +
              'FROM eleicao_voto v ' +
              'INNER JOIN eleicao_chapa c ON c.id = v.eleicao_chapa_id ' +
              '  AND c.empresa_id = v.empresa_id ' +
              '  AND c.eleicao_id = v.eleicao_id ' +
              'WHERE v.empresa_id = :idempresa ' +
              '  AND v.eleicao_id = :ideleicao ' +
              '  AND v.tipo_voto = ''CHAPA'' ' +
              'GROUP BY DATE_FORMAT(v.criado_em, ''%H:00''), c.id, c.num_chapa, c.nome_chapa ' +
              'ORDER BY DATE_FORMAT(v.criado_em, ''%H:00''), c.num_chapa';
            Qry.ParamByName('idempresa').AsInteger := Claims.IdEmpresa;
            Qry.ParamByName('ideleicao').AsInteger := IdEleicao;
            Qry.Open;

            while not Qry.Eof do
            begin
              Item := TJSONObject.Create;
              Item.AddPair('hora', Qry.FieldByName('hora').AsString);
              Item.AddPair('id_chapa', TJSONNumber.Create(Qry.FieldByName('id_chapa').AsInteger));
              Item.AddPair('numero', TJSONNumber.Create(Qry.FieldByName('numero').AsInteger));
              Item.AddPair('nome', Qry.FieldByName('nome').AsString);
              Item.AddPair('quantidade_hora', TJSONNumber.Create(Qry.FieldByName('quantidade_hora').AsInteger));
              Lista.AddElement(Item);
              Qry.Next;
            end;

            TAppResponse.Ok(Res, Dados, '');
          finally
            Qry.Free;
          end;
        finally
          Conn.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
