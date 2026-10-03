unit App.TextEncoding;


interface

type
  TAppTextEncoding = class
  public
    class function NormalizarUtf8Legado(
      const AValor: string
    ): string; static;
  end;

implementation

uses
  System.SysUtils;

class function TAppTextEncoding.NormalizarUtf8Legado(
  const AValor: string
): string;
begin
  Result := AValor;

  if Result.IsEmpty then
    Exit;

  Result := StringReplace(Result, 'Ã£', 'ã', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ãµ', 'õ', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ã¡', 'á', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ã©', 'é', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ã­', 'í', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ã³', 'ó', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ãº', 'ú', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ã§', 'ç', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ã¢', 'â', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ãª', 'ê', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ã´', 'ô', [rfReplaceAll]);

  Result := StringReplace(Result, 'Ãƒ', 'Ã', [rfReplaceAll]);
  Result := StringReplace(Result, 'Âº', 'º', [rfReplaceAll]);
  Result := StringReplace(Result, 'Âª', 'ª', [rfReplaceAll]);
  Result := StringReplace(Result, 'Â°', '°', [rfReplaceAll]);
end;

end.
