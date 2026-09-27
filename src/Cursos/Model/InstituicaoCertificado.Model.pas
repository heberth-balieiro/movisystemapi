unit InstituicaoCertificado.Model;

interface

uses
  System.Generics.Collections;

type
  TCertificadoConfiguracao = class
  private
    FExiste: Boolean;
    FIdModeloPadrao: Int64;
    FTemIdModeloPadrao: Boolean;
    FPrefixo: string;
    FUsarAno: Boolean;
    FDigitosSequencia: Integer;
    FTextoValidacao: string;
  public
    property Existe: Boolean read FExiste write FExiste;
    property IdModeloPadrao: Int64 read FIdModeloPadrao write FIdModeloPadrao;
    property TemIdModeloPadrao: Boolean read FTemIdModeloPadrao write FTemIdModeloPadrao;
    property Prefixo: string read FPrefixo write FPrefixo;
    property UsarAno: Boolean read FUsarAno write FUsarAno;
    property DigitosSequencia: Integer read FDigitosSequencia write FDigitosSequencia;
    property TextoValidacao: string read FTextoValidacao write FTextoValidacao;
  end;


  TCertificadoEmissaoContexto = class
  private
    FIdInscricao: Int64;
    FIdTurma: Int64;
    FIdParticipante: Int64;
    FIdCurso: Int64;
    FIdModeloTurma: Int64;
    FTemIdModeloTurma: Boolean;
    FParticipanteNome: string;
    FCursoNome: string;
    FInstituicaoNome: string;
    FCargaHorariaMinutos: Integer;
    FDataConclusao: TDateTime;
    FTemDataConclusao: Boolean;
    FSituacaoInscricao: string;
    FElegivelCertificado: Boolean;
  public
    property IdInscricao: Int64 read FIdInscricao write FIdInscricao;
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property IdCurso: Int64 read FIdCurso write FIdCurso;

    property IdModeloTurma: Int64 read FIdModeloTurma write FIdModeloTurma;
    property TemIdModeloTurma: Boolean read FTemIdModeloTurma write FTemIdModeloTurma;

    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property CursoNome: string read FCursoNome write FCursoNome;
    property InstituicaoNome: string read FInstituicaoNome write FInstituicaoNome;
    property CargaHorariaMinutos: Integer read FCargaHorariaMinutos write FCargaHorariaMinutos;

    property DataConclusao: TDateTime read FDataConclusao write FDataConclusao;
    property TemDataConclusao: Boolean read FTemDataConclusao write FTemDataConclusao;

    property SituacaoInscricao: string read FSituacaoInscricao write FSituacaoInscricao;
    property ElegivelCertificado: Boolean read FElegivelCertificado write FElegivelCertificado;
  end;


  TCertificadoItem = class
  private
    FId: Int64;
    FIdInstituicao: Int64;
    FIdInscricao: Int64;
    FIdTurma: Int64;
    FIdParticipante: Int64;
    FIdCurso: Int64;

    FIdModelo: Int64;
    FTemIdModelo: Boolean;
    FModeloNome: string;

    FIdCertificadoOrigem: Int64;
    FTemIdCertificadoOrigem: Boolean;

    FNumeroPublico: string;
    FCodigoValidacao: string;
    FVersao: Integer;
    FSituacao: string;

    FEmitidoEm: TDateTime;
    FTemEmitidoEm: Boolean;

    FCanceladoEm: TDateTime;
    FTemCanceladoEm: Boolean;

    FMotivoCancelamento: string;
    FMotivoReemissao: string;

    FParticipanteNome: string;
    FCursoNome: string;
    FInstituicaoNome: string;
    FCargaHorariaMinutos: Integer;
    FDataConclusao: TDateTime;

    FPdfStorageKey: string;
    FPdfSha256: string;
    FPdfTamanhoBytes: Int64;
    FTemPdfTamanhoBytes: Boolean;

    FPdfGeradoEm: TDateTime;
    FTemPdfGeradoEm: Boolean;

    FEmitidoPor: Int64;
    FTemEmitidoPor: Boolean;
    FEmitidoPorNome: string;

    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property IdInstituicao: Int64 read FIdInstituicao write FIdInstituicao;
    property IdInscricao: Int64 read FIdInscricao write FIdInscricao;
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property IdCurso: Int64 read FIdCurso write FIdCurso;

    property IdModelo: Int64 read FIdModelo write FIdModelo;
    property TemIdModelo: Boolean read FTemIdModelo write FTemIdModelo;
    property ModeloNome: string read FModeloNome write FModeloNome;

    property IdCertificadoOrigem: Int64 read FIdCertificadoOrigem write FIdCertificadoOrigem;
    property TemIdCertificadoOrigem: Boolean read FTemIdCertificadoOrigem write FTemIdCertificadoOrigem;

    property NumeroPublico: string read FNumeroPublico write FNumeroPublico;
    property CodigoValidacao: string read FCodigoValidacao write FCodigoValidacao;
    property Versao: Integer read FVersao write FVersao;
    property Situacao: string read FSituacao write FSituacao;

    property EmitidoEm: TDateTime read FEmitidoEm write FEmitidoEm;
    property TemEmitidoEm: Boolean read FTemEmitidoEm write FTemEmitidoEm;

    property CanceladoEm: TDateTime read FCanceladoEm write FCanceladoEm;
    property TemCanceladoEm: Boolean read FTemCanceladoEm write FTemCanceladoEm;

    property MotivoCancelamento: string read FMotivoCancelamento write FMotivoCancelamento;
    property MotivoReemissao: string read FMotivoReemissao write FMotivoReemissao;

    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property CursoNome: string read FCursoNome write FCursoNome;
    property InstituicaoNome: string read FInstituicaoNome write FInstituicaoNome;
    property CargaHorariaMinutos: Integer read FCargaHorariaMinutos write FCargaHorariaMinutos;
    property DataConclusao: TDateTime read FDataConclusao write FDataConclusao;

    property PdfStorageKey: string read FPdfStorageKey write FPdfStorageKey;
    property PdfSha256: string read FPdfSha256 write FPdfSha256;

    property PdfTamanhoBytes: Int64 read FPdfTamanhoBytes write FPdfTamanhoBytes;
    property TemPdfTamanhoBytes: Boolean read FTemPdfTamanhoBytes write FTemPdfTamanhoBytes;

    property PdfGeradoEm: TDateTime read FPdfGeradoEm write FPdfGeradoEm;
    property TemPdfGeradoEm: Boolean read FTemPdfGeradoEm write FTemPdfGeradoEm;

    property EmitidoPor: Int64 read FEmitidoPor write FEmitidoPor;
    property TemEmitidoPor: Boolean read FTemEmitidoPor write FTemEmitidoPor;
    property EmitidoPorNome: string read FEmitidoPorNome write FEmitidoPorNome;

    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;


  TCertificadoFiltro = record
    Busca: string;
    Situacao: string;
    IdTurma: Int64;
    IdParticipante: Int64;
    Pagina: Integer;
    PorPagina: Integer;
  end;


  TCertificadoLista = class
  private
    FItens: TObjectList<TCertificadoItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TCertificadoItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;


  TCertificadoHistoricoItem = class
  private
    FId: Int64;
    FEvento: string;
    FDescricao: string;
    FDados: string;
    FIdUsuarioInstituicao: Int64;
    FTemIdUsuarioInstituicao: Boolean;
    FUsuarioNome: string;
    FCriadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property Evento: string read FEvento write FEvento;
    property Descricao: string read FDescricao write FDescricao;
    property Dados: string read FDados write FDados;

    property IdUsuarioInstituicao: Int64 read FIdUsuarioInstituicao write FIdUsuarioInstituicao;
    property TemIdUsuarioInstituicao: Boolean read FTemIdUsuarioInstituicao write FTemIdUsuarioInstituicao;
    property UsuarioNome: string read FUsuarioNome write FUsuarioNome;

    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;


  TCertificadoHistoricoLista =
    TObjectList<TCertificadoHistoricoItem>;


  TCertificadoPdfFinalizacao = record
    PdfStorageKey: string;
    PdfSha256: string;
    PdfTamanhoBytes: Int64;
  end;


  TCertificadoValidacaoPublica = class
  private
    FEncontrado: Boolean;
    FResultado: string;
    FCertificado: TCertificadoItem;
  public
    constructor Create;
    destructor Destroy; override;

    property Encontrado: Boolean read FEncontrado write FEncontrado;
    property Resultado: string read FResultado write FResultado;
    property Certificado: TCertificadoItem read FCertificado write FCertificado;
  end;

implementation

constructor TCertificadoLista.Create;
begin
  inherited;

  FItens :=
    TObjectList<TCertificadoItem>.Create(
      True
    );
end;

destructor TCertificadoLista.Destroy;
begin
  FItens.Free;

  inherited;
end;

constructor TCertificadoValidacaoPublica.Create;
begin
  inherited;

  FCertificado := nil;
end;

destructor TCertificadoValidacaoPublica.Destroy;
begin
  FCertificado.Free;

  inherited;
end;

end.
