unit InstituicaoAuditoria.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoAuditoriaItem = class
  private
    FId: Int64;
    FCriadoEm: TDateTime;
    FIdUsuarioInstituicao: Int64;
    FUsuarioNome: string;
    FAcao: string;
    FEntidade: string;
    FRegistroId: string;
    FMetodoHttp: string;
    FRota: string;
    FIP: string;
    FSucesso: Boolean;
    FMensagem: string;
  public
    property Id: Int64 read FId write FId;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property IdUsuarioInstituicao: Int64 read FIdUsuarioInstituicao write FIdUsuarioInstituicao;
    property UsuarioNome: string read FUsuarioNome write FUsuarioNome;
    property Acao: string read FAcao write FAcao;
    property Entidade: string read FEntidade write FEntidade;
    property RegistroId: string read FRegistroId write FRegistroId;
    property MetodoHttp: string read FMetodoHttp write FMetodoHttp;
    property Rota: string read FRota write FRota;
    property IP: string read FIP write FIP;
    property Sucesso: Boolean read FSucesso write FSucesso;
    property Mensagem: string read FMensagem write FMensagem;
  end;

  TInstituicaoAuditoriaFiltro = record
    Busca: string;
    Acao: string;
    Entidade: string;
    DataInicio: TDateTime;
    DataFim: TDateTime;
    TemDataInicio: Boolean;
    TemDataFim: Boolean;
    TemSucesso: Boolean;
    Sucesso: Boolean;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoAuditoriaResultado = class
  private
    FItens: TObjectList<TInstituicaoAuditoriaItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoAuditoriaItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoAuditoriaResultado.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoAuditoriaItem>.Create(True);
end;

destructor TInstituicaoAuditoriaResultado.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
