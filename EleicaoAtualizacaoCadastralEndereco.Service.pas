unit EleicaoAtualizacaoCadastralEndereco.Service;

interface

uses
  EleicaoMelhoriasAPI.Service;

type
  TEleicaoAtualizacaoCadastralEnderecoService = class
  private
    class function SomenteNumeros(const AValor: string): string; static;
    class procedure GarantirCamposEndereco; static;
  public
    class function SolicitarAtualizacao(const AIdEmpresa, AIdUsuario: Int64;
      const AEmail, ATelefone, AWhatsapp, ACEP, AEndereco, ANumero, ABairro,
      AComplemento, ACidade, AIP, AUserAgent: string): TAtualizacaoCadastralSolicitacaoResult; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  App.Errors,
  Database.Connection;

class function TEleicaoAtualizacaoCadastralEnderecoService.SomenteNumeros(
  const AValor: string): string;
var
  C: Char;
begin
  Result := '';
  for C in AValor do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

class procedure TEleicaoAtualizacaoCadastralEnderecoService.GarantirCamposEndereco;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;

  procedure AdicionarCampoSeNaoExistir(const ACampo, ADefinicao: string);
  begin
    Qry.Close;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS qtd FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ''eleicao_atualizacao_cadastral'' ' +
      'AND COLUMN_NAME = :campo';
    Qry.ParamByName('campo').AsString := ACampo;
    Qry.Open;
    if Qry.FieldByName('qtd').AsInteger = 0 then
    begin
      Qry.Close;
      Qry.SQL.Text := 'ALTER TABLE eleicao_atualizacao_cadastral ADD COLUMN ' + ACampo + ' ' + ADefinicao;
      Qry.Execute;
    end;
  end;

begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      AdicionarCampoSeNaoExistir('cep_novo', 'VARCHAR(10) NULL');
      AdicionarCampoSeNaoExistir('endereco_novo', 'VARCHAR(180) NULL');
      AdicionarCampoSeNaoExistir('numero_novo', 'VARCHAR(20) NULL');
      AdicionarCampoSeNaoExistir('bairro_novo', 'VARCHAR(100) NULL');
      AdicionarCampoSeNaoExistir('complemento_novo', 'VARCHAR(120) NULL');
      AdicionarCampoSeNaoExistir('cidade_nova', 'VARCHAR(100) NULL');
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TEleicaoAtualizacaoCadastralEnderecoService.SolicitarAtualizacao(
  const AIdEmpresa, AIdUsuario: Int64;
  const AEmail, ATelefone, AWhatsapp, ACEP, AEndereco, ANumero, ABairro,
  AComplemento, ACidade, AIP, AUserAgent: string): TAtualizacaoCadastralSolicitacaoResult;
var
  Email, Telefone, Whatsapp, CEP, Endereco, Numero, Bairro, Complemento, Cidade: string;
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
  IdPessoa: Int64;
  NovaSolicitacao: Boolean;
