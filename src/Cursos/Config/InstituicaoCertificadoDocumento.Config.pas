unit InstituicaoCertificadoDocumento.Config;

interface

type
  TCertificadoDocumentoConfig = record
    StoragePath: string;
    PublicValidationBaseUrl: string;
    ChromiumExecutable: string;
    ChromiumArgs: string;
  end;

  TInstituicaoCertificadoDocumentoConfig = class
  public
    class function Carregar(const AExigirGerador: Boolean = True): TCertificadoDocumentoConfig; static;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles;

class function TInstituicaoCertificadoDocumentoConfig.Carregar(
  const AExigirGerador: Boolean):
  TCertificadoDocumentoConfig;
var
  Ini: TIniFile;
  Arquivo: string;
  Ambiente: string;
begin
  Result :=
    Default(
      TCertificadoDocumentoConfig
    );

  Arquivo :=
    ExtractFilePath(
      ParamStr(0)
    ) +
    'Config.ini';

  Ini :=
    TIniFile.Create(
      Arquivo
    );

  try
    Ambiente :=
      UpperCase(
        Trim(
          Ini.ReadString(
            'APP',
            'Ambiente',
            'DESENVOLVIMENTO'
          )
        )
      );

    Result.StoragePath :=
      Trim(
        Ini.ReadString(
          'CERTIFICADO_DOCUMENTO',
          'StoragePath',
          ''
        )
      );

    Result.PublicValidationBaseUrl :=
      Trim(
        Ini.ReadString(
          'CERTIFICADO_DOCUMENTO',
          'PublicValidationBaseUrl',
          ''
        )
      );

    Result.ChromiumExecutable :=
      Trim(
        Ini.ReadString(
          'CERTIFICADO_DOCUMENTO',
          'ChromiumExecutable',
          'chromium'
        )
      );

    Result.ChromiumArgs :=
      Trim(
        Ini.ReadString(
          'CERTIFICADO_DOCUMENTO',
          'ChromiumArgs',
          '--headless --disable-gpu --no-pdf-header-footer'
        )
      );

  finally
    Ini.Free;
  end;

  if Result.StoragePath.IsEmpty then
    raise Exception.Create(
      'Configure CERTIFICADO_DOCUMENTO.StoragePath no Config.ini.'
    );

  if not AExigirGerador then Exit;

  if Result.PublicValidationBaseUrl.IsEmpty then
    raise Exception.Create(
      'Configure CERTIFICADO_DOCUMENTO.PublicValidationBaseUrl no Config.ini.'
    );

  if not Result.PublicValidationBaseUrl.ToLower.StartsWith('https://') and
     not Result.PublicValidationBaseUrl.ToLower.StartsWith('http://') then
    raise Exception.Create(
      'CERTIFICADO_DOCUMENTO.PublicValidationBaseUrl deve ser uma URL HTTP ou HTTPS.'
    );

  if SameText(Ambiente, 'PRODUCAO') and
     not Result.PublicValidationBaseUrl.ToLower.StartsWith('https://') then
    raise Exception.Create(
      'CERTIFICADO_DOCUMENTO.PublicValidationBaseUrl deve utilizar HTTPS em PRODUCAO.'
    );

  if Result.ChromiumExecutable.IsEmpty then
    raise Exception.Create('Configure o executável do Chromium.');

end;

end.
