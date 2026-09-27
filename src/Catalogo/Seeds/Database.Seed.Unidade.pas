unit Database.Seed.Unidade;

interface

type
  TDatabaseSeedUnidade = class
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection;

function UnidadeExistePorDescricao(const AConn: TUniConnection;const ASigla: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM unidade ' +
      'WHERE LOWER(TRIM(sigla)) = LOWER(TRIM(:sigla))';

    Qry.ParamByName('sigla').AsString := Trim(ASigla);
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

procedure InserirUnidade(const AConn: TUniConnection;const ASigla :string;const ADescricao: string;const AAtivo :String);
var
  Qry: TUniQuery;
begin
  if UnidadeExistePorDescricao(AConn, ASigla) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO unidade (' +
      ' sigla, descricao, ativo' +
      ') VALUES (' +
      ' :sigla, :descricao, :ativo ' +
      ')';
    Qry.ParamByName('sigla').AsString       := Asigla;
    Qry.ParamByName('descricao').AsString   := ADescricao;
    Qry.ParamByName('ativo').AsString       := 'S';

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TDatabaseSeedUnidade.Run;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try

      InserirUnidade(Conn, 'UN', 'Unidade', 'S');
      InserirUnidade(Conn, 'UND', 'Unidade', 'S');
      InserirUnidade(Conn, 'KG', 'Quilograma', 'S');
      InserirUnidade(Conn, 'G', 'Grama', 'S');
      InserirUnidade(Conn, 'MG', 'Miligrama', 'S');
      InserirUnidade(Conn, 'LT', 'Litro', 'S');
      InserirUnidade(Conn, 'ML', 'Mililitro', 'S');
      InserirUnidade(Conn, 'CX', 'Caixa', 'S');
      InserirUnidade(Conn, 'PC', 'Peça', 'S');
      InserirUnidade(Conn, 'PCT', 'Pacote', 'S');
      InserirUnidade(Conn, 'FD', 'Fardo', 'S');
      InserirUnidade(Conn, 'RL',  'Rolo', 'S');
      InserirUnidade(Conn, 'MT',  'Metro', 'S');
      InserirUnidade(Conn, 'M',   'Metro', 'S');
      InserirUnidade(Conn, 'M2',  'Metro quadrado', 'S');
      InserirUnidade(Conn, 'M3',  'Metro cúbico', 'S');
      InserirUnidade(Conn, 'CM',  'Centímetro', 'S');
      InserirUnidade(Conn, 'MM',  'Milímetro', 'S');
      InserirUnidade(Conn, 'PAR', 'Par', 'S');
      InserirUnidade(Conn, 'JG',  'Jogo', 'S');
      InserirUnidade(Conn, 'KIT', 'Kit', 'S');
      InserirUnidade(Conn, 'SC',  'Saco', 'S');
      InserirUnidade(Conn, 'BD',  'Balde', 'S');
      InserirUnidade(Conn, 'GL',  'Galão', 'S');
      InserirUnidade(Conn, 'FR',  'Frasco', 'S');
      InserirUnidade(Conn, 'TB',  'Tubo', 'S');
      InserirUnidade(Conn, 'BR',  'Barra', 'S');
      InserirUnidade(Conn, 'CH',  'Chapa', 'S');
      InserirUnidade(Conn, 'AMP', 'Ampola', 'S');
      InserirUnidade(Conn, 'DIA', 'Diária', 'S');
      InserirUnidade(Conn, 'HR',  'Hora', 'S');
      InserirUnidade(Conn, 'MES', 'Mês', 'S');
      InserirUnidade(Conn, 'TON', 'Tonelada', 'S');


      Conn.Commit;

      Writeln('Seed Unidade executado com sucesso.');
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

end.
