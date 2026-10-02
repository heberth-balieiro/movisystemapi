unit InstituicaoTurmaImportacao.Service;

interface

uses
  System.Classes,
  System.JSON;

type
  TInstituicaoTurmaImportacaoService = class
  private
    class function GerarCodigoPublico: string; static;
    class function EmailValido(const AEmail: string): Boolean; static;
    class function ParseCsvLine(
      const ALinha: string;
      const ADelimitador: Char
    ): TArray<string>; static;
    class function Processar(
      const AIdInstituicao,
            AIdTurma,
            AIdUsuarioInstituicao: Int64;
      const ANomeArquivo: string;
      const AStream: TStream;
      const ASimular: Boolean
    ): TJSONObject; static;
  public
    class function Validar(
      const AIdInstituicao,
            AIdTurma,
            AIdUsuarioInstituicao: Int64;
      const ANomeArquivo: string;
      const AStream: TStream
    ): TJSONObject; static;

    class function Importar(
      const AIdInstituicao,
            AIdTurma,
            AIdUsuarioInstituicao: Int64;
      const ANomeArquivo: string;
      const AStream: TStream
    ): TJSONObject; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  Uni,
  App.Config,
  APP.Errors,
  App.ParticipanteSecurity,
  Database.Connection,
  InstituicaoPermissao.Service,
  InstituicaoConfiguracao.Service,
  InstituicaoParticipante.Model,
  InstituicaoParticipante.DAO,
  InstituicaoInscricao.Model,
  InstituicaoInscricao.DAO,
  InstituicaoTurmaImportacao.DAO;

const
  MAX_CSV_SIZE = 5 * 1024 * 1024;
  MAX_CSV_REGISTROS = 5000;

class function TInstituicaoTurmaImportacaoService.GerarCodigoPublico: string;
var
  Guid: TGUID;
  S: string;
begin
  CreateGUID(Guid);
  S := GUIDToString(Guid);
  S := StringReplace(S, '{', '', [rfReplaceAll]);
  S := StringReplace(S, '}', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '', [rfReplaceAll]);
  Result := Copy(UpperCase(S), 1, 26);
end;

class function TInstituicaoTurmaImportacaoService.EmailValido(
  const AEmail: string
): Boolean;
var
  S: string;
begin
  S := Trim(AEmail);
  Result :=
    S.IsEmpty or
    ((Length(S) <= 254) and (Pos('@', S) > 1));
end;

class function TInstituicaoTurmaImportacaoService.ParseCsvLine(
  const ALinha: string;
  const ADelimitador: Char
): TArray<string>;
var
  Campos: TStringList;
begin
  Campos := TStringList.Create;
  try
    Campos.StrictDelimiter := True;
    Campos.Delimiter := ADelimitador;
    Campos.QuoteChar := '"';
    Campos.DelimitedText := ALinha;
    Result := Campos.ToStringArray;
  finally
    Campos.Free;
  end;
end;

