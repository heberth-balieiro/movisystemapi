unit EleicaoResultadoPublicoAPI.Dao;

interface

uses
  Uni, System.Generics.Collections;

type
  TEleicaoResultadoPublicoDados = record
    IdEleicao: Integer;
    IdEmpresa: Integer;
    Nome: string;
    Situacao: string;
  end;

  TEleicaoResultadoPublicoResumo = record
    TotalVotos: Integer;
    VotosValidos: Integer;
    VotosBrancos: Integer;
    VotosNulos: Integer;
  end;

  TEleicaoResultadoPublicoChapa = record
    IdChapa: Integer;
    Numero: Integer;
    Nome: string;
    QuantidadeVotos: Integer;
  end;

  TEleicaoResultadoPublicoLista = TList<TEleicaoResultadoPublicoChapa>;

  TEleicaoResultadoPublicoAPIDao = class
  public
    class function BuscarEleicaoPublicada(const AConn: TUniConnection; const ASlug: string; out AEleicao: TEleicaoResultadoPublicoDados): Boolean; static;
    class function BuscarResumo(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao: Integer; out AResumo: TEleicaoResultadoPublicoResumo): Boolean; static;
    class procedure BuscarChapas(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao: Integer; const ALista: TEleicaoResultadoPublicoLista); static;
  end;

implementation

uses
  System.SysUtils;

class function TEleicaoResultadoPublicoAPIDao.BuscarEleicaoPublicada(const AConn: TUniConnection; const ASlug: string; out AEleicao: TEleicaoResultadoPublicoDados): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AEleicao := Default(TEleicaoResultadoPublicoDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT e.id, e.empresa_id, e.nome, e.situacao ' +
      'FROM eleicao e ' +
      'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id = e.id AND ec.empresa_id = e.empresa_id ' +
      'WHERE LOWER(TRIM(ec.slug)) = LOWER(TRIM(:slug)) ' +
      '  AND ec.pagina_publicar = ''S'' ' +
      '  AND e.ativo = ''S'' ' +
      '  AND e.situacao = ''PUBLICADA'' ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AEleicao.IdEleicao := Qry.FieldByName('id').AsInteger;
    AEleicao.IdEmpresa := Qry.FieldByName('empresa_id').AsInteger;
    AEleicao.Nome := Qry.FieldByName('nome').AsString;
    AEleicao.Situacao := Qry.FieldByName('situacao').AsString;

    Result := True;
  finally
    Qry.Free;
  end;
end;


class function TEleicaoResultadoPublicoAPIDao.BuscarResumo(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao: Integer; out AResumo: TEleicaoResultadoPublicoResumo): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AResumo := Default(TEleicaoResultadoPublicoResumo);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      ' COUNT(*) AS total_votos, ' +
      ' SUM(CASE WHEN tipo_voto = ''CHAPA'' THEN 1 ELSE 0 END) AS votos_validos, ' +
      ' SUM(CASE WHEN tipo_voto = ''BRANCO'' THEN 1 ELSE 0 END) AS votos_brancos, ' +
      ' SUM(CASE WHEN tipo_voto = ''NULO'' THEN 1 ELSE 0 END) AS votos_nulos ' +
      'FROM eleicao_voto ' +
      'WHERE empresa_id = :idempresa AND eleicao_id = :ideleicao';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AResumo.TotalVotos := Qry.FieldByName('total_votos').AsInteger;
    AResumo.VotosValidos := Qry.FieldByName('votos_validos').AsInteger;
    AResumo.VotosBrancos := Qry.FieldByName('votos_brancos').AsInteger;
    AResumo.VotosNulos := Qry.FieldByName('votos_nulos').AsInteger;

    Result := True;
  finally
    Qry.Free;
  end;
end;


class procedure TEleicaoResultadoPublicoAPIDao.BuscarChapas(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao: Integer; const ALista: TEleicaoResultadoPublicoLista);
var
  Qry: TUniQuery;
  Item: TEleicaoResultadoPublicoChapa;
begin
  ALista.Clear;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT c.id, c.num_chapa, c.nome_chapa, COUNT(v.id) AS quantidade_votos ' +
      'FROM eleicao_chapa c ' +
      'LEFT JOIN eleicao_voto v ON v.eleicao_chapa_id = c.id ' +
      ' AND v.empresa_id = c.empresa_id ' +
      ' AND v.eleicao_id = c.eleicao_id ' +
      ' AND v.tipo_voto = ''CHAPA'' ' +
      'WHERE c.empresa_id = :idempresa ' +
      '  AND c.eleicao_id = :ideleicao ' +
      '  AND c.ativo = ''S'' ' +
      'GROUP BY c.id, c.num_chapa, c.nome_chapa ' +
      'ORDER BY quantidade_votos DESC, c.num_chapa';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := Default(TEleicaoResultadoPublicoChapa);
      Item.IdChapa := Qry.FieldByName('id').AsInteger;
      Item.Numero := Qry.FieldByName('num_chapa').AsInteger;
      Item.Nome := Qry.FieldByName('nome_chapa').AsString;
      Item.QuantidadeVotos := Qry.FieldByName('quantidade_votos').AsInteger;

      ALista.Add(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

end.
