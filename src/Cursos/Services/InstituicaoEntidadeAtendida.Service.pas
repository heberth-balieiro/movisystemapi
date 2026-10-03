unit InstituicaoEntidadeAtendida.Service;

interface

uses
  InstituicaoEntidadeAtendida.Model;

type
  TInstituicaoEntidadeAtendidaService = class
  private
    class procedure Normalizar(
      var ADados: TInstituicaoEntidadeAtendidaCadastro
    ); static;

    class procedure Validar(
      const ADados: TInstituicaoEntidadeAtendidaCadastro
    ); static;

    class function NormalizarDocumento(
      const ADocumento: string
    ): string; static;

    class procedure ExigirConsultaOuUso(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ); static;
  public
    class function Listar(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ABusca,
            ATipo,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoEntidadeAtendidaLista; static;

    class function ListarOpcoes(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TInstituicaoEntidadeAtendidaLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AId: Int64
    ): TInstituicaoEntidadeAtendidaItem; static;

    class function Cadastrar(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoEntidadeAtendidaCadastro
    ): TInstituicaoEntidadeAtendidaItem; static;

    class function Atualizar(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AId: Int64;
      const ADados: TInstituicaoEntidadeAtendidaAlteracao
    ): TInstituicaoEntidadeAtendidaItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AId: Int64;
      const ASituacao: string
    ): TInstituicaoEntidadeAtendidaItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPermissao.Service,
  InstituicaoEntidadeAtendida.DAO;

class function TInstituicaoEntidadeAtendidaService.NormalizarDocumento(
  const ADocumento: string
): string;
var
  C: Char;
begin
  Result := '';
  for C in Trim(ADocumento) do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

class procedure TInstituicaoEntidadeAtendidaService.Normalizar(
  var ADados: TInstituicaoEntidadeAtendidaCadastro
);
begin
  ADados.Nome := Trim(ADados.Nome);
  ADados.NomeFantasia := Trim(ADados.NomeFantasia);
  ADados.Tipo := UpperCase(Trim(ADados.Tipo));
  ADados.Documento := NormalizarDocumento(ADados.Documento);
  ADados.Situacao := UpperCase(Trim(ADados.Situacao));
  ADados.Observacao := Trim(ADados.Observacao);

  if ADados.Tipo.IsEmpty then
    ADados.Tipo := 'EMPRESA';

  if ADados.Situacao.IsEmpty then
    ADados.Situacao := 'ATIVO';
end;

class procedure TInstituicaoEntidadeAtendidaService.Validar(
  const ADados: TInstituicaoEntidadeAtendidaCadastro
);
begin
  if ADados.Nome.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome ou razão social.');

  if Length(ADados.Nome) > 180 then
    TAppErrors.RaiseBadRequest('O nome deve possuir no máximo 180 caracteres.');

  if Length(ADados.NomeFantasia) > 180 then
    TAppErrors.RaiseBadRequest('O nome fantasia deve possuir no máximo 180 caracteres.');

  if not MatchText(
    ADados.Tipo,
    ['EMPRESA','PREFEITURA','SECRETARIA','AUTARQUIA','ASSOCIACAO','OUTRO']
  ) then
    TAppErrors.RaiseBadRequest('Tipo de cliente/entidade inválido.');

  if not ADados.Documento.IsEmpty then
    if (Length(ADados.Documento) <> 11) and
       (Length(ADados.Documento) <> 14) then
      TAppErrors.RaiseBadRequest('CPF/CNPJ deve possuir 11 ou 14 dígitos.');

  if not MatchText(ADados.Situacao, ['ATIVO','INATIVO']) then
    TAppErrors.RaiseBadRequest('Situação inválida.');

  if Length(ADados.Observacao) > 1000 then
    TAppErrors.RaiseBadRequest('A observação deve possuir no máximo 1000 caracteres.');
end;

class procedure TInstituicaoEntidadeAtendidaService.ExigirConsultaOuUso(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
);
begin
  if TInstituicaoPermissaoService.TemPermissao(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'entidade_atendida.visualizar'
  ) then
    Exit;

  if TInstituicaoPermissaoService.TemPermissao(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'curso.cadastrar'
  ) then
    Exit;

  if TInstituicaoPermissaoService.TemPermissao(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'curso.editar'
  ) then
    Exit;

  if TInstituicaoPermissaoService.TemPermissao(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'turma.cadastrar'
  ) then
    Exit;

  if TInstituicaoPermissaoService.TemPermissao(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'turma.editar'
  ) then
    Exit;

  TAppErrors.RaiseForbidden(
    'Usuário sem permissão para consultar clientes/entidades atendidas.'
  );
end;

