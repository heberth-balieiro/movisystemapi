unit App.ProcessRunner;

interface

type
  TAppProcessRunner = class
  public
    class function QuoteArg(
      const AValue: string
    ): string; static;

    class procedure Execute(
      const AExecutable: string;
      const AArguments: array of string
    ); static;
  end;

implementation

uses
  System.SysUtils
{$IFDEF MSWINDOWS}
  , Winapi.Windows
{$ENDIF}
{$IFDEF POSIX}
  , Posix.Base
{$ENDIF}
  ;

{$IFDEF POSIX}
function PosixSystem(
  const ACommand: PAnsiChar
): Integer; cdecl;
  external libc name _PU + 'system';
{$ENDIF}

class function TAppProcessRunner.QuoteArg(
  const AValue: string
): string;
begin
{$IFDEF MSWINDOWS}
  Result :=
    '"' +
    StringReplace(
      AValue,
      '"',
      '\"',
      [rfReplaceAll]
    ) +
    '"';
{$ELSE}
  Result :=
    '''' +
    StringReplace(
      AValue,
      '''',
      '''"''"''',
      [rfReplaceAll]
    ) +
    '''';
{$ENDIF}
end;

class procedure TAppProcessRunner.Execute(
  const AExecutable: string;
  const AArguments: array of string
);
var
  I: Integer;
  CommandLine: string;
{$IFDEF MSWINDOWS}
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  ExitCode: Cardinal;
{$ENDIF}
{$IFDEF POSIX}
  Utf8Command: UTF8String;
  ExitCodePosix: Integer;
{$ENDIF}
begin
  if Trim(AExecutable).IsEmpty then
    raise Exception.Create(
      'Executável externo não configurado.'
    );

  CommandLine :=
    QuoteArg(
      AExecutable
    );

  for I := Low(AArguments) to High(AArguments) do
    CommandLine :=
      CommandLine +
      ' ' +
      QuoteArg(
        AArguments[I]
      );

{$IFDEF MSWINDOWS}
  ZeroMemory(
    @StartupInfo,
    SizeOf(
      StartupInfo
    )
  );

  StartupInfo.cb :=
    SizeOf(
      StartupInfo
    );

  ZeroMemory(
    @ProcessInfo,
    SizeOf(
      ProcessInfo
    )
  );

  UniqueString(
    CommandLine
  );

  if not CreateProcess(
    nil,
    PChar(CommandLine),
    nil,
    nil,
    False,
    CREATE_NO_WINDOW,
    nil,
    nil,
    StartupInfo,
    ProcessInfo
  ) then
    raise Exception.CreateFmt(
      'Não foi possível executar "%s". Erro Windows: %d.',
      [
        AExecutable,
        GetLastError
      ]
    );

  try
    WaitForSingleObject(
      ProcessInfo.hProcess,
      INFINITE
    );

    if not GetExitCodeProcess(
      ProcessInfo.hProcess,
      ExitCode
    ) then
      raise Exception.CreateFmt(
        'Não foi possível obter o código de saída de "%s".',
        [
          AExecutable
        ]
      );

    if ExitCode <> 0 then
      raise Exception.CreateFmt(
        'O processo "%s" terminou com código %d.',
        [
          AExecutable,
          ExitCode
        ]
      );

  finally
    CloseHandle(
      ProcessInfo.hThread
    );

    CloseHandle(
      ProcessInfo.hProcess
    );
  end;
{$ENDIF}

{$IFDEF POSIX}
  Utf8Command :=
    UTF8String(
      CommandLine
    );

  ExitCodePosix :=
    PosixSystem(
      PAnsiChar(
        Utf8Command
      )
    );

  if ExitCodePosix <> 0 then
    raise Exception.CreateFmt(
      'O processo "%s" terminou com código %d.',
      [
        AExecutable,
        ExitCodePosix
      ]
    );
{$ENDIF}

{$IFNDEF MSWINDOWS}
{$IFNDEF POSIX}
  raise Exception.Create(
    'Sistema operacional não suportado pelo executor de processos.'
  );
{$ENDIF}
{$ENDIF}
end;

end.
