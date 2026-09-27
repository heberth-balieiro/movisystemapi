unit Database.Seed.Segmento;

interface

type
  TDatabaseSeedSegmento = class
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection;

function SegmentoExistePorDescricao(const AConn: TUniConnection;const ASigla: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM segmento ' +
      'WHERE LOWER(TRIM(nome)) = LOWER(TRIM(:nome))';

    Qry.ParamByName('nome').AsString := Trim(ASigla);
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

procedure InserirSegmento(const AConn: TUniConnection;const ASigla :string;const ADescricao: string;const AAtivo :String; Const AOrdem:integer);
var
  Qry: TUniQuery;
begin
  if SegmentoExistePorDescricao(AConn, ASigla) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO segmento (nome, descricao, ativo, ordem)'+
      ' VALUES (:nome, :descricao, :ativo, :ordem)';

    Qry.ParamByName('nome').AsString        := Asigla;
    Qry.ParamByName('descricao').AsString   := ADescricao;
    Qry.ParamByName('ativo').AsString       := 'S';
    Qry.ParamByName('ordem').AsInteger      := AOrdem;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TDatabaseSeedSegmento.Run;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try

      InserirSegmento(Conn, 'Acessórios', 'Catálogo para acessórios, bijuterias, joias e semijoias.', 'S', 1);
      InserirSegmento(Conn, 'Moda e Vestuário', 'Catálogo para roupas, calçados e moda em geral.', 'S', 2);
      InserirSegmento(Conn, 'Alimentos', 'Catálogo para restaurantes, lanchonetes, marmitas e alimentos.', 'S', 3);
      InserirSegmento(Conn, 'Ferramentas', 'Catálogo para ferramentas, peças e materiais de construção.', 'S', 4);
      InserirSegmento(Conn, 'Serviços', 'Catálogo para empresas prestadoras de serviço.', 'S', 5);

      Conn.Commit;

      Writeln('Seed Segmento executado com sucesso.');
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

end.
