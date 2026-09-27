unit PublicoInstituicao.Model;

interface

uses
  System.Generics.Collections;

type
  TPublicoInstituicao = class
  public
    Id: Int64;
    Slug: string;
    Nome: string;
    RazaoSocial: string;
    Cnpj: string;
    Descricao: string;
    Email: string;
    Telefone: string;
    Site: string;
    NomeExibicao: string;
    LogoUrl: string;
    FaviconUrl: string;
    ImagemLoginUrl: string;
    CorPrimaria: string;
    CorSecundaria: string;
    CorDestaque: string;
    CorFundo: string;
    CorTexto: string;
  end;

  TPublicoCurso = class
  public
    IdTurma: Int64;
    CodigoTurma: string;
    TurmaNome: string;
    IdCurso: Int64;
    CodigoCurso: string;
    CursoNome: string;
    CursoDescricao: string;
    Modalidade: string;
    ImagemUrl: string;
    DataHoraInicio: TDateTime;
    DataHoraFim: TDateTime;
    TemInscricaoFim: Boolean;
    InscricaoFim: TDateTime;
    TemLimiteParticipantes: Boolean;
    LimiteParticipantes: Integer;
    InscritosConfirmados: Integer;
    TemVagasDisponiveis: Boolean;
    VagasDisponiveis: Integer;
    Local: string;
    CargaHorariaMinutos: Integer;
  end;

  TPublicoCursoLista = class
  private
    FItens: TObjectList<TPublicoCurso>;
  public
    Pagina: Integer;
    PorPagina: Integer;
    Total: Integer;
    constructor Create;
    destructor Destroy; override;
    property Itens: TObjectList<TPublicoCurso> read FItens;
  end;

implementation

constructor TPublicoCursoLista.Create;
begin
  inherited;
  FItens := TObjectList<TPublicoCurso>.Create(True);
end;

destructor TPublicoCursoLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
