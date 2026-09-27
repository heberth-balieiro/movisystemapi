unit NotificacaoFila.Model;

interface

uses
  System.SysUtils;

type
  TNotificacaoFilaModel = class
  private
    FIdNotificacao: Int64;
    FIdEmpresa: Int64;
    FIdPedido: Int64;
    FCanal: string;
    FDestinatario: string;
    FTitulo: string;
    FMensagem: string;
    FStatus: string;
    FTentativas: Integer;
    FUltimoErro: string;
    FDataCriacao: TDateTime;
    FDataEnvio: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdNotificacao: Int64 read FIdNotificacao write FIdNotificacao;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdPedido: Int64 read FIdPedido write FIdPedido;
    property Canal: string read FCanal write FCanal;
    property Destinatario: string read FDestinatario write FDestinatario;
    property Titulo: string read FTitulo write FTitulo;
    property Mensagem: string read FMensagem write FMensagem;
    property Status: string read FStatus write FStatus;
    property Tentativas: Integer read FTentativas write FTentativas;
    property UltimoErro: string read FUltimoErro write FUltimoErro;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataEnvio: TDateTime read FDataEnvio write FDataEnvio;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
