unit InstituicaoParticipante.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoParticipanteItem = class
  private
    FId: Int64;
    FIdUnidadeOrganizacional: Int64;
    FTemUnidadeOrganizacional: Boolean;
    FUnidadeOrganizacionalNome: string;
    FIdUsuarioInstituicao: Int64;
    FTemUsuarioInstituicao: Boolean;
    FUsuarioNome: string;
    FUsuarioEmail: string;
    FCodigoPublico: string;
    FNome: string;
    FCpfMascarado: string;
    FEmail: string;
    FMatricula: string;
    FTelefone: string;
    FOrgaoEmpresa: string;
    FCargo: string;
    FSituacao: string;
    FAnonimizadoEm: TDateTime;
    FTemAnonimizadoEm: Boolean;
    FMotivoAnonimizacao: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;

    property IdUnidadeOrganizacional: Int64
      read FIdUnidadeOrganizacional
      write FIdUnidadeOrganizacional;

    property TemUnidadeOrganizacional: Boolean
      read FTemUnidadeOrganizacional
      write FTemUnidadeOrganizacional;

    property UnidadeOrganizacionalNome: string
      read FUnidadeOrganizacionalNome
      write FUnidadeOrganizacionalNome;

    property IdUsuarioInstituicao: Int64
      read FIdUsuarioInstituicao
      write FIdUsuarioInstituicao;

    property TemUsuarioInstituicao: Boolean
      read FTemUsuarioInstituicao
      write FTemUsuarioInstituicao;

    property UsuarioNome: string
      read FUsuarioNome
      write FUsuarioNome;

    property UsuarioEmail: string
      read FUsuarioEmail
      write FUsuarioEmail;

    property CodigoPublico: string
      read FCodigoPublico
      write FCodigoPublico;

    property Nome: string
      read FNome
      write FNome;

    property CpfMascarado: string
      read FCpfMascarado
      write FCpfMascarado;

    property Email: string
      read FEmail
      write FEmail;

    property Matricula: string
      read FMatricula
      write FMatricula;

    property Telefone: string
      read FTelefone
      write FTelefone;

    property OrgaoEmpresa: string
      read FOrgaoEmpresa
      write FOrgaoEmpresa;

    property Cargo: string
      read FCargo
      write FCargo;

    property Situacao: string
      read FSituacao
      write FSituacao;

    property AnonimizadoEm: TDateTime
      read FAnonimizadoEm
      write FAnonimizadoEm;

    property TemAnonimizadoEm: Boolean
      read FTemAnonimizadoEm
      write FTemAnonimizadoEm;

    property MotivoAnonimizacao: string
      read FMotivoAnonimizacao
      write FMotivoAnonimizacao;

    property CriadoEm: TDateTime
      read FCriadoEm
      write FCriadoEm;

    property AtualizadoEm: TDateTime
      read FAtualizadoEm
      write FAtualizadoEm;
  end;


  TInstituicaoParticipanteCadastro = record
    IdUnidadeOrganizacional: Int64;
    IdUsuarioInstituicao: Int64;
    Nome: string;
    Cpf: string;
    Email: string;
    Matricula: string;
    Telefone: string;
    OrgaoEmpresa: string;
    Cargo: string;
  end;


  TInstituicaoParticipanteAlteracao = record
    IdUnidadeOrganizacional: Int64;
    IdUsuarioInstituicao: Int64;
    Nome: string;

    // CPF não retorna ao frontend.
    // Só é alterado quando este indicador for True.
    TemCpfInformado: Boolean;
    Cpf: string;

    Email: string;
    Matricula: string;
    Telefone: string;
    OrgaoEmpresa: string;
    Cargo: string;
  end;


  TInstituicaoParticipanteFiltro = record
    Busca: string;
    CpfHashBusca: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;


  TInstituicaoParticipanteLista = class
  private
    FItens: TObjectList<TInstituicaoParticipanteItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoParticipanteItem>
      read FItens;

    property Total: Integer
      read FTotal
      write FTotal;

    property Pagina: Integer
      read FPagina
      write FPagina;

    property PorPagina: Integer
      read FPorPagina
      write FPorPagina;
  end;

implementation

constructor TInstituicaoParticipanteLista.Create;
begin
  inherited;

  FItens :=
    TObjectList<TInstituicaoParticipanteItem>.Create(
      True
    );
end;

destructor TInstituicaoParticipanteLista.Destroy;
begin
  FItens.Free;

  inherited;
end;

end.
