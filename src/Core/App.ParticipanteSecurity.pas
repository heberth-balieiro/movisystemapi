unit App.ParticipanteSecurity;

interface

type
  TParticipanteSecurity = class
  public
    class function NormalizarCpf(const ACpf: string): string; static;
    class function CpfValido(const ACpf: string): Boolean; static;
    class function MascararCpf(const ACpf: string): string; static;
    class function GerarCpfHashBusca(
      const ACpfNormalizado: string
    ): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles,
  System.Hash;

class function TParticipanteSecurity.NormalizarCpf(
  const ACpf: string
): string;
var
  C: Char;
begin
  Result := '';

  for C in ACpf do
  begin
    if (C >= '0') and (C <= '9') then
      Result := Result + C;
  end;
end;

class function TParticipanteSecurity.CpfValido(
  const ACpf: string
): Boolean;
var
  CpfNormalizado: string;
  I: Integer;
  Soma: Integer;
  Resto: Integer;
  Digito1: Integer;
  Digito2: Integer;
  TodosIguais: Boolean;

  function DigitoNaPosicao(
    const ATexto: string;
    const APosicao: Integer
  ): Integer;
  begin
    Result :=
      Ord(ATexto[APosicao]) -
      Ord('0');
  end;

begin
  Result := False;

  CpfNormalizado :=
    NormalizarCpf(
      ACpf
    );

  if Length(CpfNormalizado) <> 11 then
    Exit;

  TodosIguais := True;

  for I := 2 to 11 do
  begin
    if CpfNormalizado[I] <> CpfNormalizado[1] then
    begin
      TodosIguais := False;
      Break;
    end;
  end;

  if TodosIguais then
    Exit;

  Soma := 0;

  for I := 1 to 9 do
  begin
    Soma :=
      Soma +
      (
        DigitoNaPosicao(
          CpfNormalizado,
          I
        ) *
        (11 - I)
      );
  end;

  Resto :=
    (Soma * 10) mod 11;

  if Resto = 10 then
    Resto := 0;

  Digito1 := Resto;

  if Digito1 <>
     DigitoNaPosicao(
       CpfNormalizado,
       10
     ) then
    Exit;

  Soma := 0;

  for I := 1 to 10 do
  begin
    Soma :=
      Soma +
      (
        DigitoNaPosicao(
          CpfNormalizado,
          I
        ) *
        (12 - I)
      );
  end;

  Resto :=
    (Soma * 10) mod 11;

  if Resto = 10 then
    Resto := 0;

  Digito2 := Resto;

  Result :=
    Digito2 =
    DigitoNaPosicao(
      CpfNormalizado,
      11
    );
end;

class function TParticipanteSecurity.MascararCpf(
  const ACpf: string
): string;
var
  CpfNormalizado: string;
begin
  CpfNormalizado :=
    NormalizarCpf(
      ACpf
    );

  if Length(CpfNormalizado) <> 11 then
  begin
    Result := '';
    Exit;
  end;

  Result :=
    '***.***.***-' +
    Copy(
      CpfNormalizado,
      10,
      2
    );
end;

class function TParticipanteSecurity.GerarCpfHashBusca(
  const ACpfNormalizado: string
): string;
var
  Ini: TIniFile;
  Secret: string;
  CaminhoIni: string;
begin
  if Length(ACpfNormalizado) <> 11 then
    raise Exception.Create(
      'CPF normalizado inválido para geração do hash.'
    );

  CaminhoIni :=
    ExtractFilePath(
      ParamStr(0)
    ) +
    'Config.ini';

  if not FileExists(CaminhoIni) then
    raise Exception.Create(
      'Config.ini não encontrado em: ' +
      CaminhoIni
    );

  Ini :=
    TIniFile.Create(
      CaminhoIni
    );

  try
    Secret :=
      Trim(
        Ini.ReadString(
          'SEGURANCA',
          'CpfHmacSecret',
          ''
        )
      );
  finally
    Ini.Free;
  end;

  if Length(Secret) < 32 then
    raise Exception.Create(
      'SEGURANCA.CpfHmacSecret deve possuir pelo menos 32 caracteres no Config.ini.'
    );

  // Em Delphi 11, o overload de string de GetHMAC usa SHA-256 por padrão.
  Result :=
    LowerCase(
      THashSHA2.GetHMAC(
        ACpfNormalizado,
        Secret
      )
    );
end;

end.

