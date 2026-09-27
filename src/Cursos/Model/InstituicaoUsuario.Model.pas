unit InstituicaoUsuario.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoUsuarioPerfilItem = class
  private
    FId: Int64;
    FNome: string;
    FSistema: Boolean;
    FSituacao: string;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property Sistema: Boolean read FSistema write FSistema;
    property Situacao: string read FSituacao write FSituacao;
  end;

  TInstituicaoUsuarioItem = class
  private
    FId: Int64;
    FIdUsuario: Int64;
    FNome: string;
    FEmail: string;
    FLogin: string;
    FSituacao: string;
    FPrincipal: Boolean;
    FTemUltimoAcesso: Boolean;
    FUltimoAcessoEm: TDateTime;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
    FPerfis: TObjectList<TInstituicaoUsuarioPerfilItem>;
  public
    constructor Create;
    destructor Destroy; override;

    property Id: Int64 read FId write FId;
    property IdUsuario: Int64 read FIdUsuario write FIdUsuario;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property Login: string read FLogin write FLogin;
    property Situacao: string read FSituacao write FSituacao;
    property Principal: Boolean read FPrincipal write FPrincipal;
    property TemUltimoAcesso: Boolean read FTemUltimoAcesso write FTemUltimoAcesso;
    property UltimoAcessoEm: TDateTime read FUltimoAcessoEm write FUltimoAcessoEm;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
    property Perfis: TObjectList<TInstituicaoUsuarioPerfilItem> read FPerfis;
  end;

  TInstituicaoUsuarioCadastro = record
    Nome: string;
    Email: string;
    Login: string;
    Perfis: TArray<Int64>;
  end;

  TInstituicaoUsuarioAlteracao = record
    Login: string;
  end;

  TInstituicaoUsuarioFiltro = record
    Busca: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoUsuarioLista = class
  private
    FItens: TObjectList<TInstituicaoUsuarioItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoUsuarioItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoUsuarioItem.Create;
begin
  inherited;
  FPerfis :=
    TObjectList<TInstituicaoUsuarioPerfilItem>.Create(True);
end;

destructor TInstituicaoUsuarioItem.Destroy;
begin
  FPerfis.Free;
  inherited;
end;

constructor TInstituicaoUsuarioLista.Create;
begin
  inherited;
  FItens :=
    TObjectList<TInstituicaoUsuarioItem>.Create(True);
end;

destructor TInstituicaoUsuarioLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
