unit PlataformaIdentidade.DAO;

interface

uses
  Uni,
  PlataformaIdentidade.Model;

type
  TPlataformaIdentidadeDAO = class
  public
    class function Buscar(const AConn: TUniConnection): TPlataformaIdentidadeConfig; static;
    class procedure Salvar(
      const AConn: TUniConnection;
      const ADados: TPlataformaIdentidadeInput;
      const AIdUsuario: Int64
    ); static;
    class procedure AtualizarLogo(
      const AConn: TUniConnection;
      const ALogoUrl: string;
      const AIdUsuario: Int64
    ); static;
    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const AAcao, AMensagem, AIP, AUserAgent: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TPlataformaIdentidadeDAO.Buscar(
  const AConn: TUniConnection
): TPlataformaIdentidadeConfig;
var Q: TUniQuery;
begin
  Result := Default(TPlataformaIdentidadeConfig);
  Result.NomePlataforma := 'MoviSystem';
  Result.TituloLogin := 'Administração';
  Result.SubtituloLogin := 'Acesso MoviSystem';
  Result.TituloDestaqueLogin := 'Gerencie todos os clientes da plataforma em um único ambiente.';
  Result.DescricaoLogin := 'Cadastre instituições, acompanhe implantação, utilização e situação operacional de cada tenant.';

  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT nome_plataforma,titulo_login,subtitulo_login,titulo_destaque_login,' +
      'descricao_login,logo_url FROM plataforma_identidade_configuracao WHERE id=1';
    Q.Open;
    if Q.IsEmpty then Exit;

    Result.NomePlataforma := Q.FieldByName('nome_plataforma').AsString;
    Result.TituloLogin := Q.FieldByName('titulo_login').AsString;
    Result.SubtituloLogin := Q.FieldByName('subtitulo_login').AsString;
    Result.TituloDestaqueLogin := Q.FieldByName('titulo_destaque_login').AsString;
    Result.DescricaoLogin := Q.FieldByName('descricao_login').AsString;
    Result.LogoUrl := Q.FieldByName('logo_url').AsString;
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaIdentidadeDAO.Salvar(
  const AConn: TUniConnection;
  const ADados: TPlataformaIdentidadeInput;
  const AIdUsuario: Int64
);
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO plataforma_identidade_configuracao ' +
      '(id,nome_plataforma,titulo_login,subtitulo_login,titulo_destaque_login,descricao_login,atualizado_por) ' +
      'VALUES (1,:nome,:titulo,:subtitulo,:destaque,:descricao,:usuario) ' +
      'ON DUPLICATE KEY UPDATE nome_plataforma=VALUES(nome_plataforma),' +
      'titulo_login=VALUES(titulo_login),subtitulo_login=VALUES(subtitulo_login),' +
      'titulo_destaque_login=VALUES(titulo_destaque_login),descricao_login=VALUES(descricao_login),' +
      'atualizado_por=VALUES(atualizado_por)';
    Q.ParamByName('nome').AsString := ADados.NomePlataforma;
    Q.ParamByName('titulo').AsString := ADados.TituloLogin;
    Q.ParamByName('subtitulo').AsString := ADados.SubtituloLogin;
    Q.ParamByName('destaque').AsString := ADados.TituloDestaqueLogin;
    Q.ParamByName('descricao').AsString := ADados.DescricaoLogin;
    Q.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Q.ExecSQL;
  finally Q.Free; end;
end;

class procedure TPlataformaIdentidadeDAO.AtualizarLogo(
  const AConn: TUniConnection;
  const ALogoUrl: string;
  const AIdUsuario: Int64
);
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO plataforma_identidade_configuracao (id,logo_url,atualizado_por) ' +
      'VALUES (1,:logo,:usuario) ON DUPLICATE KEY UPDATE logo_url=VALUES(logo_url), atualizado_por=VALUES(atualizado_por)';
    Q.ParamByName('logo').AsString := ALogoUrl;
    Q.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Q.ExecSQL;
  finally Q.Free; end;
end;

class procedure TPlataformaIdentidadeDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const AAcao, AMensagem, AIP, AUserAgent: string
);
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO auditoria_log (id_instituicao,id_usuario,id_usuario_instituicao,acao,entidade,registro_id,' +
      'metodo_http,rota,ip,user_agent,sucesso,mensagem) VALUES ' +
      '(NULL,:usuario,NULL,:acao,''plataforma_identidade_configuracao'',''1'',''PUT'',' +
      '''/v1/certifica/plataforma/configuracoes/identidade'',:ip,:ua,1,:mensagem)';
    Q.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Q.ParamByName('acao').AsString := AAcao;
    Q.ParamByName('ip').AsString := Copy(Trim(AIP),1,45);
    Q.ParamByName('ua').AsString := Copy(Trim(AUserAgent),1,1000);
    Q.ParamByName('mensagem').AsString := Copy(AMensagem,1,1000);
    Q.ExecSQL;
  finally Q.Free; end;
end;

end.
