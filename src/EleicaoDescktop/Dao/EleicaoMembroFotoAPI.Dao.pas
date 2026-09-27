unit EleicaoMembroFotoAPI.Dao;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Uni;

type
  TEleicaoMembroFotoAPIDao = class
  public
    class function BuscarFoto(const AConn: TUniConnection; const ASlug: string; const AIdMembro: Integer; out AArquivo: TBytes; out AExtensao: string): Boolean; static;
  end;

implementation

{ TEleicaoMembroFotoAPIDao }

class function TEleicaoMembroFotoAPIDao.BuscarFoto(const AConn: TUniConnection; const ASlug: string; const AIdMembro: Integer; out AArquivo: TBytes; out AExtensao: string): Boolean;
var
  Qry   : TUniQuery;
  Stream: TMemoryStream;
begin
  Result := False;
  AArquivo := nil;
  AExtensao := '';

  if (AConn = nil) or Trim(ASlug).IsEmpty or (AIdMembro <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT m.arquivo_foto, m.extensao_foto ' +
      'FROM eleicao_chapa_membros m ' +
      'INNER JOIN eleicao_chapa c ON c.id = m.eleicao_chapa_id ' +
      ' AND c.eleicao_id = m.eleicao_id ' +
      ' AND c.empresa_id = m.empresa_id ' +
      'INNER JOIN eleicao e ON e.id = m.eleicao_id ' +
      ' AND e.empresa_id = m.empresa_id ' +
      'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id = e.id ' +
      ' AND ec.empresa_id = e.empresa_id ' +
      'WHERE LOWER(TRIM(ec.slug)) = LOWER(TRIM(:slug)) ' +
      ' AND m.id = :idmembro ' +
      ' AND m.ativo = ''S'' ' +
      ' AND c.ativo = ''S'' ' +
      ' AND e.ativo = ''S'' ' +
      ' AND ec.pagina_publicar = ''S'' ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.ParamByName('idmembro').AsInteger := AIdMembro;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    if Qry.FieldByName('arquivo_foto').IsNull then
      Exit;

    Stream := TMemoryStream.Create;
    try
      TBlobField(Qry.FieldByName('arquivo_foto')).SaveToStream(Stream);

      if Stream.Size <= 0 then
        Exit;

      SetLength(AArquivo, Stream.Size);
      Stream.Position := 0;
      Stream.ReadBuffer(AArquivo[0], Stream.Size);
    finally
      Stream.Free;
    end;

    AExtensao := UpperCase(Trim(Qry.FieldByName('extensao_foto').AsString));

    Result := Length(AArquivo) > 0;
  finally
    Qry.Free;
  end;
end;

end.
