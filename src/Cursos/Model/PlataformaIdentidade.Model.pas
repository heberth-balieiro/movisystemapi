unit PlataformaIdentidade.Model;

interface

uses
  System.JSON;

type
  TPlataformaIdentidadeInput = record
    NomePlataforma: string;
    TituloLogin: string;
    SubtituloLogin: string;
    TituloDestaqueLogin: string;
    DescricaoLogin: string;
  end;

  TPlataformaIdentidadeConfig = record
    NomePlataforma: string;
    TituloLogin: string;
    SubtituloLogin: string;
    TituloDestaqueLogin: string;
    DescricaoLogin: string;
    LogoUrl: string;
    function ToJSON: TJSONObject;
  end;

implementation

function TPlataformaIdentidadeConfig.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('nome_plataforma', NomePlataforma);
  Result.AddPair('titulo_login', TituloLogin);
  Result.AddPair('subtitulo_login', SubtituloLogin);
  Result.AddPair('titulo_destaque_login', TituloDestaqueLogin);
  Result.AddPair('descricao_login', DescricaoLogin);
  Result.AddPair('logo_url', LogoUrl);
end;

end.
