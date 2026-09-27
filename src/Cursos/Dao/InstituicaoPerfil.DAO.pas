unit InstituicaoPerfil.DAO;

interface

uses
  Uni,
  System.Generics.Collections,
  InstituicaoPerfil.Model;

type
  TInstituicaoPerfilDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoPerfilFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoPerfilFiltro
    ); static;

    class function MapearPerfil(
      const AQry: TUniQuery
    ): TInstituicaoPerfilItem; static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoPerfilFiltro
    ): TInstituicaoPerfilLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdPerfil: Int64
    ): TInstituicaoPerfilItem; static;

    class function ExisteNome(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ANome: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoPerfilCadastro
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdPerfil: Int64;
      const ADados: TInstituicaoPerfilAlteracao
    ); static;

    class procedure AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdPerfil: Int64;
      const ASituacao: string
    ); static;

    class function ListarPermissoes(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdPerfil: Int64
    ): TObjectList<TInstituicaoPermissaoItem>; static;

    class function ExistePermissaoAtiva(
      const AConn: TUniConnection;
      const AIdPermissao: Int64
    ): Boolean; static;

    class procedure SubstituirPermissoes(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdPerfil: Int64;
      const APermissoes: TArray<Int64>
    ); static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuario,
            AIdUsuarioInstituicao,
            AIdPerfil: Int64;
      const AAcao,
            AMetodo,
            ARota,
            AMensagem,
            AIP,
            AUserAgent: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoPerfilDAO.MontarWhere(
  const AFiltro: TInstituicaoPerfilFiltro
): string;
begin
  Result :=
    ' WHERE p.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result :=
      Result +
      ' AND (p.nome LIKE :busca OR p.descricao LIKE :busca) ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result :=
      Result +
      ' AND p.situacao = :situacao ';
end;

class procedure TInstituicaoPerfilDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoPerfilFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt :=
    AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString :=
      UpperCase(Trim(AFiltro.Situacao));
end;

