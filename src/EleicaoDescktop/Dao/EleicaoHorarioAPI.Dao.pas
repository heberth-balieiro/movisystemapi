unit EleicaoHorarioAPI.Dao;

interface

uses
  Uni;

type
  TEleicaoHorario = record
    IdEleicao: Integer;
    Situacao: string;
    DataHoraInicio: TDateTime;
    DataHoraFim: TDateTime;
    DataHoraAtual: TDateTime;
    TemInicio: Boolean;
    TemFim: Boolean;
  end;

  TEleicaoHorarioAPIDao = class
  public
    class function BuscarHorario(const AConn: TUniConnection; const ASlug: string; const AIdEmpresa: Integer; out AHorario: TEleicaoHorario): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

class function TEleicaoHorarioAPIDao.BuscarHorario(
  const AConn: TUniConnection;
  const ASlug: string;
  const AIdEmpresa: Integer;
  out AHorario: TEleicaoHorario
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AHorario := Default(TEleicaoHorario);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT e.id, e.situacao, ec.data_hora_inicio, ec.data_hora_fim, NOW() AS data_hora_atual ' +
      'FROM eleicao e ' +
      'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id = e.id AND ec.empresa_id = e.empresa_id ' +
      'WHERE LOWER(TRIM(ec.slug)) = LOWER(TRIM(:slug)) ' +
      '  AND e.empresa_id = :idempresa ' +
      '  AND e.ativo = ''S'' ' +
      '  AND ec.pagina_publicar = ''S'' ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AHorario.IdEleicao := Qry.FieldByName('id').AsInteger;
    AHorario.Situacao := Qry.FieldByName('situacao').AsString;

    AHorario.TemInicio := not Qry.FieldByName('data_hora_inicio').IsNull;
    AHorario.TemFim := not Qry.FieldByName('data_hora_fim').IsNull;

    if AHorario.TemInicio then
      AHorario.DataHoraInicio := Qry.FieldByName('data_hora_inicio').AsDateTime;

    if AHorario.TemFim then
      AHorario.DataHoraFim := Qry.FieldByName('data_hora_fim').AsDateTime;

    AHorario.DataHoraAtual := Qry.FieldByName('data_hora_atual').AsDateTime;

    Result := True;
  finally
    Qry.Free;
  end;
end;

end.
