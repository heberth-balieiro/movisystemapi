unit EleicaoMembroFotoAPI.Controller;

interface

type
  TEleicaoMembroFotoAPIController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.Classes,
  App.Errors,
  EleicaoMembroFotoAPI.Service;

{ TEleicaoMembroFotoAPIController }

class procedure TEleicaoMembroFotoAPIController.Registry;
begin

  {$REGION 'FOTO MEMBRO'}

  THorse.Get('/api/v1/public/eleicao/:slug/membro/:id/foto',

    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug       : string;
      IdMembro   : Integer;
      Foto       : TEleicaoMembroFotoResult;
      Stream     : TMemoryStream;
      NomeArquivo: string;
    begin
      try
        Slug := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');

        if not TryStrToInt(Trim(Req.Params['id']), IdMembro) then
          TAppErrors.RaiseBadRequest('Membro inválido.');

        if IdMembro <= 0 then
          TAppErrors.RaiseBadRequest('Membro inválido.');

        Foto := TEleicaoMembroFotoAPIService.BuscarFoto(Slug, IdMembro);

        Stream := TMemoryStream.Create;

        if Length(Foto.Arquivo) > 0 then
          Stream.WriteBuffer(Foto.Arquivo[0], Length(Foto.Arquivo));

        Stream.Position := 0;

        NomeArquivo := Format(
          'membro_%d.%s',
          [
            IdMembro,
            LowerCase(Foto.Extensao)
          ]
        );

        Res
          .AddHeader('Cache-Control', 'public, max-age=3600')
          .SendFile(
            Stream,
            NomeArquivo,
            Foto.ContentType
          );

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}

end;

end.
