unit Unidade.DAO;

interface

uses
  Uni,
  Unidade.Model,
  System.Generics.Collections;

type
  TUnidadeDAO = class
  public
    class function ListarAtivas(const AConn: TUniConnection): TObjectList<TUnidadeModel>; static;
  end;

implementation

uses
  System.SysUtils;

procedure PreencherModel(const Qry: TUniQuery; const AUnidade: TUnidadeModel);
begin
  AUnidade.IdUnidade    := Qry.FieldByName('id_unidade').AsLargeInt;
  AUnidade.Sigla        := Qry.FieldByName('sigla').AsString;
  AUnidade.Descricao    := Qry.FieldByName('descricao').AsString;
  AUnidade.Ativo        := Qry.FieldByName('ativo').AsString;
  AUnidade.DataCriacao  := Qry.FieldByName('data_criacao').AsDateTime;

  if not Qry.FieldByName('data_alteracao').IsNull then
    AUnidade.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;
end;

class function TUnidadeDAO.ListarAtivas(const AConn: TUniConnection): TObjectList<TUnidadeModel>;
var
  Qry: TUniQuery;
  Unidade: TUnidadeModel;
begin
  Result := TObjectList<TUnidadeModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select ' +
      ' id_unidade, sigla, descricao, ativo, data_criacao, data_alteracao ' +
      ' from unidade ' +
      ' where ativo = ''S'' ' +
      ' order by sigla';

    Qry.Open;

    while not Qry.Eof do
    begin
      Unidade := TUnidadeModel.Create;
      PreencherModel(Qry, Unidade);
      Result.Add(Unidade);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

end.
