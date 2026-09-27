unit Cupom.Model;

interface

uses
  System.SysUtils;

type
  TCupomModel = class
  private
    Flimite_por_cliente: integer;
    Fdata_fim: Tdate;
    Fdata_inicio: Tdate;
    Fativo: String;
    Fdescricao: string;
    Fvalor_minimo_pedido: double;
    Fcodigo: String;
    Fid_cupom: Int64;
    Ftipo_desconto: string;
    Fid_empresa: Int64;
    Flimite_total: integer;
    Fvalor_desconto: double;
    Fvalor_maximo_desconto: double;
    Fquantidade_utilizada: integer;

  public
    property id_cupom               :Int64    read  Fid_cupom               write Fid_cupom;
    property id_empresa             :Int64    read  Fid_empresa             write Fid_empresa;
    property codigo                 :String   read  Fcodigo                 write Fcodigo;
    property descricao              :string   read  Fdescricao              write Fdescricao;
    property tipo_desconto          :string   read  Ftipo_desconto          write Ftipo_desconto;
    property valor_desconto         :double   read  Fvalor_desconto         write Fvalor_desconto;
    property valor_minimo_pedido    :double   read  Fvalor_minimo_pedido    write Fvalor_minimo_pedido;
    property valor_maximo_desconto  :double   read  Fvalor_maximo_desconto  write Fvalor_maximo_desconto;
    property limite_total           :integer  read  Flimite_total           write Flimite_total;
    property quantidade_utilizada   :integer  read  Fquantidade_utilizada   write Fquantidade_utilizada;
    property limite_por_cliente     :integer  read  Flimite_por_cliente     write Flimite_por_cliente;
    property data_inicio            :Tdate    read  Fdata_inicio            write Fdata_inicio;
    property data_fim               :Tdate    read  Fdata_fim               write Fdata_fim;
    property ativo                  :String   read  Fativo                  write Fativo;

end;

implementation

end.
