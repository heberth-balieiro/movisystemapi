unit EleicaoVotacaoAPI.Dao;

interface

uses
  Uni;

type
  TEleicaoVotacaoAPIDao = class
  public
    class function EleitorJaVotou(
      const AConn: TUniConnection;
      const AIdEleicao: Integer;
      const AIdUsuario: Integer
    ): Boolean; static;

    class function ChapaValida(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdChapa: Integer
    ): Boolean; static;

    class procedure RegistrarVoto(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdChapa: Integer;
      const ATipoVoto: string;
      const AComprovanteHash: string
    ); static;

    class procedure RegistrarVotante(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdUsuario: Integer
    ); static;
  end;

implementation

uses
  System.SysUtils,
  DB;

{ TEleicaoVotacaoAPIDao }

class function TEleicaoVotacaoAPIDao.EleitorJaVotou(
  const AConn: TUniConnection;
  const AIdEleicao: Integer;
  const AIdUsuario: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM eleicao_votante ' +
      'WHERE eleicao_id = :ideleicao ' +
      '  AND usuario_id = :idusuario ' +
      '  AND votou = ''S'' ' +
      'LIMIT 1';

    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idusuario').AsInteger := AIdUsuario;

    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoVotacaoAPIDao.ChapaValida(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdChapa: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM eleicao_chapa ' +
      'WHERE id = :idchapa ' +
      '  AND empresa_id = :idempresa ' +
      '  AND eleicao_id = :ideleicao ' +
      '  AND ativo = ''S'' ' +
      'LIMIT 1';

    Qry.ParamByName('idchapa').AsInteger := AIdChapa;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;

    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoVotacaoAPIDao.RegistrarVoto(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdChapa: Integer;
  const ATipoVoto: string;
  const AComprovanteHash: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO eleicao_voto (' +
      '  empresa_id, ' +
      '  eleicao_id, ' +
      '  eleicao_chapa_id, ' +
      '  tipo_voto, ' +
      '  comprovante_hash ' +
      ') VALUES (' +
      '  :idempresa, ' +
      '  :ideleicao, ' +
      '  :idchapa, ' +
      '  :tipovoto, ' +
      '  :comprovantehash ' +
      ')';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;

    if SameText(ATipoVoto, 'CHAPA') then
      Qry.ParamByName('idchapa').AsInteger := AIdChapa
    else
    begin
      Qry.ParamByName('idchapa').DataType := ftLargeint;
      Qry.ParamByName('idchapa').Clear;
    end;

    Qry.ParamByName('tipovoto').AsString :=
      UpperCase(Trim(ATipoVoto));

    if Trim(AComprovanteHash) <> '' then
      Qry.ParamByName('comprovantehash').AsString :=
        AComprovanteHash
    else
    begin
      Qry.ParamByName('comprovantehash').DataType := ftString;
      Qry.ParamByName('comprovantehash').Clear;
    end;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoVotacaoAPIDao.RegistrarVotante(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdUsuario: Integer
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO eleicao_votante (' +
      '  empresa_id, ' +
      '  eleicao_id, ' +
      '  usuario_id, ' +
      '  votou ' +
      ') VALUES (' +
      '  :idempresa, ' +
      '  :ideleicao, ' +
      '  :idusuario, ' +
      '  ''S'' ' +
      ')';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idusuario').AsInteger := AIdUsuario;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