class function TInstituicaoPerfilDAO.MapearPerfil(
  const AQry: TUniQuery
): TInstituicaoPerfilItem;
begin
  Result := TInstituicaoPerfilItem.Create;

  Result.Id :=
    AQry.FieldByName('id').AsLargeInt;

  Result.Nome :=
    AQry.FieldByName('nome').AsString;

  Result.Descricao :=
    AQry.FieldByName('descricao').AsString;

  Result.Sistema :=
    AQry.FieldByName('sistema').AsInteger = 1;

  Result.Situacao :=
    AQry.FieldByName('situacao').AsString;

  Result.QuantidadePermissoes :=
    AQry.FieldByName('quantidade_permissoes').AsInteger;

  Result.CriadoEm :=
    AQry.FieldByName('criado_em').AsDateTime;

  Result.AtualizadoEm :=
    AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoPerfilDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoPerfilFiltro
): TInstituicaoPerfilLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TInstituicaoPerfilLista.Create;
  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;

      WhereSQL :=
        MontarWhere(AFiltro);

      Offset :=
        (AFiltro.Pagina - 1) *
        AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM perfil p ' +
        WhereSQL;

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.Open;

      Result.Total :=
        Qry.FieldByName('total').AsInteger;

      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'p.id, p.nome, p.descricao, p.sistema, p.situacao, ' +
        'p.criado_em, p.atualizado_em, ' +
        '(SELECT COUNT(*) ' +
        '   FROM perfil_permissao pp ' +
        '  WHERE pp.id_instituicao = p.id_instituicao ' +
        '    AND pp.id_perfil = p.id) AS quantidade_permissoes ' +
        'FROM perfil p ' +
        WhereSQL +
        'ORDER BY p.sistema DESC, p.nome, p.id ' +
        'LIMIT :limite OFFSET :offset';

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.ParamByName('limite').AsInteger :=
        AFiltro.PorPagina;

      Qry.ParamByName('offset').AsInteger :=
        Offset;

      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Itens.Add(
          MapearPerfil(Qry)
        );

        Qry.Next;
      end;

    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPerfilDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdPerfil: Int64
): TInstituicaoPerfilItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'p.id, p.nome, p.descricao, p.sistema, p.situacao, ' +
      'p.criado_em, p.atualizado_em, ' +
      '(SELECT COUNT(*) ' +
      '   FROM perfil_permissao pp ' +
      '  WHERE pp.id_instituicao = p.id_instituicao ' +
      '    AND pp.id_perfil = p.id) AS quantidade_permissoes ' +
      'FROM perfil p ' +
      'WHERE p.id_instituicao = :id_instituicao ' +
      '  AND p.id = :id_perfil ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_perfil').AsLargeInt :=
      AIdPerfil;

    Qry.Open;

    if not Qry.IsEmpty then
      Result :=
        MapearPerfil(Qry);
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPerfilDAO.ExisteNome(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ANome: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM perfil ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND nome = :nome ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add(
        'AND id <> :id_ignorar '
      );

    Qry.SQL.Add(
      'LIMIT 1'
    );

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('nome').AsString :=
      Trim(ANome);

    if AIdIgnorar > 0 then
      Qry.ParamByName('id_ignorar').AsLargeInt :=
        AIdIgnorar;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPerfilDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoPerfilCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO perfil ' +
      '(id_instituicao, nome, descricao, sistema, situacao) ' +
      'VALUES ' +
      '(:id_instituicao, :nome, :descricao, 0, ''ATIVO'')';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    if Trim(ADados.Descricao).IsEmpty then
      Qry.ParamByName('descricao').Clear
    else
      Qry.ParamByName('descricao').AsString :=
        ADados.Descricao;

    Qry.Execute;

    Qry.SQL.Text :=
      'SELECT LAST_INSERT_ID() AS id';

    Qry.Open;

    Result :=
      Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoPerfilDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdPerfil: Int64;
  const ADados: TInstituicaoPerfilAlteracao
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE perfil SET ' +
      'nome = :nome, ' +
      'descricao = :descricao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id = :id_perfil ' +
      '  AND sistema = 0';

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    if Trim(ADados.Descricao).IsEmpty then
      Qry.ParamByName('descricao').Clear
    else
      Qry.ParamByName('descricao').AsString :=
        ADados.Descricao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_perfil').AsLargeInt :=
      AIdPerfil;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoPerfilDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdPerfil: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE perfil SET ' +
      'situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id = :id_perfil ' +
      '  AND sistema = 0';

    Qry.ParamByName('situacao').AsString :=
      ASituacao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_perfil').AsLargeInt :=
      AIdPerfil;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPerfilDAO.ListarPermissoes(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdPerfil: Int64
): TObjectList<TInstituicaoPermissaoItem>;
var
  Qry: TUniQuery;
  Item: TInstituicaoPermissaoItem;
begin
  Result :=
    TObjectList<TInstituicaoPermissaoItem>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT ' +
        'pe.id, pe.codigo, pe.modulo, pe.descricao, pe.situacao, ' +
        'CASE WHEN pp.id_permissao IS NULL THEN 0 ELSE 1 END AS selecionada ' +
        'FROM permissao pe ' +
        'LEFT JOIN perfil_permissao pp ' +
        '  ON pp.id_permissao = pe.id ' +
        ' AND pp.id_instituicao = :id_instituicao ' +
        ' AND pp.id_perfil = :id_perfil ' +
        'WHERE pe.situacao = ''ATIVA'' ' +
        'ORDER BY pe.modulo, pe.descricao, pe.codigo';

      Qry.ParamByName('id_instituicao').AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName('id_perfil').AsLargeInt :=
        AIdPerfil;

      Qry.Open;

      while not Qry.Eof do
      begin
        Item :=
          TInstituicaoPermissaoItem.Create;

        Item.Id :=
          Qry.FieldByName('id').AsLargeInt;

        Item.Codigo :=
          Qry.FieldByName('codigo').AsString;

        Item.Modulo :=
          Qry.FieldByName('modulo').AsString;

        Item.Descricao :=
          Qry.FieldByName('descricao').AsString;

        Item.Situacao :=
          Qry.FieldByName('situacao').AsString;

        Item.Selecionada :=
          Qry.FieldByName('selecionada').AsInteger = 1;

        Result.Add(Item);

        Qry.Next;
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPerfilDAO.ExistePermissaoAtiva(
  const AConn: TUniConnection;
  const AIdPermissao: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if AIdPermissao <= 0 then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM permissao ' +
      'WHERE id = :id_permissao ' +
      '  AND situacao = ''ATIVA'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_permissao').AsLargeInt :=
      AIdPermissao;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoPerfilDAO.SubstituirPermissoes(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdPerfil: Int64;
  const APermissoes: TArray<Int64>
);
var
  Qry: TUniQuery;
  IdPermissao: Int64;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'DELETE FROM perfil_permissao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id_perfil = :id_perfil';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_perfil').AsLargeInt :=
      AIdPerfil;

    Qry.Execute;

    for IdPermissao in APermissoes do
    begin
      Qry.SQL.Text :=
        'INSERT INTO perfil_permissao ' +
        '(id_instituicao, id_perfil, id_permissao) ' +
        'VALUES ' +
        '(:id_instituicao, :id_perfil, :id_permissao)';

      Qry.ParamByName('id_instituicao').AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName('id_perfil').AsLargeInt :=
        AIdPerfil;

      Qry.ParamByName('id_permissao').AsLargeInt :=
        IdPermissao;

      Qry.Execute;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoPerfilDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuario,
        AIdUsuarioInstituicao,
        AIdPerfil: Int64;
  const AAcao,
        AMetodo,
        ARota,
        AMensagem,
        AIP,
        AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, ' +
      'acao, entidade, registro_id, metodo_http, rota, ' +
      'ip, user_agent, sucesso, mensagem) ' +
      'VALUES ' +
      '(:id_instituicao, :id_usuario, :id_usuario_instituicao, ' +
      ':acao, ''perfil'', :registro_id, :metodo, :rota, ' +
      ':ip, :user_agent, 1, :mensagem)';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.ParamByName('acao').AsString :=
      Copy(UpperCase(Trim(AAcao)), 1, 80);

    Qry.ParamByName('registro_id').AsString :=
      AIdPerfil.ToString;

    Qry.ParamByName('metodo').AsString :=
      Copy(UpperCase(Trim(AMetodo)), 1, 10);

    Qry.ParamByName('rota').AsString :=
      Copy(Trim(ARota), 1, 500);

    Qry.ParamByName('ip').AsString :=
      Copy(Trim(AIP), 1, 45);

    Qry.ParamByName('user_agent').AsString :=
      Copy(Trim(AUserAgent), 1, 1000);

    Qry.ParamByName('mensagem').AsString :=
      Copy(Trim(AMensagem), 1, 1000);

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
