unit EleicaoEmail.Contracts;

interface

type
  IEmailService = interface
    ['{6C0EF2D4-03D9-4E1B-A4B8-BBA8E67692C6}']
    procedure Enviar(
      const AIdEmpresa: Integer;
      const ADestinatario,
            AAssunto,
            AHtml: string
    );

    procedure EnviarTeste(
      const AIdEmpresa: Integer;
      const ADestinatario: string
    );
  end;

implementation

end.
