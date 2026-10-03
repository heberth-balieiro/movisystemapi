unit Contrato.Model;

interface

uses
  System.Generics.Collections;

type
  TContratoCadastro = record
    DocumentoContratado: string;
    NomeContratado: string;
    Numero: string;
    NumeroExterno: string;
    TipoGestao: string;
    Tipo: string;
    Titulo: string;
    Objeto: string;
    NumeroProcesso: string;
    AnoProcesso: Integer;
    OrigemContratacao: string;
    Modalidade: string;
    NumeroLicitacao: string;
    IdentificadorPncp: string;
    UrlPncp: string;
    DataAssinatura: TDateTime;
    DataInicio: TDateTime;
    DataFim: TDateTime;
    ValorInicial: Double;
    ValorAtual: Double;
    Periodicidade: string;
    UnidadeResponsavel: string;
    Observacao: string;
    Situacao: string;
  end;

  TContratoItem = class
  public
    Id: Int64;
    CodigoPublico: string;
    IdEntidade: Int64;
    DocumentoContratado: string;
    NomeContratado: string;
    Numero: string;
    NumeroExterno: string;
    TipoGestao: string;
    Tipo: string;
    Titulo: string;
    Objeto: string;
    NumeroProcesso: string;
    AnoProcesso: Integer;
    OrigemContratacao: string;
    Modalidade: string;
    NumeroLicitacao: string;
    IdentificadorPncp: string;
    UrlPncp: string;
    DataAssinatura: TDateTime;
    DataInicio: TDateTime;
    DataFim: TDateTime;
    ValorInicial: Double;
    ValorAtual: Double;
    Periodicidade: string;
    UnidadeResponsavel: string;
    Observacao: string;
    Situacao: string;
  end;

  TContratoFiltro = record
    Busca: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TContratoLista = class
  public
    Itens: TObjectList<TContratoItem>;
    Total: Integer;
    Pagina: Integer;
    PorPagina: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TContratoLista.Create;
begin
  inherited;
  Itens := TObjectList<TContratoItem>.Create(True);
end;

destructor TContratoLista.Destroy;
begin
  Itens.Free;
  inherited;
end;

end.
