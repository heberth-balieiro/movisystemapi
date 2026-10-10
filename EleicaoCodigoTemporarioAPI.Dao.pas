unit EleicaoCodigoTemporarioAPI.Dao;

interface

uses
  Uni,
  System.Generics.Collections;

type
  TEleicaoCodigoTemporarioEleitor = record
    IdUsuario: Integer;
    Nome: string;
    CPF: string;
    Matricula: string;
    Email: string;
    Whatsapp: string;
    JaVotou: Boolean;
  end;

  TEleicaoCodigoTemporarioEleitores = TList<TEleicaoCodigoTemporarioEleitor>;

  TEleicaoCodigoTemporarioDados = record
    Id: Int64;
    OperadorUsuarioId: Integer;
    CodigoHash: string;
    ExpiraEm: TDateTime;
    Status: string;
  end;

  TEleicaoCodigoTemporarioAPIDao = class
  public
    class procedure GarantirEstrutura(const AConn: TUniConnection); static;
    class procedure BuscarEleitores(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao: Integer; const ATermo: string; const ALista: TEleicaoCodigoTemporarioEleitores); static;
    class function EleitorValido(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; out ANome: string; out AJaVotou: Boolean): Boolean; static;
    class function QuantidadeGeracoesEleitor(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario, AMinutos: Integer): Integer; static;
    class function QuantidadeGeracoesOperador(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdOperador, AMinutos: Integer): Integer; static;
    class function InvalidarAtivos(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario: Integer): Integer; static;
    class procedure InvalidarConfirmacaoNormal(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario: Integer); static;
    class procedure Inserir(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario, AIdOperador: Integer; const ACodigoHash: string; const AValidadeMinutos: Integer; const AIP, AUserAgent: string); static;
    class function BuscarAtivo(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; out ADados: TEleicaoCodigoTemporarioDados): Boolean; static;
    class procedure MarcarUtilizado(const AConn: TUniConnection; const AId: Int64); static;
    class procedure MarcarExpirado(const AConn: TUniConnection; const AId: Int64); static;
  end;

implementation

uses
  System.SysUtils;