class function TInstituicaoTurmaImportacaoService.Processar(
  const AIdInstituicao,
        AIdTurma,
        AIdUsuarioInstituicao: Int64;
  const ANomeArquivo: string;
  const AStream: TStream;
  const ASimular: Boolean
): TJSONObject;
var
  AppConfig: TAppApiConfig;
  Conn: TUniConnection;
  Linhas: TStringList;
  Cabecalho, Campos: TArray<string>;
  Delimitador: Char;
  I, J, LinhaNumero: Integer;
  IdNome, IdCpf, IdEmail, IdTelefone: Integer;
  Nome, Cpf, Email, Telefone, CpfHash, CpfMascarado: string;
  Erro: string;
  Total, Validos, Erros, Importados: Integer;
  ErrosJson, ItensJson: TJSONArray;
  ItemJson, ErroJson: TJSONObject;
  CpfArquivo: TDictionary<string, Boolean>;
  IdImportacao, IdParticipante, IdInscricao: Int64;
  Participante: TInstituicaoParticipanteCadastro;
  Inscricao: TInstituicaoInscricaoCadastro;
  Codigo: string;
  Tentativas: Integer;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'turma.importar_participantes'
  );

  if not TInstituicaoConfiguracaoService.PermiteTurmaSomenteCertificacao(
    AIdInstituicao
  ) then
    TAppErrors.RaiseBadRequest(
      'A importação para certificação não está habilitada nesta instituição.'
    );

  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest('Turma inválida.');

  if AStream = nil then
    TAppErrors.RaiseBadRequest('Arquivo CSV não informado.');

  if (AStream.Size <= 0) or (AStream.Size > MAX_CSV_SIZE) then
    TAppErrors.RaiseBadRequest(
      'O arquivo CSV deve possuir até 5 MB.'
    );

  Linhas := TStringList.Create;
  CpfArquivo := TDictionary<string, Boolean>.Create;
  try
    AStream.Position := 0;
    Linhas.LoadFromStream(AStream, TEncoding.UTF8);

    while (Linhas.Count > 0) and Trim(Linhas[Linhas.Count - 1]).IsEmpty do
      Linhas.Delete(Linhas.Count - 1);

    if Linhas.Count < 2 then
      TAppErrors.RaiseBadRequest(
        'O CSV deve possuir cabeçalho e ao menos um participante.'
      );

    if Linhas.Count - 1 > MAX_CSV_REGISTROS then
      TAppErrors.RaiseBadRequest(
        'O CSV permite no máximo 5000 participantes por importação.'
      );

    if Linhas[0].CountChar(';') >= Linhas[0].CountChar(',') then
      Delimitador := ';'
    else
      Delimitador := ',';

    Cabecalho := ParseCsvLine(Linhas[0], Delimitador);
    IdNome := -1;
    IdCpf := -1;
    IdEmail := -1;
    IdTelefone := -1;

    for I := 0 to High(Cabecalho) do
    begin
      Cabecalho[I] := LowerCase(Trim(Cabecalho[I]));
      if Cabecalho[I] = 'nome' then IdNome := I
      else if Cabecalho[I] = 'cpf' then IdCpf := I
      else if Cabecalho[I] = 'email' then IdEmail := I
      else if Cabecalho[I] = 'telefone' then IdTelefone := I;
    end;

    if (IdNome < 0) or (IdCpf < 0) then
      TAppErrors.RaiseBadRequest(
        'O CSV deve conter as colunas nome e cpf.'
      );

    AppConfig := TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

    Conn := TDatabaseConnection.NewConnection(AppConfig.Database);
    try
      if not TInstituicaoTurmaImportacaoDAO.TurmaEhSomenteCertificacao(
        Conn,
        AIdInstituicao,
        AIdTurma
      ) then
        TAppErrors.RaiseBadRequest(
          'A turma informada não é do tipo somente certificação.'
        );

      Total := Linhas.Count - 1;
      Validos := 0;
      Erros := 0;
      Importados := 0;
      IdImportacao := 0;
      ErrosJson := TJSONArray.Create;
      ItensJson := TJSONArray.Create;

      if not ASimular then
      begin
        Conn.StartTransaction;
        try
          IdImportacao :=
            TInstituicaoTurmaImportacaoDAO.CriarImportacao(
              Conn,
              AIdInstituicao,
              AIdTurma,
              AIdUsuarioInstituicao,
              IfThen(Trim(ANomeArquivo).IsEmpty, 'importacao.csv', ExtractFileName(ANomeArquivo)),
              Total
            );
        except
          if Conn.InTransaction then
            Conn.Rollback;
          raise;
        end;
      end;

      try
        for I := 1 to Linhas.Count - 1 do
        begin
          LinhaNumero := I + 1;
          Erro := '';
          Campos := ParseCsvLine(Linhas[I], Delimitador);

          if (IdNome > High(Campos)) or (IdCpf > High(Campos)) then
            Erro := 'Linha com quantidade de colunas inválida.'
          else
          begin
            Nome := Trim(Campos[IdNome]);
            Cpf := TParticipanteSecurity.NormalizarCpf(Trim(Campos[IdCpf]));

            Email := '';
            if (IdEmail >= 0) and (IdEmail <= High(Campos)) then
              Email := LowerCase(Trim(Campos[IdEmail]));

            Telefone := '';
            if (IdTelefone >= 0) and (IdTelefone <= High(Campos)) then
              Telefone := Trim(Campos[IdTelefone]);

            if Nome.IsEmpty then
              Erro := 'Nome não informado.'
            else if Length(Nome) > 180 then
              Erro := 'Nome excede 180 caracteres.'
            else if not TParticipanteSecurity.CpfValido(Cpf) then
              Erro := 'CPF inválido.'
            else if not EmailValido(Email) then
              Erro := 'E-mail inválido.'
            else if Length(Telefone) > 30 then
              Erro := 'Telefone excede 30 caracteres.'
            else
            begin
              CpfHash := TParticipanteSecurity.GerarCpfHashBusca(Cpf);
              if CpfArquivo.ContainsKey(CpfHash) then
                Erro := 'CPF duplicado no arquivo.'
              else
                CpfArquivo.Add(CpfHash, True);
            end;
          end;

          if not Erro.IsEmpty then
          begin
            Inc(Erros);

            ErroJson := TJSONObject.Create;
            ErroJson.AddPair('linha', TJSONNumber.Create(LinhaNumero));
            ErroJson.AddPair('mensagem', Erro);
            ErrosJson.AddElement(ErroJson);

            if not ASimular then
              TInstituicaoTurmaImportacaoDAO.RegistrarErro(
                Conn,
                AIdInstituicao,
                IdImportacao,
                LinhaNumero,
                Erro
              );
            Continue;
          end;

          Inc(Validos);

          ItemJson := TJSONObject.Create;
          ItemJson.AddPair('linha', TJSONNumber.Create(LinhaNumero));
          ItemJson.AddPair('nome', Nome);
          ItemJson.AddPair('cpf', TParticipanteSecurity.MascararCpf(Cpf));
          ItemJson.AddPair('email', Email);
          ItemJson.AddPair('telefone', Telefone);
          ItensJson.AddElement(ItemJson);

          if ASimular then
            Continue;

          CpfHash := TParticipanteSecurity.GerarCpfHashBusca(Cpf);
          CpfMascarado := TParticipanteSecurity.MascararCpf(Cpf);

          IdParticipante :=
            TInstituicaoTurmaImportacaoDAO.BuscarParticipantePorCpfHash(
              Conn,
              AIdInstituicao,
              CpfHash
            );

          if IdParticipante <= 0 then
          begin
            Participante := Default(TInstituicaoParticipanteCadastro);
            Participante.Nome := Nome;
            Participante.Cpf := Cpf;
            Participante.Email := Email;
            Participante.Telefone := Telefone;

            Codigo := '';
            for J := 1 to 5 do
            begin
              Codigo := GerarCodigoPublico;
              if not TInstituicaoParticipanteDAO.ExisteCodigoPublico(
                Conn,
                Codigo
              ) then
                Break;
              Codigo := '';
            end;

            if Codigo.IsEmpty then
              raise Exception.Create(
                'Não foi possível gerar o código público do participante.'
              );

            IdParticipante :=
              TInstituicaoParticipanteDAO.Inserir(
                Conn,
                AIdInstituicao,
                AIdUsuarioInstituicao,
                Codigo,
                CpfHash,
                CpfMascarado,
                Participante
              );
          end;

          IdInscricao :=
            TInstituicaoTurmaImportacaoDAO.BuscarInscricaoId(
              Conn,
              AIdInstituicao,
              AIdTurma,
              IdParticipante
            );

          if IdInscricao <= 0 then
          begin
            Inscricao := Default(TInstituicaoInscricaoCadastro);
            Inscricao.IdTurma := AIdTurma;
            Inscricao.IdParticipante := IdParticipante;

            Codigo := '';
            Tentativas := 0;
            repeat
              Inc(Tentativas);
              Codigo := GerarCodigoPublico;
              if not TInstituicaoInscricaoDAO.ExisteCodigoPublico(
                Conn,
                Codigo
              ) then
                Break;
              Codigo := '';
            until Tentativas >= 5;

            if Codigo.IsEmpty then
              raise Exception.Create(
                'Não foi possível gerar o código público da inscrição.'
              );

            IdInscricao :=
              TInstituicaoInscricaoDAO.Inserir(
                Conn,
                AIdInstituicao,
                AIdUsuarioInstituicao,
                Codigo,
                'IMPORTACAO',
                Inscricao
              );

            TInstituicaoInscricaoDAO.InserirHistorico(
              Conn,
              AIdInstituicao,
              AIdTurma,
              IdInscricao,
              AIdUsuarioInstituicao,
              '',
              'INSCRITO',
              'Participante incluído por importação CSV para certificação.'
            );
          end;

          TInstituicaoTurmaImportacaoDAO.ConcluirInscricaoCertificacao(
            Conn,
            AIdInstituicao,
            IdInscricao,
            AIdUsuarioInstituicao
          );

          TInstituicaoInscricaoDAO.InserirHistorico(
            Conn,
            AIdInstituicao,
            AIdTurma,
            IdInscricao,
            AIdUsuarioInstituicao,
            'INSCRITO',
            'CONCLUIDO',
            'Conclusão registrada por turma do tipo somente certificação, sem controle de presença.'
          );

          Inc(Importados);
        end;

        if not ASimular then
        begin
          TInstituicaoTurmaImportacaoDAO.AtualizarTotais(
            Conn,
            AIdInstituicao,
            IdImportacao,
            Importados,
            Erros
          );
          Conn.Commit;
        end;

        Result := TJSONObject.Create;
        Result.AddPair('total', TJSONNumber.Create(Total));
        Result.AddPair('validos', TJSONNumber.Create(Validos));
        Result.AddPair('invalidos', TJSONNumber.Create(Erros));
        Result.AddPair('importados', TJSONNumber.Create(Importados));
        Result.AddPair('simulacao', TJSONBool.Create(ASimular));
        if IdImportacao > 0 then
          Result.AddPair('id_importacao', TJSONNumber.Create(IdImportacao))
        else
          Result.AddPair('id_importacao', TJSONNull.Create);
        Result.AddPair('itens', ItensJson);
        Result.AddPair('erros', ErrosJson);
      except
        ErrosJson.Free;
        ItensJson.Free;
        if (not ASimular) and Conn.InTransaction then
          Conn.Rollback;
        raise;
      end;
    finally
      Conn.Free;
    end;
  finally
    CpfArquivo.Free;
    Linhas.Free;
  end;
end;

class function TInstituicaoTurmaImportacaoService.Validar(
  const AIdInstituicao,
        AIdTurma,
        AIdUsuarioInstituicao: Int64;
  const ANomeArquivo: string;
  const AStream: TStream
): TJSONObject;
begin
  Result := Processar(
    AIdInstituicao,
    AIdTurma,
    AIdUsuarioInstituicao,
    ANomeArquivo,
    AStream,
    True
  );
end;

class function TInstituicaoTurmaImportacaoService.Importar(
  const AIdInstituicao,
        AIdTurma,
        AIdUsuarioInstituicao: Int64;
  const ANomeArquivo: string;
  const AStream: TStream
): TJSONObject;
begin
  Result := Processar(
    AIdInstituicao,
    AIdTurma,
    AIdUsuarioInstituicao,
    ANomeArquivo,
    AStream,
    False
  );
end;

end.
