unit Notificacao.Model;

interface

uses
  System.SysUtils;

type
  TNotificacaoModel = class
  private
    FIdNotificacao: Int64;
    FIdEmpresa: Int64;
    FIdSocio: Int64;

    FTipo: Integer;
    FTitulo: string;
    FMensagem: string;

    FDataCriacaoNotificacao: TDateTime;
    FHoraCriacaoNotificacao: TDateTime;
    FDataEnvio: TDateTime;
    FHoraEnvio: TDateTime;
    FRetornoEnvio: string;

    FPublico: string;
    FFoto: TBytes;
    FAtivo: string;

    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdNotificacao: Int64 read FIdNotificacao write FIdNotificacao;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdSocio: Int64 read FIdSocio write FIdSocio;

    property Tipo: Integer read FTipo write FTipo;
    property Titulo: string read FTitulo write FTitulo;
    property Mensagem: string read FMensagem write FMensagem;

    property DataCriacaoNotificacao: TDateTime read FDataCriacaoNotificacao write FDataCriacaoNotificacao;
    property HoraCriacaoNotificacao: TDateTime read FHoraCriacaoNotificacao write FHoraCriacaoNotificacao;
    property DataEnvio: TDateTime read FDataEnvio write FDataEnvio;
    property HoraEnvio: TDateTime read FHoraEnvio write FHoraEnvio;
    property RetornoEnvio: string read FRetornoEnvio write FRetornoEnvio;

    property Publico: string read FPublico write FPublico;
    property Foto: TBytes read FFoto write FFoto;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
