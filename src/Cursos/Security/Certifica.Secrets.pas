unit Certifica.Secrets;

interface

type
  TCertificaSecrets = class
  public
    class function WhatsAppTokenSecret: string; static;
    class function EmailSmtpSecret: string; static;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles;

class function TCertificaSecrets.WhatsAppTokenSecret: string;
var
  Ini: TIniFile;
  IniPath: string;
begin
  IniPath := ExtractFilePath(ParamStr(0)) + 'Config.ini';

  Ini := TIniFile.Create(IniPath);
  try
    Result := Trim(
      Ini.ReadString(
        'SECURITY',
        'WhatsAppTokenSecret',
        ''
      )
    );
  finally
    Ini.Free;
  end;

  if Length(Result) < 32 then
    raise Exception.Create(
      'Configure SECURITY/WhatsAppTokenSecret com no minimo 32 caracteres.'
    );
end;


class function TCertificaSecrets.EmailSmtpSecret: string;
var
  Ini: TIniFile;
  IniPath: string;
begin
  IniPath := ExtractFilePath(ParamStr(0)) + 'Config.ini';

  Ini := TIniFile.Create(IniPath);
  try
    Result := Trim(
      Ini.ReadString(
        'SECURITY',
        'EmailSmtpSecret',
        ''
      )
    );
  finally
    Ini.Free;
  end;

  if Length(Result) < 32 then
    raise Exception.Create(
      'Configure SECURITY/EmailSmtpSecret com no minimo 32 caracteres.'
    );
end;

end.
