unit PlataformaUsuario.Model;

interface

uses
  System.SysUtils;

type
  TPlataformaUsuarioModel = class
  private
    FId: Int64;
    FNome: string;
    FEmail: string;
    FSituacao: string;
    FCriadoEm: TDateTime;
    FUltimoLoginEm: TDateTime;
    FTemUltimoLogin: Boolean;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property Situacao: string read FSituacao write FSituacao;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property UltimoLoginEm: TDateTime read FUltimoLoginEm write FUltimoLoginEm;
    property TemUltimoLogin: Boolean read FTemUltimoLogin write FTemUltimoLogin;
  end;

implementation

end.
