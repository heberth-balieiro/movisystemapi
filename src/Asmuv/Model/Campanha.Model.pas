unit Campanha.Model;

interface

uses
  System.SysUtils;

type
  TCampanhaModel = class
  private
    FIdCampanha: Int64;
    FIdEmpresa: Int64;
    FIdEleicao: Int64;
    FCodigo: Integer;

    FDataInicio: TDateTime;
    FHoraInicio: TDateTime;
    FDataFinal: TDateTime;
    FHoraFinal: TDateTime;

    FDetalhes: string;
    FPublicada: string;
    FConcluida: string;
    FAuditoria: string;
    FFechamentoAutomatico: string;

    FToken: string;
    FChaveKey: string;
    FChaveKeyAlt: string;
    FChaveKeyPublicar: string;
    FChaveKeyDespublicar: string;
    FChaveKeyEncerramento: string;

    FDataHoraPublicacao: TDateTime;
    FDataHoraFechamento: TDateTime;
    FDataHoraDespublicacao: TDateTime;

    FAnexo: TBytes;
    FAnexoFormato: string;
    FAtivo: string;

    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdCampanha: Int64 read FIdCampanha write FIdCampanha;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdEleicao: Int64 read FIdEleicao write FIdEleicao;
    property Codigo: Integer read FCodigo write FCodigo;

    property DataInicio: TDateTime read FDataInicio write FDataInicio;
    property HoraInicio: TDateTime read FHoraInicio write FHoraInicio;
    property DataFinal: TDateTime read FDataFinal write FDataFinal;
    property HoraFinal: TDateTime read FHoraFinal write FHoraFinal;

    property Detalhes: string read FDetalhes write FDetalhes;
    property Publicada: string read FPublicada write FPublicada;
    property Concluida: string read FConcluida write FConcluida;
    property Auditoria: string read FAuditoria write FAuditoria;
    property FechamentoAutomatico: string read FFechamentoAutomatico write FFechamentoAutomatico;

    property Token: string read FToken write FToken;
    property ChaveKey: string read FChaveKey write FChaveKey;
    property ChaveKeyAlt: string read FChaveKeyAlt write FChaveKeyAlt;
    property ChaveKeyPublicar: string read FChaveKeyPublicar write FChaveKeyPublicar;
    property ChaveKeyDespublicar: string read FChaveKeyDespublicar write FChaveKeyDespublicar;
    property ChaveKeyEncerramento: string read FChaveKeyEncerramento write FChaveKeyEncerramento;

    property DataHoraPublicacao: TDateTime read FDataHoraPublicacao write FDataHoraPublicacao;
    property DataHoraFechamento: TDateTime read FDataHoraFechamento write FDataHoraFechamento;
    property DataHoraDespublicacao: TDateTime read FDataHoraDespublicacao write FDataHoraDespublicacao;

    property Anexo: TBytes read FAnexo write FAnexo;
    property AnexoFormato: string read FAnexoFormato write FAnexoFormato;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
