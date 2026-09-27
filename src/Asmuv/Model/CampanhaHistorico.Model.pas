unit CampanhaHistorico.Model;

interface

uses
  System.SysUtils;

type
  TCampanhaHistoricoModel = class
  private
    FIdHistorico: Int64;
    FIdCampanha: Int64;
    FIdMembro: Int64;
    FCpfConfirmacao: string;
    FDataConfirmacao: TDateTime;
    FHoraConfirmacao: TDateTime;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdHistorico: Int64 read FIdHistorico write FIdHistorico;
    property IdCampanha: Int64 read FIdCampanha write FIdCampanha;
    property IdMembro: Int64 read FIdMembro write FIdMembro;
    property CpfConfirmacao: string read FCpfConfirmacao write FCpfConfirmacao;
    property DataConfirmacao: TDateTime read FDataConfirmacao write FDataConfirmacao;
    property HoraConfirmacao: TDateTime read FHoraConfirmacao write FHoraConfirmacao;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
