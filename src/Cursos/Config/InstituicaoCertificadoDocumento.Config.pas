unit InstituicaoCertificadoDocumento.Config;

interface

type
  TCertificadoDocumentoConfig = record
    StoragePath: string;
    PublicValidationBaseUrl: string;
    QrEncodeExecutable: string;
    ChromiumExecutable: string;
    ChromiumArgs: string;
  end;

  TInstituicaoCertificadoDocumentoConfig = class
  public
    class function Carregar: TCertificadoDocumentoConfig; static;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles;

class function TInstituicaoCertificadoDocumentoConfig.Carregar:
  TCertificadoDocumentoConfig;
var
  Ini: TIniFile;
  Arquivo: string;
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

    Result.QrEncodeExecutable :=
      Trim(
        Ini.ReadString(
          'CERTIFICADO_DOCUMENTO',
          'QrEncodeExecutable',
          'qrencode'
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

  if Result.PublicValidationBaseUrl.IsEmpty then
    raise Exception.Create(
      'Configure CERTIFICADO_DOCUMENTO.PublicValidationBaseUrl no Config.ini.'
    );
end;

end.
