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
  private
    FId: Int64;
    FDocumento: string;
    FRazaoSocial: string;
    FNomeFantasia: string;
    FResponsavel: string;
    FTelefone: string;
    FEmail: string;
    FGrau: string;
    FCidade: string;
    FUF: string;
    FOrgao: string;
    FSite: string;
    FFonte: string;
    FDataColeta: string;
    FSituacao: string;
    FCargo: string;
    FPartido: string;
    FIdExterno: string;
    FFonteDados: string;
    FUrlPerfil: string;
    FUnaleAssociado: Boolean;
    FEmExercicio: Boolean;
  public
    property Id: Int64 read FId write FId;
    property Documento: string read FDocumento write FDocumento;
    property RazaoSocial: string read FRazaoSocial write FRazaoSocial;
    property NomeFantasia: string read FNomeFantasia write FNomeFantasia;
    property Responsavel: string read FResponsavel write FResponsavel;
    property Telefone: string read FTelefone write FTelefone;
    property Email: string read FEmail write FEmail;
    property Grau: string read FGrau write FGrau;
    property Cidade: string read FCidade write FCidade;
    property UF: string read FUF write FUF;
    property Orgao: string read FOrgao write FOrgao;
    property Site: string read FSite write FSite;
    property Fonte: string read FFonte write FFonte;
    property DataColeta: string read FDataColeta write FDataColeta;
    property Situacao: string read FSituacao write FSituacao;
    property Cargo: string read FCargo write FCargo;
    property Partido: string read FPartido write FPartido;
    property IdExterno: string read FIdExterno write FIdExterno;
    property FonteDados: string read FFonteDados write FFonteDados;
    property UrlPerfil: string read FUrlPerfil write FUrlPerfil;
    property UnaleAssociado: Boolean read FUnaleAssociado write FUnaleAssociado;
    property EmExercicio: Boolean read FEmExercicio write FEmExercicio;
  end;

  TPlataformaContatoRelatorioResultado = class
  private
    FItens: TObjectList<TPlataformaContatoRelatorioItem>;
    FTotal: Integer;
    FLimite: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property Itens: TObjectList<TPlataformaContatoRelatorioItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Limite: Integer read FLimite write FLimite;
  end;

implementation

constructor TPlataformaContatoRelatorioResultado.Create;
begin
  inherited;
  FItens := TObjectList<TPlataformaContatoRelatorioItem>.Create(True);
  FLimite := 5000;
end;

destructor TPlataformaContatoRelatorioResultado.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
