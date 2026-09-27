unit NotificacaoLida.Model;

interface

uses
  System.SysUtils;

type
  TNotificacaoLidaModel = class
  private
    FIdNotificacaoLida: Int64;
    FIdNotificacao: Int64;
    FIdCarteira: Int64;
    FDataLeitura: TDateTime;
    FHoraLeitura: TDateTime;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdNotificacaoLida: Int64 read FIdNotificacaoLida write FIdNotificacaoLida;
    property IdNotificacao: Int64 read FIdNotificacao write FIdNotificacao;
    property IdCarteira: Int64 read FIdCarteira write FIdCarteira;
    property DataLeitura: TDateTime read FDataLeitura write FDataLeitura;
    property HoraLeitura: TDateTime read FHoraLeitura write FHoraLeitura;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
