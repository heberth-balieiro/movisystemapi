unit Eleicao.Model;

interface

uses
  System.SysUtils;

type
  TEleicaoModel = class
  private
    Fempresaid: integer;
    FAtivo: string;
    FDescricao: string;
    FCodigo: Integer;
    Fid: integer;
    FAno: Integer;
    Fid_eleicao_int: Integer;
    Fsituacao: string;
    Fano_fim: Integer;
    FNome: string;
    FTipo: string;
    Foperacao: String;

  public
    property id             : integer   read Fid              write Fid;
    property empresaid      : integer   read Fempresaid       write Fempresaid;
    property id_eleicao_int : Integer   read Fid_eleicao_int  write Fid_eleicao_int;
    property Codigo         : Integer   read FCodigo          write FCodigo;
    property nome           : string    read FNome            write FNome;
    property descricao      : string    read FDescricao       write FDescricao;
    property ano            : Integer   read FAno             write FAno;
    property ativo          : string    read FAtivo           write FAtivo;
    property ano_fim        : Integer   read Fano_fim         write Fano_fim;
    // E = Eleição, A = Assembleia
    property Tipo           : string    read FTipo            write FTipo;
    property situacao       : string    read Fsituacao        write Fsituacao;
    property operacao       : String    read Foperacao        write Foperacao;

  end;

type
  TEleicaoConfigModel = class
    private
    FEmpresaId: Integer;
    FEmail: string;
    FUrlPublica: string;
    FSlug: string;
    FCorPrimaria: string;
    FEleicaoId: Integer;
    FPaginaPublicar: string;
    FCorSecundaria: string;
    FId: Integer;
    FUrlInstagram: string;
    FUrlFacebook: string;
    FMensagemBoasVindas: string;
    FIdConfig: Integer;
    FLogo: string;
    FNomeExibicao: string;
    FBanner: string;
    FUrlYoutube: string;
    FTelefone: string;
    FDataHoraFim: TDateTime;
    FDataHoraInicio: TDateTime;
    Fencerramento_automatico: string;
    Fabertura_automatica: string;
    Fquorum_base: string;
    Fquorum_minimo: integer;
    Fexigir_presenca_votacao: string;
    Ftipo_quorum: string;
    Fvotacao_secreta: string;
    Fquorum_percentual: double;
    Fexibir_resultado_parcial: string;
    Fcontrolar_quorum: string;
    Fpublicacao_resultado: string;
    Fcontrolar_presenca: string;

    public
      property id                 : Integer read FId                  write FId;
      property EmpresaId          : Integer read FEmpresaId           write FEmpresaId;
      property EleicaoId          : Integer read FEleicaoId           write FEleicaoId;
      property IdConfig           : Integer read FIdConfig            write FIdConfig;
      property Slug               : string  read FSlug                write FSlug;
      property NomeExibicao       : string  read FNomeExibicao        write FNomeExibicao;
      property Logo               : string  read FLogo                write FLogo;
      property Banner             : string  read FBanner              write FBanner;
      property MensagemBoasVindas : string  read FMensagemBoasVindas  write FMensagemBoasVindas;
      property Url_Publica        : string  read FUrlPublica          write FUrlPublica;
      property Email              : string  read FEmail               write FEmail;
      property Telefone           : string  read FTelefone            write FTelefone;
      property CorPrimaria        : string  read FCorPrimaria         write FCorPrimaria;
      property CorSecundaria      : string  read FCorSecundaria       write FCorSecundaria;
      property UrlInstagram       : string  read FUrlInstagram        write FUrlInstagram;
      property UrlFacebook        : string  read FUrlFacebook         write FUrlFacebook;
      property UrlYoutube         : string  read FUrlYoutube          write FUrlYoutube;
      property PaginaPublicar     : string  read FPaginaPublicar      write FPaginaPublicar;
      property DataHoraInicio     : TDateTime read FDataHoraInicio write FDataHoraInicio;
      property DataHoraFim        : TDateTime read FDataHoraFim    write FDataHoraFim;
      property abertura_automatica     :string  read Fabertura_automatica write Fabertura_automatica;
      property encerramento_automatico :string  read Fencerramento_automatico write Fencerramento_automatico;

      property votacao_secreta          :string  read Fvotacao_secreta      write Fvotacao_secreta;
      property exibir_resultado_parcial :string  read Fexibir_resultado_parcial      write Fexibir_resultado_parcial;
      property publicacao_resultado     :string  read Fpublicacao_resultado      write Fpublicacao_resultado;
      property controlar_quorum         :string  read Fcontrolar_quorum      write Fcontrolar_quorum;
      property tipo_quorum              :string  read Ftipo_quorum      write Ftipo_quorum;
      property quorum_minimo            :integer read Fquorum_minimo      write Fquorum_minimo;
      property quorum_percentual        :double  read Fquorum_percentual      write Fquorum_percentual;
      property quorum_base              :string  read Fquorum_base      write Fquorum_base;
      property controlar_presenca       :string  read Fcontrolar_presenca      write Fcontrolar_presenca;
      property exigir_presenca_votacao  :string  read Fexigir_presenca_votacao      write Fexigir_presenca_votacao;
  end;

