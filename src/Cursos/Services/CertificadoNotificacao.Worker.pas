unit CertificadoNotificacao.Worker;

interface

type
  TCertificadoNotificacaoWorker = class
  public
    class procedure Start; static;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  CertificadoNotificacao.Service;

class procedure TCertificadoNotificacaoWorker.Start;
begin
  with TThread.CreateAnonymousThread(
    procedure
    var
      Processou: Boolean;
    begin
      while not TThread.CurrentThread.CheckTerminated do
      begin
        Processou := False;
        try
          Processou := TCertificadoNotificacaoService.ProcessarProximo;
        except
          // O worker não pode derrubar a API.
        end;

        if Processou then
          TThread.Sleep(250)
        else
          TThread.Sleep(2000);
      end;
    end
  ) do
  begin
    FreeOnTerminate := True;
    Start;
  end;
end;

end.
