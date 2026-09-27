unit Associado.Model;

interface

Type
TAssociadoModel = Class
  private
    Ffuncao: string;
    Frg: string;
    Fpai: string;
    Femail: string;
    Fdata_filiacao: TDate;
    Flotacao: string;
    Fnascimento: TDate;
    Fativo: string;
    Fnaturalde: string;
    Fapelido: string;
    Fcodigo: Integer;
    Fcpf: string;
    Fid_socio: Integer;
    FId: Integer;
    Ffoto: string;
    Fbloqueado: string;
    Fempresa_id: Integer;
    Fwhatsapp: string;
    Flocaltrabalho: string;
    Fnome: string;
    Fmatricula: Integer;
    Fcidade: string;
    Fexcluido: Integer;
    Fsecretaria: string;
    Fmae: string;
    Ftelefone: string;
    Fprofissao: string;
    Fcelular: string;

  public
    property id             : Integer read FId            write FId;
    property id_socio       : Integer read Fid_socio      write Fid_socio;
    property codigo         : Integer read Fcodigo        write Fcodigo;
    property matricula      : Integer read Fmatricula     write Fmatricula;
    property ativo          : string  read Fativo         write Fativo;
    property nome           : string  read Fnome          write Fnome;
    property apelido        : string  read Fapelido       write Fapelido;
    property telefone       : string  read Ftelefone      write Ftelefone;
    property celular        : string  read Fcelular       write Fcelular;
    property whatsapp       : string  read Fwhatsapp      write Fwhatsapp;
    property cpf            : string  read Fcpf           write Fcpf;
    property nascimento     : TDate   read Fnascimento    write Fnascimento;
    property email          : string  read Femail         write Femail;
    property cidade         : string  read Fcidade        write Fcidade;
    property secretaria     : string  read Fsecretaria    write Fsecretaria;
    property profissao      : string  read Fprofissao     write Fprofissao;
    property lotacao        : string  read Flotacao       write Flotacao;
    property localtrabalho  : string  read Flocaltrabalho write Flocaltrabalho;
    property funcao         : string  read Ffuncao        write Ffuncao;
    property naturalde      : string  read Fnaturalde     write Fnaturalde;
    property rg             : string  read Frg            write Frg;
    property data_filiacao  : TDate   read Fdata_filiacao write Fdata_filiacao;
    property pai            : string  read Fpai           write Fpai;
    property mae            : string  read Fmae           write Fmae;
    property foto           : string  read Ffoto          write Ffoto;
    property bloqueado      : string  read Fbloqueado     write Fbloqueado;
    property excluido       : Integer read Fexcluido      write Fexcluido;
    property empresa_id     : Integer  read Fempresa_id    write Fempresa_id;


End;

implementation

end.
