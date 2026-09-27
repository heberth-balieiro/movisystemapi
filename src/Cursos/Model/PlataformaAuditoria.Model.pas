unit PlataformaAuditoria.Model;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TPlataformaAuditoriaItem = class
  private
    FId: Int64;
    FCriadoEm: TDateTime;
    FIdUsuario: Int64;
    FUsuarioNome: string;
    FUsuarioEmail: string;
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
    property IdUsuario: Int64 read FIdUsuario write FIdUsuario;
    property UsuarioNome: string read FUsuarioNome write FUsuarioNome;
    property UsuarioEmail: string read FUsuarioEmail write FUsuarioEmail;
    property Acao: string read FAcao write FAcao;
    property Entidade: string read FEntidade write FEntidade;
    property RegistroId: string read FRegistroId write FRegistroId;
    property MetodoHttp: string read FMetodoHttp write FMetodoHttp;
    property Rota: string read FRota write FRota;
    property IP: string read FIP write FIP;
    property Sucesso: Boolean read FSucesso write FSucesso;
    property Mensagem: string read FMensagem write FMensagem;
  end;

  TPlataformaAuditoriaFiltro = record
    Busca: string;
    Acao: string;
    DataInicio: TDateTime;
    DataFim: TDateTime;
    TemDataInicio: Boolean;
    TemDataFim: Boolean;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TPlataformaAuditoriaResultado = class
  private
    FItens: TObjectList<TPlataformaAuditoriaItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TPlataformaAuditoriaItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TPlataformaAuditoriaResultado.Create;
begin
  inherited;
  FItens := TObjectList<TPlataformaAuditoriaItem>.Create(True);
end;

destructor TPlataformaAuditoriaResultado.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
