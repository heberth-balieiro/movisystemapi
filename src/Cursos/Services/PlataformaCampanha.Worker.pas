unit PlataformaCampanha.Worker;

interface

type
  TPlataformaCampanhaWorker = class
  public
    class procedure Start; static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  PlataformaCampanha.Service;

class procedure TPlataformaCampanhaWorker.Start;
var
  Worker: TThread;
begin
  Worker :=
    TThread.CreateAnonymousThread(
      procedure
      begin
        while True do
        begin
          try
            TPlataformaCampanhaService.ProcessarProximo;
          except
            // O worker não pode derrubar a API.
            // Falhas individuais são persistidas na própria fila.
          end;

          TThread.Sleep(1500);
        end;
      end
    );

  Worker.FreeOnTerminate := True;
  Worker.Start;
end;

end.