type
  TEleicaoChapaModel = class
    private
    FObs: string;
    FEmpresaId: Integer;
    FAtivo: string;
    FEleicaoId: Integer;
    FCodigo: Integer;
    FId: Integer;
    FNomeChapa: string;
    FSituacao: string;
    FSlogan: string;
    FNumChapa: Integer;
    Fid_chapa_int: integer;

    public
      property Id         : Integer read FId write FId;
      property EmpresaId  : Integer read FEmpresaId write FEmpresaId;
      property EleicaoId  : Integer read FEleicaoId write FEleicaoId;
      property id_chapa_int : integer read Fid_chapa_int  write Fid_chapa_int;
      property Codigo     : Integer read FCodigo write FCodigo;
      property Situacao   : string read FSituacao write FSituacao;
      property NumChapa   : Integer read FNumChapa write FNumChapa;
      property NomeChapa  : string read FNomeChapa write FNomeChapa;
      property Slogan     : string read FSlogan write FSlogan;
      property Obs        : string read FObs write FObs;
      property Ativo      : string read FAtivo write FAtivo;
  end;

type
  TEleicaoChapaMembrosModel = class
    private
    FExtensaoFoto: string;
    FObservacao: string;
    FEmpresaId: Integer;
    FEmail: string;
    FAtivo: string;
    FEleicaoId: Integer;
    FArquivoFoto: String;
    FCodigo: Integer;
    FCpf: string;
    Fid_membro_int: Integer;
    FId: Integer;
    FCargo: string;
    FNome: string;
    FTipo: string;
    FTelefone: string;
    FEleicaoChapaId: Integer;

    public
      property Id               : Integer read FId write FId;
      property EmpresaId        : Integer read FEmpresaId write FEmpresaId;
      property EleicaoId        : Integer read FEleicaoId write FEleicaoId;
      property EleicaoChapaId   : Integer read FEleicaoChapaId write FEleicaoChapaId;
      property id_membro_int     : Integer read Fid_membro_int write Fid_membro_int;
      property Codigo           : Integer read FCodigo write FCodigo;
      property Nome             : string  read FNome write FNome;
      property Cpf              : string  read FCpf write FCpf;
      property Telefone         : string  read FTelefone write FTelefone;
      property Email            : string  read FEmail write FEmail;
      property Ativo            : string  read FAtivo write FAtivo;
      property Cargo            : string  read FCargo write FCargo;
      property Tipo             : string  read FTipo write FTipo;
      property Observacao       : string  read FObservacao write FObservacao;
      property ArquivoFoto      : String  read FArquivoFoto write FArquivoFoto;
      property ExtensaoFoto     : string  read FExtensaoFoto write FExtensaoFoto;
  end;

type
  TEleicaoQuestaoModel = class
    private
    Fid_questao_int: Integer;
    Ftitulo: string;
    Fativo: string;
    Ftipo_resposta: string;
    Fdescricao: string;
    Fid: Integer;
    Fid_eleicao_int: Integer;
    Fempresa_id: Integer;
    Fordem: Integer;
    Feleicao_id: Integer;
    Fobrigatoria: string;

    public
      property id: Integer read Fid write Fid;
      property id_questao_int: Integer read Fid_questao_int write Fid_questao_int;
      property eleicao_id: Integer read Feleicao_id write Feleicao_id;
      property id_eleicao_int: Integer read Fid_eleicao_int write Fid_eleicao_int;
      property empresa_id: Integer read Fempresa_id write Fempresa_id;
      property titulo: string read Ftitulo write Ftitulo;
      property descricao: string read Fdescricao write Fdescricao;
      property ordem: Integer read Fordem write Fordem;
      property tipo_resposta: string read Ftipo_resposta write Ftipo_resposta;
      property obrigatoria: string read Fobrigatoria write Fobrigatoria;
      property ativo: string read Fativo write Fativo;
end;

type
  TEleicaoQuestaoOpcaoModel = class
    private
    Fid_questao_int: Integer;
    Fativo: string;
    Fdescricao: string;
    Fquestao_id: Integer;
    Fid_opcao_int: Integer;
    Fid: Integer;
    Fid_eleicao_int: Integer;
    Fempresa_id: Integer;
    Fordem: Integer;
    Feleicao_id: Integer;

    public
      property id: Integer read Fid write Fid;
      property id_opcao_int: Integer read Fid_opcao_int write Fid_opcao_int;
      property questao_id: Integer read Fquestao_id write Fquestao_id;
      property id_questao_int: Integer read Fid_questao_int write Fid_questao_int;
      property eleicao_id: Integer read Feleicao_id write Feleicao_id;
      property id_eleicao_int: Integer read Fid_eleicao_int write Fid_eleicao_int;
      property empresa_id: Integer read Fempresa_id write Fempresa_id;
      property ordem: Integer read Fordem write Fordem;
      property descricao: string read Fdescricao write Fdescricao;
      property ativo: string read Fativo write Fativo;

end;


type
  TEleicaoComissaoModel = class
  private
    FEmpresaId: Integer;
    FEleicaoId: Integer;
    FIdEleicaoInt: Integer;
    FIdComissaoInt: Integer;
    FUsuarioId: Integer;
    FNome: string;
    FCPF: string;
    FTelefone: string;
    FEmail: string;
    FCargo: string;
    FAtivo: string;
    FSenhaHash: string;
  public
    property EmpresaId: Integer read FEmpresaId write FEmpresaId;
    property EleicaoId: Integer read FEleicaoId write FEleicaoId;
    property IdEleicaoInt: Integer read FIdEleicaoInt write FIdEleicaoInt;
    property IdComissaoInt: Integer read FIdComissaoInt write FIdComissaoInt;
    property UsuarioId: Integer read FUsuarioId write FUsuarioId;
    property Nome: string read FNome write FNome;
    property CPF: string read FCPF write FCPF;
    property Telefone: string read FTelefone write FTelefone;
    property Email: string read FEmail write FEmail;
    property Cargo: string read FCargo write FCargo;
    property Ativo: string read FAtivo write FAtivo;
    property SenhaHash: string read FSenhaHash write FSenhaHash;
  end;

implementation

end.
