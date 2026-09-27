unit Assinatura.Model;

interface

uses
  System.SysUtils;

type
  TAssinaturaModel = class
  private
    FIdAssinatura: Int64;
    FIdEmpresa: Int64;
    FIdPlano: Int64;
    FRecorrencia: string;
    FSituacao: string;
    FIniciadoEm: TDateTime;
    FTrialTerminaEm: TDateTime;
    FProximoVencimento: TDateTime;
    FCanceladoEm: TDateTime;
    FTerminaEm: TDateTime;
    FValor: Currency;
    FObservacao: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdAssinatura: Int64 read FIdAssinatura write FIdAssinatura;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdPlano: Int64 read FIdPlano write FIdPlano;
    property Recorrencia: string read FRecorrencia write FRecorrencia;
    property Situacao: string read FSituacao write FSituacao;
    property IniciadoEm: TDateTime read FIniciadoEm write FIniciadoEm;
    property TrialTerminaEm: TDateTime read FTrialTerminaEm write FTrialTerminaEm;
    property ProximoVencimento: TDateTime read FProximoVencimento write FProximoVencimento;
    property CanceladoEm: TDateTime read FCanceladoEm write FCanceladoEm;
    property TerminaEm: TDateTime read FTerminaEm write FTerminaEm;
    property Valor: Currency read FValor write FValor;
    property Observacao: string read FObservacao write FObservacao;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
