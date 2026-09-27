unit Emp.Model;

interface

Type
TEmpresasModel = class
  private
    Ffantasia: string;
    Fativo: string;
    Fuuid: string;
    Fcpfcnpj: string;
    Fid: Int64;
    Fid_empresa: Integer;
    Ftelefone: string;
    Frazao: string;
    Fwhatsapp_url: string;
    Fwhatsapp_instancia: string;
    Feasyone_integracao_ativo: string;
    Feasyone_api_key_hash: string;
    Fwhatsapp_token: string;

  public
    property id                 : Int64   read Fid                  write Fid;
    property id_empresa         : Integer read Fid_empresa          write Fid_empresa;
    property uuid               : string  read Fuuid                write Fuuid;
    property razao              : string  read Frazao               write Frazao;
    property fantasia           : string  read Ffantasia            write Ffantasia;
    property telefone           : string  read Ftelefone            write Ftelefone;
    property ativo              : string  read Fativo               write Fativo;
    property cpfcnpj            : string  read Fcpfcnpj             write Fcpfcnpj;

    property whatsapp_url            : string  read Fwhatsapp_url             write Fwhatsapp_url;
    property whatsapp_instancia      : string  read Fwhatsapp_instancia       write Fwhatsapp_instancia;
    property whatsapp_token          : string  read Fwhatsapp_token           write Fwhatsapp_token;

    property easyone_api_key_hash    : string  read Feasyone_api_key_hash     write Feasyone_api_key_hash;
    property easyone_integracao_ativo: string  read Feasyone_integracao_ativo write Feasyone_integracao_ativo;


end;

implementation

end.
