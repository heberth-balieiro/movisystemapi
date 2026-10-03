unit Contratos.Seeds;

interface

type
  TContratosSeeds = class
  private
    class procedure GarantirPermissao(const AConn: TObject; const ACodigo, ADescricao: string); static;
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection,
  InstituicaoPermissao.DAO;

class procedure TContratosSeeds.GarantirPermissao(const AConn: TObject; const ACodigo, ADescricao: string);
var
  Conn: TUniConnection;
  Qry: TUniQuery;
begin
  Conn := TUniConnection(AConn);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := Conn;
    Qry.SQL.Text :=
      'INSERT INTO permissao(codigo,modulo,descricao,situacao) ' +
      'VALUES(:codigo,''CONTRATOS'',:descricao,''ATIVA'') ' +
      'ON DUPLICATE KEY UPDATE modulo=''CONTRATOS'',descricao=VALUES(descricao),situacao=''ATIVA''';
    Qry.ParamByName('codigo').AsString := LowerCase(Trim(ACodigo));
    Qry.ParamByName('descricao').AsString := ADescricao;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TContratosSeeds.Run;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      GarantirPermissao(Conn, 'contrato.visualizar', 'Visualizar contratos.');
      GarantirPermissao(Conn, 'contrato.cadastrar', 'Cadastrar contratos.');
      GarantirPermissao(Conn, 'contrato.editar', 'Editar contratos.');
      GarantirPermissao(Conn, 'contrato.encerrar', 'Encerrar contratos.');
      GarantirPermissao(Conn, 'contrato.cancelar', 'Cancelar contratos.');
      GarantirPermissao(Conn, 'contrato.visualizar_valores', 'Visualizar valores contratuais.');
      GarantirPermissao(Conn, 'contrato.documento.gerenciar', 'Gerenciar documentos dos contratos.');
      GarantirPermissao(Conn, 'contrato.aditivo.gerenciar', 'Gerenciar aditivos dos contratos.');
      GarantirPermissao(Conn, 'contrato.fiscalizacao.gerenciar', 'Gerenciar fiscalizacao contratual.');
      GarantirPermissao(Conn, 'contrato.projecao.visualizar', 'Visualizar projecoes contratuais.');
      GarantirPermissao(Conn, 'contrato.projecao.editar', 'Editar projecoes contratuais.');
      GarantirPermissao(Conn, 'contrato.relatorio.visualizar', 'Visualizar relatorios de contratos.');

      TInstituicaoPermissaoDAO.GarantirPerfisAdministradores(Conn);
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

end.
