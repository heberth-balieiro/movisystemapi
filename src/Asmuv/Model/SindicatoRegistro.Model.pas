unit SindicatoRegistro.Model;

interface

uses
  System.SysUtils;

type
  TSindicatoRegistroModel = class
  private
    FIdRegistro: Int64;
    FIdCarteira: Int64;
    FDataRegistro: TDateTime;
    FHoraRegistro: TDateTime;
    FObservacao: string;
    FSincronizado: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdRegistro: Int64 read FIdRegistro write FIdRegistro;
    property IdCarteira: Int64 read FIdCarteira write FIdCarteira;
    property DataRegistro: TDateTime read FDataRegistro write FDataRegistro;
    property HoraRegistro: TDateTime read FHoraRegistro write FHoraRegistro;
    property Observacao: string read FObservacao write FObservacao;
    property Sincronizado: string read FSincronizado write FSincronizado;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
