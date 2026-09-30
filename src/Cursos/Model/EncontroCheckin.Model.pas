unit EncontroCheckin.Model;

interface

uses
  System.Generics.Collections;

type
  TEncontroCheckinInfo = record
    IdTurma, IdEncontro, IdInscricao, IdPresenca: Int64;
    Titulo, TurmaNome, Situacao, Token, Tipo: string;
    Aberto, JaRegistrada: Boolean;
    SegundosRestantes: Integer;
    ExpiraEm, CheckinEm: TDateTime;
  end;

  TTurmaPresencaItem = class
  public
    IdInscricao: Int64;
    IdParticipante: Int64;
    ParticipanteNome: string;
    ParticipanteEmail: string;
    SituacaoInscricao: string;
    SituacaoPresenca: string;
    TemPresenca: Boolean;
    CheckinEm: TDateTime;
    TemCheckinEm: Boolean;
    Origem: string;
  end;

  TTurmaPresencaLista = class
  public
    Itens: TObjectList<TTurmaPresencaItem>;
    TotalMatriculados: Integer;
    TotalPresentes: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TTurmaPresencaLista.Create;
begin
  inherited;
  Itens := TObjectList<TTurmaPresencaItem>.Create(True);
end;

destructor TTurmaPresencaLista.Destroy;
begin
  Itens.Free;
  inherited;
end;

end.
