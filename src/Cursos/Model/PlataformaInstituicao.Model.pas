unit PlataformaInstituicao.Model;

interface

uses
  System.SysUtils;

type
  // Representa a identidade visual da instituição usada pelo frontend.
  TPlataformaInstituicaoTema = class
  public
    NomeExibicao: string;
    LogoUrl: string;
    FaviconUrl: string;
    ImagemLoginUrl: string;
    CorPrimaria: string;
    CorSecundaria: string;
    CorDestaque: string;
    CorFundo: string;
    CorTexto: string;
    constructor Create;
  end;

  // Modelo usado pela administração global da MoviSystem.
  TPlataformaInstituicaoModel = class
  public
    Id: Int64;
    CodigoPublico: string;
    Slug: string;
    RazaoSocial: string;
    NomeFantasia: string;
    Documento: string;
    Tipo: string;
    Email: string;
    Telefone: string;
    Site: string;
    Situacao: string;
    CriadoEm: TDateTime;
    AdministradorNome: string;
    AdministradorEmail: string;
    Tema: TPlataformaInstituicaoTema;

    // Métricas ficam zeradas nesta etapa. Serão alimentadas quando as tabelas
    // de cursos, turmas, participantes e certificados entrarem no Run.
    MetricasUsuarios: Int64;
    MetricasParticipantes: Int64;
    MetricasCursos: Int64;
    MetricasTurmas: Int64;
    MetricasCertificados: Int64;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TPlataformaInstituicaoTema.Create;
begin
  inherited Create;
  CorPrimaria := '#2563EB';
  CorSecundaria := '#1E40AF';
  CorDestaque := '#F59E0B';
  CorFundo := '#F8FAFC';
  CorTexto := '#0F172A';
end;

constructor TPlataformaInstituicaoModel.Create;
begin
  inherited Create;
  Tipo := 'PRIVADA';
  Situacao := 'IMPLANTACAO';
  Tema := TPlataformaInstituicaoTema.Create;
end;

destructor TPlataformaInstituicaoModel.Destroy;
begin
  Tema.Free;
  inherited;
end;

end.
