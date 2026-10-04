unit Eleicao.Seeds;

interface

type
  TEleicaoSeeds = class
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  Uni,
  App.Config,
  Database.Connection,
  Auth.Passwords;

function BuscarId(const AConn: TUniConnection; const ASQL: string): Integer;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := ASQL;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.Fields[0].AsInteger;
  finally
    Qry.Free;
  end;
end;

procedure ExecSQL(const AConn: TUniConnection; const ASQL: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := ASQL;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

procedure GarantirEmpresa(const AConn: TUniConnection);
begin
  ExecSQL(AConn,
    'INSERT INTO empresa '+
    '(id_empresa,uuid,razao,fantasia,telefone,ativo,cpfcnpj,easyone_integracao_ativo) '+
    'SELECT 990001,''11111111-2222-3333-4444-555555555555'','+
    '''Empresa Demo Eleitoral LTDA'',''Empresa Demo Eleitoral'',''11999990000'',''S'','+
    '''99999999000199'',''N'' '+
    'WHERE NOT EXISTS (SELECT 1 FROM empresa WHERE id_empresa=990001)'
  );
end;

procedure GarantirPessoa(const AConn: TUniConnection;
  const AIdSocio, ACodigo, AMatricula: Integer;
  const ANome, ACPF, AEmail: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO pessoa '+
      '(id_socio,codigo,matricula,ativo,nome,cpf,email,bloqueado,excluido,empresa_id) '+
      'SELECT :id_socio,:codigo,:matricula,''S'',:nome,:cpf,:email,''N'',0,e.id '+
      'FROM empresa e '+
      'WHERE e.id_empresa=990001 '+
      'AND NOT EXISTS ('+
      '  SELECT 1 FROM pessoa p '+
      '  WHERE p.empresa_id=e.id AND p.id_socio=:id_socio_check'+
      ')';

    Qry.ParamByName('id_socio').AsInteger := AIdSocio;
    Qry.ParamByName('codigo').AsInteger := ACodigo;
    Qry.ParamByName('matricula').AsInteger := AMatricula;
    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('cpf').AsString := ACPF;
    Qry.ParamByName('email').AsString := AEmail;
    Qry.ParamByName('id_socio_check').AsInteger := AIdSocio;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

procedure GarantirUsuarioPessoa(const AConn: TUniConnection;
  const AIdSocio, AIdEleitorInt: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO usuario '+
      '(empresa_id,pessoa_id,nome,login,senha_hash,ativo,email,perfil,id_eleitor_int) '+
      'SELECT p.empresa_id,p.id,p.nome,p.cpf,NULL,''S'',p.email,''ELEITOR'',:id_eleitor_int '+
      'FROM pessoa p '+
      'WHERE p.id_socio=:id_socio '+
      'AND NOT EXISTS ('+
      '  SELECT 1 FROM usuario u '+
      '  WHERE u.empresa_id=p.empresa_id AND u.pessoa_id=p.id'+
      ')';

    Qry.ParamByName('id_socio').AsInteger := AIdSocio;
    Qry.ParamByName('id_eleitor_int').AsInteger := AIdEleitorInt;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

procedure GarantirUsuarioAdmin(const AConn: TUniConnection);
var
  Qry: TUniQuery;
  Hash: string;
begin
  Hash := HashSenha('123456');

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO usuario '+
      '(empresa_id,pessoa_id,nome,login,senha_hash,ativo,email,perfil,id_usuario_int) '+
      'SELECT e.id,NULL,''Administrador Demo'',''admin.demo'',:senha,''S'','+
      '''admin.demo@movisystem.local'',''ADMIN'',990001 '+
      'FROM empresa e '+
      'WHERE e.id_empresa=990001 '+
      'AND NOT EXISTS ('+
      '  SELECT 1 FROM usuario u '+
      '  WHERE u.empresa_id=e.id AND u.login=''admin.demo'''+
      ')';

    Qry.ParamByName('senha').AsString := Hash;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

procedure GarantirEleicao(const AConn: TUniConnection);
begin
  ExecSQL(AConn,
    'INSERT INTO eleicao '+
    '(empresa_id,id_eleicao_int,codigo,nome,descricao,ano,ativo,ano_fim,tipo,situacao,operacao) '+
    'SELECT e.id,990001,1,''Eleicao Demo 2026'','+
    '''Eleicao criada pelo seed de homologacao'',2026,''S'',2026,''E'',''ABERTA'',''ELEICAO'' '+
    'FROM empresa e '+
    'WHERE e.id_empresa=990001 '+
    'AND NOT EXISTS ('+
    ' SELECT 1 FROM eleicao x '+
    ' WHERE x.empresa_id=e.id AND x.id_eleicao_int=990001'+
    ')'
  );
end;

procedure GarantirConfiguracao(const AConn: TUniConnection);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO eleicao_configuracao '+
      '(empresa_id,eleicao_id,id_config,slug,nome_exibicao,mensagem_boas_vindas,'+
      'url_publica,email,telefone,cor_primaria,cor_secundaria,pagina_publicar,'+
      'data_hora_inicio,data_hora_fim,abertura_automatica,encerramento_automatico,'+
      'votacao_secreta,exibir_resultado_parcial,publicacao_resultado,controlar_quorum,'+
      'tipo_quorum,quorum_minimo,quorum_percentual,quorum_base,controlar_presenca,'+
      'exigir_presenca_votacao) '+
      'SELECT e.empresa_id,e.id,990001,''eleicao-demo-2026'',''Eleicao Demo 2026'','+
      '''Bem-vindo a eleicao de demonstracao.'',''http://localhost:3000/eleicao-demo-2026'','+
      '''contato.demo@movisystem.local'',''11999990000'',''#2563EB'',''#0F172A'',''S'','+
      ':inicio,:fim,''N'',''N'',''S'',''N'',''N'',''N'',''PERCENTUAL'',0,0.00,''APTOS'',''N'',''N'' '+
      'FROM eleicao e '+
      'WHERE e.id_eleicao_int=990001 '+
      'AND NOT EXISTS ('+
      ' SELECT 1 FROM eleicao_configuracao c '+
      ' WHERE c.empresa_id=e.empresa_id AND c.id_config=990001'+
      ')';

    Qry.ParamByName('inicio').AsDateTime := IncDay(Now,-1);
    Qry.ParamByName('fim').AsDateTime := IncDay(Now,7);
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

procedure GarantirChapa(const AConn: TUniConnection;
  const AIdChapaInt, ANumero: Integer;
  const ANome, ASlogan: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO eleicao_chapa '+
      '(empresa_id,eleicao_id,id_chapa_int,codigo,situacao,num_chapa,nome_chapa,slogan,ativo) '+
      'SELECT e.empresa_id,e.id,:id_chapa_int,:codigo,''HOMOLOGADA'',:numero,:nome,:slogan,''S'' '+
      'FROM eleicao e '+
      'WHERE e.id_eleicao_int=990001 '+
      'AND NOT EXISTS ('+
      ' SELECT 1 FROM eleicao_chapa c '+
      ' WHERE c.empresa_id=e.empresa_id AND c.id_chapa_int=:id_chapa_check'+
      ')';

    Qry.ParamByName('id_chapa_int').AsInteger := AIdChapaInt;
    Qry.ParamByName('codigo').AsInteger := ANumero;
    Qry.ParamByName('numero').AsInteger := ANumero;
    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('slogan').AsString := ASlogan;
    Qry.ParamByName('id_chapa_check').AsInteger := AIdChapaInt;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

procedure GarantirMembro(const AConn: TUniConnection;
  const AIdChapaInt, AIdMembroInt, ACodigo: Integer;
  const ANome, ACPF, ACargo, ATipo: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO eleicao_chapa_membros '+
      '(empresa_id,eleicao_id,eleicao_chapa_id,id_membro_int,codigo,nome,cpf,ativo,cargo,tipo) '+
      'SELECT e.empresa_id,e.id,c.id,:id_membro,:codigo,:nome,:cpf,''S'',:cargo,:tipo '+
      'FROM eleicao e '+
      'INNER JOIN eleicao_chapa c ON c.eleicao_id=e.id AND c.id_chapa_int=:id_chapa '+
      'WHERE e.id_eleicao_int=990001 '+
      'AND NOT EXISTS ('+
      ' SELECT 1 FROM eleicao_chapa_membros m '+
      ' WHERE m.empresa_id=e.empresa_id AND m.id_membro_int=:id_membro_check'+
      ')';

    Qry.ParamByName('id_membro').AsInteger := AIdMembroInt;
    Qry.ParamByName('codigo').AsInteger := ACodigo;
    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('cpf').AsString := ACPF;
    Qry.ParamByName('cargo').AsString := ACargo;
    Qry.ParamByName('tipo').AsString := ATipo;
    Qry.ParamByName('id_chapa').AsInteger := AIdChapaInt;
    Qry.ParamByName('id_membro_check').AsInteger := AIdMembroInt;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

procedure GarantirEleitores(const AConn: TUniConnection);
begin
  ExecSQL(AConn,
    'INSERT INTO eleicao_votante (empresa_id,eleicao_id,usuario_id,votou) '+
    'SELECT e.empresa_id,e.id,u.id,''N'' '+
    'FROM eleicao e '+
    'INNER JOIN usuario u ON u.empresa_id=e.empresa_id AND u.perfil=''ELEITOR'' '+
    'WHERE e.id_eleicao_int=990001 '+
    'AND NOT EXISTS ('+
    ' SELECT 1 FROM eleicao_votante v '+
    ' WHERE v.eleicao_id=e.id AND v.usuario_id=u.id'+
    ')'
  );
end;

procedure GarantirComissao(const AConn: TUniConnection);
var
  Qry: TUniQuery;
  Hash: string;
begin
  Hash := HashSenha('123456');

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO usuario '+
      '(empresa_id,pessoa_id,nome,login,senha_hash,ativo,email,perfil) '+
      'SELECT e.id,NULL,''Comissao Demo'',''99999999999'',:senha,''S'','+
      '''comissao.demo@movisystem.local'',''COMISSAO'' '+
      'FROM empresa e '+
      'WHERE e.id_empresa=990001 '+
      'AND NOT EXISTS ('+
      ' SELECT 1 FROM usuario u '+
      ' WHERE u.empresa_id=e.id AND u.login=''99999999999'''+
      ')';

    Qry.ParamByName('senha').AsString := Hash;
    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text :=
      'INSERT INTO eleicao_comissao '+
      '(empresa_id,eleicao_id,id_eleicao_int,id_comissao_int,usuario_id,nome,cpf,telefone,email,cargo,ativo) '+
      'SELECT e.empresa_id,e.id,990001,990001,u.id,''Comissao Demo'',''99999999999'','+
      '''11999990001'',''comissao.demo@movisystem.local'',''Presidente'',''S'' '+
      'FROM eleicao e '+
      'INNER JOIN usuario u ON u.empresa_id=e.empresa_id AND u.login=''99999999999'' '+
      'WHERE e.id_eleicao_int=990001 '+
      'AND NOT EXISTS ('+
      ' SELECT 1 FROM eleicao_comissao c '+
      ' WHERE c.empresa_id=e.empresa_id AND c.id_eleicao_int=990001 AND c.id_comissao_int=990001'+
      ')';

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

procedure GarantirQuestao(const AConn: TUniConnection);
begin
  ExecSQL(AConn,
    'INSERT INTO eleicao_questao '+
    '(id_questao_int,eleicao_id,id_eleicao_int,empresa_id,titulo,descricao,ordem,tipo_resposta,obrigatoria,ativo) '+
    'SELECT 990001,e.id,990001,e.empresa_id,''Aprova a proposta apresentada?'','+
    '''Questao fake para homologacao'',1,''UNICA'',''S'',''S'' '+
    'FROM eleicao e '+
    'WHERE e.id_eleicao_int=990001 '+
    'AND NOT EXISTS ('+
    ' SELECT 1 FROM eleicao_questao q '+
    ' WHERE q.empresa_id=e.empresa_id AND q.id_eleicao_int=990001 AND q.id_questao_int=990001'+
    ')'
  );

  ExecSQL(AConn,
    'INSERT INTO eleicao_questao_opcao '+
    '(id_opcao_int,questao_id,id_questao_int,eleicao_id,id_eleicao_int,empresa_id,ordem,descricao,ativo) '+
    'SELECT 990001,q.id,990001,q.eleicao_id,990001,q.empresa_id,1,''Sim'',''S'' '+
    'FROM eleicao_questao q '+
    'WHERE q.id_questao_int=990001 '+
    'AND NOT EXISTS ('+
    ' SELECT 1 FROM eleicao_questao_opcao o '+
    ' WHERE o.empresa_id=q.empresa_id AND o.id_opcao_int=990001'+
    ')'
  );

  ExecSQL(AConn,
    'INSERT INTO eleicao_questao_opcao '+
    '(id_opcao_int,questao_id,id_questao_int,eleicao_id,id_eleicao_int,empresa_id,ordem,descricao,ativo) '+
    'SELECT 990002,q.id,990001,q.eleicao_id,990001,q.empresa_id,2,''Nao'',''S'' '+
    'FROM eleicao_questao q '+
    'WHERE q.id_questao_int=990001 '+
    'AND NOT EXISTS ('+
    ' SELECT 1 FROM eleicao_questao_opcao o '+
    ' WHERE o.empresa_id=q.empresa_id AND o.id_opcao_int=990002'+
    ')'
  );

  ExecSQL(AConn,
    'INSERT INTO eleicao_questao_opcao '+
    '(id_opcao_int,questao_id,id_questao_int,eleicao_id,id_eleicao_int,empresa_id,ordem,descricao,ativo) '+
    'SELECT 990003,q.id,990001,q.eleicao_id,990001,q.empresa_id,3,''Abstencao'',''S'' '+
    'FROM eleicao_questao q '+
    'WHERE q.id_questao_int=990001 '+
    'AND NOT EXISTS ('+
    ' SELECT 1 FROM eleicao_questao_opcao o '+
    ' WHERE o.empresa_id=q.empresa_id AND o.id_opcao_int=990003'+
    ')'
  );
end;

class procedure TEleicaoSeeds.Run;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  if not Config.RunDemoSeeds then
    Exit;

  if SameText(Config.Ambiente,'PRODUCAO') then
    raise Exception.Create('Seed demo da eleicao nao pode ser executado em PRODUCAO.');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      GarantirEmpresa(Conn);

      GarantirPessoa(Conn,990001,990001,1001,'Ana Demo','11111111111','ana.demo@movisystem.local');
      GarantirPessoa(Conn,990002,990002,1002,'Bruno Demo','22222222222','bruno.demo@movisystem.local');
      GarantirPessoa(Conn,990003,990003,1003,'Carla Demo','33333333333','carla.demo@movisystem.local');

      GarantirUsuarioPessoa(Conn,990001,990001);
      GarantirUsuarioPessoa(Conn,990002,990002);
      GarantirUsuarioPessoa(Conn,990003,990003);
      GarantirUsuarioAdmin(Conn);

      GarantirEleicao(Conn);
      GarantirConfiguracao(Conn);

      GarantirChapa(Conn,990001,10,'Chapa Renovar','Participacao e transparencia');
      GarantirChapa(Conn,990002,20,'Chapa Uniao','Juntos por novas conquistas');

      GarantirMembro(Conn,990001,990001,1,'Marcos Demo','44444444444','Presidente','TITULAR');
      GarantirMembro(Conn,990001,990002,2,'Luciana Demo','55555555555','Vice-presidente','TITULAR');
      GarantirMembro(Conn,990002,990003,1,'Roberto Demo','66666666666','Presidente','TITULAR');
      GarantirMembro(Conn,990002,990004,2,'Patricia Demo','77777777777','Vice-presidente','TITULAR');

      GarantirEleitores(Conn);
      GarantirComissao(Conn);
      GarantirQuestao(Conn);

      Conn.Commit;

      Writeln('Seed demo da eleicao executado com sucesso.');
      Writeln('Slug: eleicao-demo-2026');
      Writeln('Admin: admin.demo@movisystem.local / senha 123456');
      Writeln('Comissao: comissao.demo@movisystem.local / senha 123456');
      Writeln('Eleitores: CPF 11111111111, 22222222222 ou 33333333333');
      Writeln('Matriculas: 1001, 1002 ou 1003');
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

end.