begin
  Result.IdSolicitacao := 0;
  Result.Situacao := '';

  Email := Trim(AEmail);
  Telefone := SomenteNumeros(ATelefone);
  Whatsapp := SomenteNumeros(AWhatsapp);
  CEP := SomenteNumeros(ACEP);
  Endereco := Trim(AEndereco);
  Numero := Trim(ANumero);
  Bairro := Trim(ABairro);
  Complemento := Trim(AComplemento);
  Cidade := Trim(ACidade);

  if Email.IsEmpty and Telefone.IsEmpty and Whatsapp.IsEmpty and CEP.IsEmpty and
     Endereco.IsEmpty and Numero.IsEmpty and Bairro.IsEmpty and Complemento.IsEmpty and Cidade.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe ao menos um dado para atualização.');

  if (not Email.IsEmpty) and (Pos('@', Email) <= 1) then
    TAppErrors.RaiseBadRequest('Informe um e-mail válido.');
  if (not Telefone.IsEmpty) and ((Length(Telefone) < 10) or (Length(Telefone) > 13)) then
    TAppErrors.RaiseBadRequest('Informe um telefone válido.');
  if (not Whatsapp.IsEmpty) and ((Length(Whatsapp) < 10) or (Length(Whatsapp) > 13)) then
    TAppErrors.RaiseBadRequest('Informe um WhatsApp válido.');
  if (not CEP.IsEmpty) and (Length(CEP) <> 8) then
    TAppErrors.RaiseBadRequest('Informe um CEP válido.');

  GarantirCamposEndereco;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'SELECT p.id AS pessoa_id FROM usuario u ' +
        'INNER JOIN pessoa p ON p.id = u.pessoa_id AND p.empresa_id = u.empresa_id ' +
        'WHERE u.id = :usuario AND u.empresa_id = :empresa AND u.ativo = ''S'' ' +
        'AND p.ativo = ''S'' AND p.excluido = 0 LIMIT 1';
      Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
      Qry.ParamByName('empresa').AsLargeInt := AIdEmpresa;
      Qry.Open;
      if Qry.IsEmpty then
        TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');
      IdPessoa := Qry.FieldByName('pessoa_id').AsLargeInt;

      Qry.Close;
      Qry.SQL.Text :=
        'SELECT id FROM eleicao_atualizacao_cadastral ' +
        'WHERE empresa_id = :empresa AND usuario_id = :usuario AND pessoa_id = :pessoa ' +
        'AND situacao = ''PENDENTE'' ORDER BY id DESC LIMIT 1';
      Qry.ParamByName('empresa').AsLargeInt := AIdEmpresa;
      Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
      Qry.ParamByName('pessoa').AsLargeInt := IdPessoa;
      Qry.Open;

      NovaSolicitacao := Qry.IsEmpty;

      if NovaSolicitacao then
      begin
        Qry.Close;
        Qry.SQL.Text :=
          'INSERT INTO eleicao_atualizacao_cadastral ' +
          '(empresa_id, usuario_id, pessoa_id, email_novo, telefone_novo, whatsapp_novo, ' +
          ' cep_novo, endereco_novo, numero_novo, bairro_novo, complemento_novo, cidade_nova, ' +
          ' situacao, ip_origem, user_agent) ' +
          'VALUES (:empresa, :usuario, :pessoa, :email, :telefone, :whatsapp, :cep, :endereco, ' +
          ' :numero, :bairro, :complemento, :cidade, ''PENDENTE'', :ip, :agent)';
        Qry.ParamByName('empresa').AsLargeInt := AIdEmpresa;
        Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
        Qry.ParamByName('pessoa').AsLargeInt := IdPessoa;
      end
      else
      begin
        Result.IdSolicitacao := Qry.FieldByName('id').AsLargeInt;
        Qry.Close;
        Qry.SQL.Text :=
          'UPDATE eleicao_atualizacao_cadastral SET ' +
          'email_novo=:email, telefone_novo=:telefone, whatsapp_novo=:whatsapp, ' +
          'cep_novo=:cep, endereco_novo=:endereco, numero_novo=:numero, bairro_novo=:bairro, ' +
          'complemento_novo=:complemento, cidade_nova=:cidade, ip_origem=:ip, user_agent=:agent, ' +
          'atualizado_em=NOW() WHERE id=:id AND situacao=''PENDENTE''';
        Qry.ParamByName('id').AsLargeInt := Result.IdSolicitacao;
      end;

      Qry.ParamByName('email').AsString := Email;
      Qry.ParamByName('telefone').AsString := Telefone;
      Qry.ParamByName('whatsapp').AsString := Whatsapp;
      Qry.ParamByName('cep').AsString := CEP;
      Qry.ParamByName('endereco').AsString := Copy(Endereco, 1, 180);
      Qry.ParamByName('numero').AsString := Copy(Numero, 1, 20);
      Qry.ParamByName('bairro').AsString := Copy(Bairro, 1, 100);
      Qry.ParamByName('complemento').AsString := Copy(Complemento, 1, 120);
      Qry.ParamByName('cidade').AsString := Copy(Cidade, 1, 100);
      Qry.ParamByName('ip').AsString := Copy(Trim(AIP), 1, 64);
      Qry.ParamByName('agent').AsString := Copy(Trim(AUserAgent), 1, 500);
      Qry.Execute;

      if NovaSolicitacao then
      begin
        Qry.Close;
        Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
        Qry.Open;
        Result.IdSolicitacao := Qry.FieldByName('id').AsLargeInt;
      end;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;

  Result.Situacao := 'PENDENTE';
end;

end.
