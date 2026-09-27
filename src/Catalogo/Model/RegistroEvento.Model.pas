unit RegistroEvento.Model;

interface

uses
  System.SysUtils;

type
  TRegistroEventoModel = class
  private
    FIdRegistro: Int64;
    FIdEmpresa: Int64;
    FIdUsuario: Int64;
    FOrigem: string;
    FTipo: string;
    FEntidade: string;
    FIdEntidade: Int64;
    FTitulo: string;
    FMensagem: string;
    FDadosJson: string;
    FNivel: string;
    FDataCriacao: TDateTime;
  public
    property IdRegistro: Int64 read FIdRegistro write FIdRegistro;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdUsuario: Int64 read FIdUsuario write FIdUsuario;
    property Origem: string read FOrigem write FOrigem;
    property Tipo: string read FTipo write FTipo;
    property Entidade: string read FEntidade write FEntidade;
    property IdEntidade: Int64 read FIdEntidade write FIdEntidade;
    property Titulo: string read FTitulo write FTitulo;
    property Mensagem: string read FMensagem write FMensagem;
    property DadosJson: string read FDadosJson write FDadosJson;
    property Nivel: string read FNivel write FNivel;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
  end;

implementation

end.
