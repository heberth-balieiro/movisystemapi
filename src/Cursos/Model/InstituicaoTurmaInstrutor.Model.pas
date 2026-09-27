unit InstituicaoTurmaInstrutor.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoTurmaInstrutorItem = class
  private
    FIdInstrutor: Int64;
    FInstrutorNome: string;
    FInstrutorEmail: string;
    FInstrutorTelefone: string;
    FInstrutorSituacao: string;
    FPrincipal: Boolean;
    FCriadoEm: TDateTime;
  public
    property IdInstrutor: Int64 read FIdInstrutor write FIdInstrutor;
    property InstrutorNome: string read FInstrutorNome write FInstrutorNome;
    property InstrutorEmail: string read FInstrutorEmail write FInstrutorEmail;
    property InstrutorTelefone: string read FInstrutorTelefone write FInstrutorTelefone;
    property InstrutorSituacao: string read FInstrutorSituacao write FInstrutorSituacao;
    property Principal: Boolean read FPrincipal write FPrincipal;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

  TInstituicaoTurmaInstrutorLista = class
  private
    FItens: TObjectList<TInstituicaoTurmaInstrutorItem>;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoTurmaInstrutorItem> read FItens;
  end;

implementation

constructor TInstituicaoTurmaInstrutorLista.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoTurmaInstrutorItem>.Create(True);
end;

destructor TInstituicaoTurmaInstrutorLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
