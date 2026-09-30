unit EncontroCheckin.Model;

interface

type
  TEncontroCheckinInfo = record
    IdTurma, IdEncontro, IdInscricao, IdPresenca: Int64;
    Titulo, TurmaNome, Situacao, Token, Tipo: string;
    Aberto, JaRegistrada: Boolean;
    SegundosRestantes: Integer;
    ExpiraEm, CheckinEm: TDateTime;
  end;

implementation
end.
