unit EleicaoRelatorioAPI.Dao;

interface

uses
  Uni,
  System.SysUtils,
  System.Generics.Collections;

type
  TEleicaoRelatorioEleitor = record
    IdUsuario: Integer;
    IdPessoa: Integer;
    Matricula: Integer;
    Nome: string;
    CPF: string;
    Email: string;
    Whatsapp: string;
    Votou: string;
    VotadoEm: TDateTime;
    TemVotadoEm: Boolean;
  end;

  TEleicaoRelatorioListaEleitores = TList<TEleicaoRelatorioEleitor>;

  TEleicaoRelatorioAPIDao = class
  public
    class procedure BuscarEleitores(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const ASituacao: string;
      const ALista: TEleicaoRelatorioListaEleitores
    ); static;
  end;

implementation

{ TEleicaoRelatorioAPIDao }

class procedure TEleicaoRelatorioAPIDao.BuscarEleitores(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const ASituacao: string;
  const ALista: TEleicaoRelatorioListaEleitores);
var
  Qry: TUniQuery;
  Item: TEleicaoRelatorioEleitor;
  Situacao: string;
begin
  ALista.Clear;

  Situacao := UpperCase(Trim(ASituacao));

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      '  u.id AS usuario_id, ' +
      '  p.id AS pessoa_id, ' +
      '  p.matricula, ' +
      '  p.nome, ' +
      '  p.cpf, ' +
      '  p.email, ' +
      '  p.whatsapp, ' +
      '  CASE WHEN ev.usuario_id IS NOT NULL THEN ''S'' ELSE ''N'' END AS votou, ' +
      '  ev.votado_em ' +
      'FROM usuario u ' +
      'INNER JOIN pessoa p ON ' +
      '  p.id = u.pessoa_id ' +
      '  AND p.empresa_id = u.empresa_id ' +
      'LEFT JOIN eleicao_votante ev ON ' +
      '  ev.empresa_id = u.empresa_id ' +
      '  AND ev.eleicao_id = :ideleicao ' +
      '  AND ev.usuario_id = u.id ' +
      '  AND ev.votou = ''S'' ' +
      'WHERE u.empresa_id = :idempresa ' +
      '  AND u.ativo = ''S'' ' +
      '  AND p.ativo = ''S'' ' +
      '  AND COALESCE(p.bloqueado, ''N'') = ''N'' ' +
      '  AND COALESCE(p.excluido, 0) = 0 ';

    if Situacao = 'VOTARAM' then
      Qry.SQL.Add('AND ev.usuario_id IS NOT NULL ')
    else
    if Situacao = 'NAO_VOTARAM' then
      Qry.SQL.Add('AND ev.usuario_id IS NULL ');

    Qry.SQL.Add('ORDER BY p.nome, p.matricula');

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;

    Qry.Open;

    while not Qry.Eof do
    begin
      Item := Default(TEleicaoRelatorioEleitor);

      Item.IdUsuario := Qry.FieldByName('usuario_id').AsInteger;
      Item.IdPessoa := Qry.FieldByName('pessoa_id').AsInteger;
      Item.Matricula := Qry.FieldByName('matricula').AsInteger;
      Item.Nome := Qry.FieldByName('nome').AsString;
      Item.CPF := Qry.FieldByName('cpf').AsString;
      Item.Email := Qry.FieldByName('email').AsString;
      Item.Whatsapp := Qry.FieldByName('whatsapp').AsString;
      Item.Votou := Qry.FieldByName('votou').AsString;

      Item.TemVotadoEm := not Qry.FieldByName('votado_em').IsNull;

      if Item.TemVotadoEm then
        Item.VotadoEm := Qry.FieldByName('votado_em').AsDateTime;

      ALista.Add(Item);

      Qry.Next;
    end;

  finally
    Qry.Free;
  end;
end;

end.
