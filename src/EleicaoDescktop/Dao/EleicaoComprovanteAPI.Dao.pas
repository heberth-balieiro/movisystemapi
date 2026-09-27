unit EleicaoComprovanteAPI.Dao;

interface

uses
  Uni;

type
  TEleicaoComprovante = record
    IdEleicao: Integer;
    NomeEleicao: string;
    Comprovante: string;
    RegistradoEm: TDateTime;
  end;

  TEleicaoComprovanteAPIDao = class
  public
    class function BuscarComprovante(
      const AConn: TUniConnection;
      const ASlug: string;
      const AComprovante: string;
      out AResultado: TEleicaoComprovante
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

class function TEleicaoComprovanteAPIDao.BuscarComprovante(
  const AConn: TUniConnection;
  const ASlug: string;
  const AComprovante: string;
  out AResultado: TEleicaoComprovante
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AResultado := Default(TEleicaoComprovante);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      '  e.id AS id_eleicao, ' +
      '  e.nome AS nome_eleicao, ' +
      '  v.comprovante_hash, ' +
      '  v.criado_em ' +
      'FROM eleicao_voto v ' +
      'INNER JOIN eleicao e ON ' +
      '  e.id = v.eleicao_id ' +
      '  AND e.empresa_id = v.empresa_id ' +
      'INNER JOIN eleicao_configuracao ec ON ' +
      '  ec.eleicao_id = e.id ' +
      '  AND ec.empresa_id = e.empresa_id ' +
      'WHERE LOWER(TRIM(ec.slug)) = LOWER(TRIM(:slug)) ' +
      '  AND v.comprovante_hash = :comprovante ' +
      '  AND ec.pagina_publicar = ''S'' ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString :=
      Trim(ASlug);

    Qry.ParamByName('comprovante').AsString :=
      Trim(AComprovante);

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AResultado.IdEleicao :=
      Qry.FieldByName('id_eleicao').AsInteger;

    AResultado.NomeEleicao :=
      Qry.FieldByName('nome_eleicao').AsString;

    AResultado.Comprovante :=
      Qry.FieldByName('comprovante_hash').AsString;

    AResultado.RegistradoEm :=
      Qry.FieldByName('criado_em').AsDateTime;

    Result := True;

  finally
    Qry.Free;
  end;
end;

end.
