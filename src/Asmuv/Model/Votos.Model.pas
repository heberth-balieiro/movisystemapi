unit Votos.Model;

interface

uses
  System.SysUtils;

type
  TVotosModel = class
  private
    FIdVoto: Int64;
    FIdSocio: Int64;
    FIdEleicao: Int64;
    FIdCampanha: Int64;
    FToken: string;
    FVoto: Integer;
    FChave: string;
    FDataVoto: TDateTime;
    FHoraVoto: TDateTime;
    FIp: string;
    FOrdem: Integer;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdVoto: Int64 read FIdVoto write FIdVoto;
    property IdSocio: Int64 read FIdSocio write FIdSocio;
    property IdEleicao: Int64 read FIdEleicao write FIdEleicao;
    property IdCampanha: Int64 read FIdCampanha write FIdCampanha;
    property Token: string read FToken write FToken;
    property Voto: Integer read FVoto write FVoto;
    property Chave: string read FChave write FChave;
    property DataVoto: TDateTime read FDataVoto write FDataVoto;
    property HoraVoto: TDateTime read FHoraVoto write FHoraVoto;
    property Ip: string read FIp write FIp;
    property Ordem: Integer read FOrdem write FOrdem;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
