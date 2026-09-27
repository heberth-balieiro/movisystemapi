unit InstituicaoInstrutor.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoInstrutorItem = class
  private
    FId: Int64;
    FIdParticipante: Int64;
    FTemParticipante: Boolean;
    FParticipanteNome: string;
    FCodigoPublico: string;
    FNome: string;
    FEmail: string;
    FTelefone: string;
    FBiografia: string;
    FSituacao: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property TemParticipante: Boolean read FTemParticipante write FTemParticipante;
    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property CodigoPublico: string read FCodigoPublico write FCodigoPublico;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property Telefone: string read FTelefone write FTelefone;
    property Biografia: string read FBiografia write FBiografia;
    property Situacao: string read FSituacao write FSituacao;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

  TInstituicaoInstrutorCadastro = record
    IdParticipante: Int64;
    Nome: string;
    Email: string;
    Telefone: string;
    Biografia: string;
  end;

  TInstituicaoInstrutorAlteracao = record
    IdParticipante: Int64;
    Nome: string;
    Email: string;
    Telefone: string;
    Biografia: string;
  end;

  TInstituicaoInstrutorFiltro = record
    Busca: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoInstrutorLista = class
  private
    FItens: TObjectList<TInstituicaoInstrutorItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoInstrutorItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoInstrutorLista.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoInstrutorItem>.Create(True);
end;

destructor TInstituicaoInstrutorLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
