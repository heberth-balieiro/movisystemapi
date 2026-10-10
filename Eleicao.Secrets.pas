unit Eleicao.Secrets;

interface

type
  TEleicaoSecrets = class
  public
    class function EmailSmtpSecret: string; static;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles;

class function TEleicaoSecrets.EmailSmtpSecret: string;
var
  Ini: TIniFile;
  IniPath: string;
begin
  IniPath := ExtractFilePath(ParamStr(0)) + 'Config.ini';

  Ini := TIniFile.Create(IniPath);
  try
    Result := Trim(Ini.ReadString('SECURITY', 'EleicaoEmailSmtpSecret', ''));

    // Compatibilidade com ambientes que já utilizam o segredo SMTP do Certifica.
    if Result.IsEmpty then
      Result := Trim(Ini.ReadString('SECURITY', 'EmailSmtpSecret', ''));
  finally
    Ini.Free;
  end;

  if Length(Result) < 32 then
    raise Exception.Create(
      'Configure SECURITY/EleicaoEmailSmtpSecret com no minimo 32 caracteres.'
    );
end;

end.