class function TInstituicaoEntidadeAtendidaService.Listar(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ABusca,
        ATipo,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoEntidadeAtendidaLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoEntidadeAtendidaFiltro;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'entidade_atendida.visualizar'
  );

  Filtro := Default(TInstituicaoEntidadeAtendidaFiltro);
  Filtro.Busca := Trim(ABusca);
  Filtro.Tipo := UpperCase(Trim(ATipo));
  Filtro.Situacao := UpperCase(Trim(ASituacao));
  Filtro.Pagina := APagina;
  Filtro.PorPagina := APorPagina;

  if Filtro.Pagina <= 0 then Filtro.Pagina := 1;
  if Filtro.PorPagina <= 0 then Filtro.PorPagina := 20;
  if Filtro.PorPagina > 100 then Filtro.PorPagina := 100;

  if not Filtro.Tipo.IsEmpty then
    if not MatchText(
      Filtro.Tipo,
      ['EMPRESA','PREFEITURA','SECRETARIA','AUTARQUIA','ASSOCIACAO','OUTRO']
    ) then
      TAppErrors.RaiseBadRequest('Tipo inválido.');

  if not Filtro.Situacao.IsEmpty then
    if not MatchText(Filtro.Situacao, ['ATIVO','INATIVO']) then
      TAppErrors.RaiseBadRequest('Situação inválida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoEntidadeAtendidaDAO.Listar(
      Conn,
      AIdInstituicao,
      Filtro
    );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoEntidadeAtendidaService.ListarOpcoes(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TInstituicaoEntidadeAtendidaLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoEntidadeAtendidaFiltro;
begin
  ExigirConsultaOuUso(AIdInstituicao, AIdUsuarioInstituicao);

  Filtro := Default(TInstituicaoEntidadeAtendidaFiltro);
  Filtro.Situacao := 'ATIVO';
  Filtro.Pagina := 1;
  Filtro.PorPagina := 100;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoEntidadeAtendidaDAO.Listar(
      Conn,
      AIdInstituicao,
      Filtro
    );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoEntidadeAtendidaService.BuscarPorId(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AId: Int64
): TInstituicaoEntidadeAtendidaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'entidade_atendida.visualizar'
  );

  if AId <= 0 then
    TAppErrors.RaiseBadRequest('Cliente/entidade inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoEntidadeAtendidaDAO.BuscarPorId(
      Conn,
      AIdInstituicao,
      AId
    );

    if Result = nil then
      TAppErrors.RaiseBadRequest('Cliente/entidade não encontrado.');
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoEntidadeAtendidaService.Cadastrar(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoEntidadeAtendidaCadastro
): TInstituicaoEntidadeAtendidaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoEntidadeAtendidaCadastro;
  Id: Int64;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'entidade_atendida.criar'
  );

  Dados := ADados;
  Normalizar(Dados);
  Validar(Dados);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TInstituicaoEntidadeAtendidaDAO.ExisteDocumento(
      Conn,
      AIdInstituicao,
      Dados.Documento
    ) then
      TAppErrors.RaiseBadRequest(
        'Já existe um cliente/entidade com este CPF/CNPJ.'
      );

    Conn.StartTransaction;
    try
      Id := TInstituicaoEntidadeAtendidaDAO.Inserir(
        Conn,
        AIdInstituicao,
        Dados
      );

      Result := TInstituicaoEntidadeAtendidaDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        Id
      );

      if Result = nil then
        raise Exception.Create(
          'Cliente/entidade cadastrado, mas não foi possível recuperar os dados.'
        );

      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      Result.Free;
      Result := nil;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoEntidadeAtendidaService.Atualizar(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AId: Int64;
  const ADados: TInstituicaoEntidadeAtendidaAlteracao
): TInstituicaoEntidadeAtendidaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoEntidadeAtendidaCadastro;
  Atual: TInstituicaoEntidadeAtendidaItem;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'entidade_atendida.editar'
  );

  if AId <= 0 then
    TAppErrors.RaiseBadRequest('Cliente/entidade inválido.');

  Dados := ADados;
  Normalizar(Dados);
  Validar(Dados);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TInstituicaoEntidadeAtendidaDAO.BuscarPorId(
      Conn,
      AIdInstituicao,
      AId
    );
    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest('Cliente/entidade não encontrado.');

      if TInstituicaoEntidadeAtendidaDAO.ExisteDocumento(
        Conn,
        AIdInstituicao,
        Dados.Documento,
        AId
      ) then
        TAppErrors.RaiseBadRequest(
          'Já existe outro cliente/entidade com este CPF/CNPJ.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoEntidadeAtendidaDAO.Atualizar(
          Conn,
          AIdInstituicao,
          AId,
          Dados
        );

        Result := TInstituicaoEntidadeAtendidaDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          AId
        );

        if Result = nil then
          raise Exception.Create(
            'Cliente/entidade atualizado, mas não foi possível recuperar os dados.'
          );

        Conn.Commit;
      except
        if Conn.InTransaction then Conn.Rollback;
        Result.Free;
        Result := nil;
        raise;
      end;
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoEntidadeAtendidaService.AlterarSituacao(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AId: Int64;
  const ASituacao: string
): TInstituicaoEntidadeAtendidaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  Atual: TInstituicaoEntidadeAtendidaItem;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'entidade_atendida.inativar'
  );

  Situacao := UpperCase(Trim(ASituacao));

  if not MatchText(Situacao, ['ATIVO','INATIVO']) then
    TAppErrors.RaiseBadRequest('Situação inválida.');

  if AId <= 0 then
    TAppErrors.RaiseBadRequest('Cliente/entidade inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TInstituicaoEntidadeAtendidaDAO.BuscarPorId(
      Conn,
      AIdInstituicao,
      AId
    );
    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest('Cliente/entidade não encontrado.');

      Conn.StartTransaction;
      try
        TInstituicaoEntidadeAtendidaDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AId,
          Situacao
        );

        Result := TInstituicaoEntidadeAtendidaDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          AId
        );

        if Result = nil then
          raise Exception.Create(
            'Situação atualizada, mas não foi possível recuperar o cliente/entidade.'
          );

        Conn.Commit;
      except
        if Conn.InTransaction then Conn.Rollback;
        Result.Free;
        Result := nil;
        raise;
      end;
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
