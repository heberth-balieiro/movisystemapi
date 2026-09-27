unit EleicaoLoginAPI.Dao;

interface

uses
  System.SysUtils,
  Uni,
  System.Generics.Collections,
  System.JSON;

type
  TEleicaoUsuarioLoginDTO = record
    IdUsuario: Integer;
    IdPessoa: Integer;
    IdEmpresa: Integer;
    Nome: string;
    Perfil:String;
end;

Type
TEleicaoLoginAPIDao = Class
  private

  public
    class function BuscarUsuarioAtivo(const AConn: TUniConnection;
      const AIdEmpresa: Integer; const ACPF: string; const AMatricula: Integer;
      out AUsuario: TEleicaoUsuarioLoginDTO): Boolean; static;

    class function BuscarSlugID(const AConn: TUniConnection; const ASlug: string; out AIDEleicao: integer): Integer; static;
End;

implementation

{ TEleicaoLoginAPIDao }

class function TEleicaoLoginAPIDao.BuscarSlugID(const AConn: TUniConnection; const ASlug: string; Out AIDEleicao: integer): Integer;
var
  Qry         : TUniQuery;
const
  StrSqlA = 'Select empresa_id, slug, eleicao_id from eleicao_configuracao where  '+
            ' LOWER(TRIM(slug)) = LOWER(TRIM(:slug)) limit 1 ';
begin
  Result      := 0;
  AIDEleicao  := 0;
  Qry         := TUniQuery.Create(nil);

  try
    Qry.Connection          := AConn;
    Qry.SQL.Text            := StrSqlA;
    Qry.Params.ParamByName('slug').AsString         := Trim(ASlug);
    Qry.Open;

    Result      := Qry.FieldByName('empresa_id').AsInteger;
    AIDEleicao  := Qry.FieldByName('eleicao_id').AsInteger;
  finally
    Qry.Free;
  end;
end;


class function TEleicaoLoginAPIDao.BuscarUsuarioAtivo(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const ACPF: string;
  const AMatricula: Integer;
  out AUsuario: TEleicaoUsuarioLoginDTO
): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =
    'SELECT ' +
    '  u.id AS id_usuario, ' +
    '  u.empresa_id, ' +
    '  u.perfil,  '+
    '  p.id AS id_pessoa, ' +
    '  p.nome, ' +
    '  p.cpf, ' +
    '  p.matricula ' +
    'FROM pessoa p ' +
    'INNER JOIN usuario u ON ' +
    '  u.pessoa_id = p.id ' +
    '  AND u.empresa_id = p.empresa_id ' +
    'WHERE p.empresa_id = :idempresa ' +
    '  AND p.cpf = :cpf ' +
    '  AND p.matricula = :matricula ' +
    '  AND p.ativo = ''S'' ' +
    '  AND p.excluido = 0 ' +
    '  AND p.bloqueado = ''N'' ' +
    '  AND u.ativo = ''S'' ' +
    'LIMIT 1';
begin
  Result := False;

  AUsuario.IdUsuario := 0;
  AUsuario.IdPessoa  := 0;
  AUsuario.IdEmpresa := 0;
  AUsuario.Nome      := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.Params.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.Params.ParamByName('cpf').AsString        := Trim(ACPF);
    Qry.Params.ParamByName('matricula').AsInteger := AMatricula;

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AUsuario.IdUsuario :=
      Qry.FieldByName('id_usuario').AsInteger;

    AUsuario.IdPessoa :=
      Qry.FieldByName('id_pessoa').AsInteger;

    AUsuario.IdEmpresa :=
      Qry.FieldByName('empresa_id').AsInteger;

    AUsuario.Nome :=
      Qry.FieldByName('nome').AsString;

    AUsuario.Perfil :=
      Qry.FieldByName('perfil').AsString;

    Result := True;

  finally
    Qry.Free;
  end;
end;



end.
