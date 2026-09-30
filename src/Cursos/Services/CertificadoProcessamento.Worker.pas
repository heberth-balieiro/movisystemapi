unit CertificadoProcessamento.Worker;

interface

type
  TCertificadoProcessamentoWorker = class
  public
    class procedure Start; static;
  end;

implementation

uses
  System.Classes,
  CertificadoProcessamento.Service;

class procedure TCertificadoProcessamentoWorker.Start;
var
  Worker: TThread;
begin
  Worker := TThread.CreateAnonymousThread(
    procedure
    var
      Processou: Boolean;
    begin
      while True do
      begin
        Processou := False;
        try
          Processou := TCertificadoProcessamentoService.ProcessarProximo;
        except
          // O worker nunca pode derrubar a API.
          // Erros individuais permanecem registrados na fila.
        end;

        if Processou then
          TThread.Sleep(250)
        else
          TThread.Sleep(2000);
      end;
    end
  );

  Worker.FreeOnTerminate := True;
  Worker.Start;
end;

end.
