unit PlataformaContatoRelatorio.Model;

interface

uses
  System.Generics.Collections;

type
  TPlataformaContatoRelatorioFiltro = record
    Tipo: string;
    UF: string;
    Municipio: string;
    Partido: string;
    Situacao: string;
    EmExercicio: Integer;
    TemEmail: Integer;
  end;

  TPlataformaContatoRelatorioItem = class
  public
    Id: Int64;
    Documento: string;
    RazaoSocial: string;
    NomeFantasia: string;
    Responsavel: string;
    Telefone: string;
    Email: string;
    Grau: string;
    Cidade: string;
    UF: string;
    Orgao: string;
    Site: string;
    Fonte: string;
    DataColeta: string;
    Situacao: string;
    Cargo: string;
    Partido: string;
    IdExterno: string;
    FonteDados: string;
    UrlPerfil: string;
    UnaleAssociado: Boolean;
    EmExercicio: Boolean;
  end;

  TPlataformaContatoRelatorioResultado = class
  public
    Tipo: string;
    Total: Integer;
    Limite: Integer;
    Itens: TObjectList<TPlataformaContatoRelatorioItem>;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TPlataformaContatoRelatorioResultado.Create;
begin
  inherited Create;
  Itens := TObjectList<TPlataformaContatoRelatorioItem>.Create(True);
  Limite := 5000;
end;

destructor TPlataformaContatoRelatorioResultado.Destroy;
begin
  Itens.Free;
  inherited;
end;

end.