class procedure TEleicaoCodigoTemporarioAPIDao.GarantirEstrutura(const AConn: TUniConnection);
var Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS eleicao_codigo_temporario (' +
      ' id BIGINT NOT NULL AUTO_INCREMENT,' +
      ' empresa_id INT NOT NULL,' +
      ' eleicao_id INT NOT NULL,' +
      ' usuario_id INT NOT NULL,' +
      ' operador_usuario_id INT NOT NULL,' +
      ' codigo_hash VARCHAR(128) NOT NULL,' +
      ' status VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',' +
      ' criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
      ' expira_em DATETIME NOT NULL,' +
      ' utilizado_em DATETIME NULL,' +
      ' invalidado_em DATETIME NULL,' +
      ' ip VARCHAR(64) NULL,' +
      ' user_agent VARCHAR(500) NULL,' +
      ' PRIMARY KEY (id),' +
      ' KEY idx_ect_eleitor (empresa_id,eleicao_id,usuario_id,status),' +
      ' KEY idx_ect_operador (empresa_id,eleicao_id,operador_usuario_id,criado_em),' +
      ' CONSTRAINT fk_ect_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id),' +
      ' CONSTRAINT fk_ect_eleicao FOREIGN KEY (eleicao_id) REFERENCES eleicao(id),' +
      ' CONSTRAINT fk_ect_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id),' +
      ' CONSTRAINT fk_ect_operador FOREIGN KEY (operador_usuario_id) REFERENCES usuario(id)' +
      ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci';
    Qry.ExecSQL;
  finally Qry.Free; end;
end;

class procedure TEleicaoCodigoTemporarioAPIDao.BuscarEleitores(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao: Integer; const ATermo: string; const ALista: TEleicaoCodigoTemporarioEleitores);
var Qry: TUniQuery; Item: TEleicaoCodigoTemporarioEleitor; Termo: string;
begin
  ALista.Clear; Termo := Trim(ATermo); Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT u.id AS id_usuario,p.nome,COALESCE(p.cpf,'''') AS cpf,' +
      ' COALESCE(p.matricula,'''') AS matricula,COALESCE(p.email,'''') AS email,' +
      ' COALESCE(p.whatsapp,'''') AS whatsapp,' +
      ' CASE WHEN EXISTS (SELECT 1 FROM eleicao_votante ev WHERE ev.empresa_id=u.empresa_id' +
      ' AND ev.eleicao_id=:ideleicao AND ev.usuario_id=u.id AND ev.votou=''S'') THEN 1 ELSE 0 END AS ja_votou ' +
      'FROM usuario u INNER JOIN pessoa p ON p.id=u.pessoa_id AND p.empresa_id=u.empresa_id ' +
      'WHERE u.empresa_id=:idempresa AND u.ativo=''S'' AND p.ativo=''S'' ' +
      ' AND COALESCE(p.bloqueado,''N'')=''N'' AND COALESCE(p.excluido,0)=0 ' +
      ' AND u.perfil=''ELEITOR_IDENTIFICADO'' AND COALESCE(u.id_eleitor_int,0)>0 ' +
      ' AND (:termo='''' OR p.nome LIKE :busca OR p.cpf LIKE :busca OR CAST(p.matricula AS CHAR) LIKE :busca) ORDER BY p.nome LIMIT 50';
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao; Qry.ParamByName('idempresa').AsInteger := AIdEmpresa; Qry.ParamByName('termo').AsString := Termo; Qry.ParamByName('busca').AsString := '%' + Termo + '%'; Qry.Open;
    while not Qry.Eof do begin
      Item := Default(TEleicaoCodigoTemporarioEleitor); Item.IdUsuario := Qry.FieldByName('id_usuario').AsInteger; Item.Nome := Qry.FieldByName('nome').AsString; Item.CPF := Qry.FieldByName('cpf').AsString; Item.Matricula := Qry.FieldByName('matricula').AsString; Item.Email := Qry.FieldByName('email').AsString; Item.Whatsapp := Qry.FieldByName('whatsapp').AsString; Item.JaVotou := Qry.FieldByName('ja_votou').AsInteger = 1; ALista.Add(Item); Qry.Next;
    end;
  finally Qry.Free; end;
end;

class function TEleicaoCodigoTemporarioAPIDao.EleitorValido(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; out ANome: string; out AJaVotou: Boolean): Boolean;
var Qry: TUniQuery;
begin
  Result := False; ANome := ''; AJaVotou := False; Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'SELECT p.nome,CASE WHEN EXISTS (SELECT 1 FROM eleicao_votante ev WHERE ev.empresa_id=u.empresa_id AND ev.eleicao_id=:ideleicao AND ev.usuario_id=u.id AND ev.votou=''S'') THEN 1 ELSE 0 END AS ja_votou FROM usuario u INNER JOIN pessoa p ON p.id=u.pessoa_id AND p.empresa_id=u.empresa_id WHERE u.id=:idusuario AND u.empresa_id=:idempresa AND u.ativo=''S'' AND u.perfil=''ELEITOR_IDENTIFICADO'' AND COALESCE(u.id_eleitor_int,0)>0 AND p.ativo=''S'' AND COALESCE(p.bloqueado,''N'')=''N'' AND COALESCE(p.excluido,0)=0 LIMIT 1';
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao; Qry.ParamByName('idusuario').AsInteger := AIdUsuario; Qry.ParamByName('idempresa').AsInteger := AIdEmpresa; Qry.Open; if Qry.IsEmpty then Exit; ANome := Qry.FieldByName('nome').AsString; AJaVotou := Qry.FieldByName('ja_votou').AsInteger = 1; Result := True;
  finally Qry.Free; end;
end;

class function TEleicaoCodigoTemporarioAPIDao.QuantidadeGeracoesEleitor(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario, AMinutos: Integer): Integer;
var Qry: TUniQuery;
begin Qry := TUniQuery.Create(nil); try Qry.Connection := AConn; Qry.SQL.Text := 'SELECT COUNT(*) total FROM eleicao_codigo_temporario WHERE empresa_id=:e AND eleicao_id=:el AND usuario_id=:u AND criado_em>=DATE_SUB(NOW(),INTERVAL :m MINUTE)'; Qry.ParamByName('e').AsInteger := AIdEmpresa; Qry.ParamByName('el').AsInteger := AIdEleicao; Qry.ParamByName('u').AsInteger := AIdUsuario; Qry.ParamByName('m').AsInteger := AMinutos; Qry.Open; Result := Qry.FieldByName('total').AsInteger; finally Qry.Free; end; end;

class function TEleicaoCodigoTemporarioAPIDao.QuantidadeGeracoesOperador(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdOperador, AMinutos: Integer): Integer;
var Qry: TUniQuery;
begin Qry := TUniQuery.Create(nil); try Qry.Connection := AConn; Qry.SQL.Text := 'SELECT COUNT(*) total FROM eleicao_codigo_temporario WHERE empresa_id=:e AND eleicao_id=:el AND operador_usuario_id=:o AND criado_em>=DATE_SUB(NOW(),INTERVAL :m MINUTE)'; Qry.ParamByName('e').AsInteger := AIdEmpresa; Qry.ParamByName('el').AsInteger := AIdEleicao; Qry.ParamByName('o').AsInteger := AIdOperador; Qry.ParamByName('m').AsInteger := AMinutos; Qry.Open; Result := Qry.FieldByName('total').AsInteger; finally Qry.Free; end; end;

class function TEleicaoCodigoTemporarioAPIDao.InvalidarAtivos(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario: Integer): Integer;
var Qry: TUniQuery;
begin Result := 0; Qry := TUniQuery.Create(nil); try Qry.Connection := AConn; Qry.SQL.Text := 'UPDATE eleicao_codigo_temporario SET status=''INVALIDADO'',invalidado_em=NOW() WHERE empresa_id=:e AND eleicao_id=:el AND usuario_id=:u AND status=''ATIVO'''; Qry.ParamByName('e').AsInteger := AIdEmpresa; Qry.ParamByName('el').AsInteger := AIdEleicao; Qry.ParamByName('u').AsInteger := AIdUsuario; Qry.ExecSQL; Result := Qry.RowsAffected; finally Qry.Free; end; end;

class procedure TEleicaoCodigoTemporarioAPIDao.InvalidarConfirmacaoNormal(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario: Integer);
var Qry: TUniQuery;
begin Qry := TUniQuery.Create(nil); try Qry.Connection := AConn; Qry.SQL.Text := 'UPDATE eleicao_confirmacao SET expira_em=NOW() WHERE empresa_id=:e AND eleicao_id=:el AND usuario_id=:u AND confirmado=''N'''; Qry.ParamByName('e').AsInteger := AIdEmpresa; Qry.ParamByName('el').AsInteger := AIdEleicao; Qry.ParamByName('u').AsInteger := AIdUsuario; Qry.ExecSQL; finally Qry.Free; end; end;

class procedure TEleicaoCodigoTemporarioAPIDao.Inserir(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario, AIdOperador: Integer; const ACodigoHash: string; const AValidadeMinutos: Integer; const AIP, AUserAgent: string);
var Qry: TUniQuery;
begin Qry := TUniQuery.Create(nil); try Qry.Connection := AConn; Qry.SQL.Text := 'INSERT INTO eleicao_codigo_temporario (empresa_id,eleicao_id,usuario_id,operador_usuario_id,codigo_hash,status,criado_em,expira_em,ip,user_agent) VALUES (:e,:el,:u,:o,:h,''ATIVO'',NOW(),DATE_ADD(NOW(),INTERVAL :m MINUTE),:ip,:ua)'; Qry.ParamByName('e').AsInteger := AIdEmpresa; Qry.ParamByName('el').AsInteger := AIdEleicao; Qry.ParamByName('u').AsInteger := AIdUsuario; Qry.ParamByName('o').AsInteger := AIdOperador; Qry.ParamByName('h').AsString := ACodigoHash; Qry.ParamByName('m').AsInteger := AValidadeMinutos; Qry.ParamByName('ip').AsString := Copy(AIP,1,64); Qry.ParamByName('ua').AsString := Copy(AUserAgent,1,500); Qry.ExecSQL; finally Qry.Free; end; end;

class function TEleicaoCodigoTemporarioAPIDao.BuscarAtivo(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; out ADados: TEleicaoCodigoTemporarioDados): Boolean;
var Qry: TUniQuery;
begin Result := False; ADados := Default(TEleicaoCodigoTemporarioDados); Qry := TUniQuery.Create(nil); try Qry.Connection := AConn; Qry.SQL.Text := 'SELECT id,operador_usuario_id,codigo_hash,expira_em,status FROM eleicao_codigo_temporario WHERE empresa_id=:e AND eleicao_id=:el AND usuario_id=:u AND status=''ATIVO'' ORDER BY id DESC LIMIT 1'; Qry.ParamByName('e').AsInteger := AIdEmpresa; Qry.ParamByName('el').AsInteger := AIdEleicao; Qry.ParamByName('u').AsInteger := AIdUsuario; Qry.Open; if Qry.IsEmpty then Exit; ADados.Id := Qry.FieldByName('id').AsLargeInt; ADados.OperadorUsuarioId := Qry.FieldByName('operador_usuario_id').AsInteger; ADados.CodigoHash := Qry.FieldByName('codigo_hash').AsString; ADados.ExpiraEm := Qry.FieldByName('expira_em').AsDateTime; ADados.Status := Qry.FieldByName('status').AsString; Result := True; finally Qry.Free; end; end;

class procedure TEleicaoCodigoTemporarioAPIDao.MarcarUtilizado(const AConn: TUniConnection; const AId: Int64);
var Qry: TUniQuery;
begin Qry := TUniQuery.Create(nil); try Qry.Connection := AConn; Qry.SQL.Text := 'UPDATE eleicao_codigo_temporario SET status=''UTILIZADO'',utilizado_em=NOW() WHERE id=:id AND status=''ATIVO'''; Qry.ParamByName('id').AsLargeInt := AId; Qry.ExecSQL; finally Qry.Free; end; end;

class procedure TEleicaoCodigoTemporarioAPIDao.MarcarExpirado(const AConn: TUniConnection; const AId: Int64);
var Qry: TUniQuery;
begin Qry := TUniQuery.Create(nil); try Qry.Connection := AConn; Qry.SQL.Text := 'UPDATE eleicao_codigo_temporario SET status=''EXPIRADO'',invalidado_em=NOW() WHERE id=:id AND status=''ATIVO'''; Qry.ParamByName('id').AsLargeInt := AId; Qry.ExecSQL; finally Qry.Free; end; end;

end.
