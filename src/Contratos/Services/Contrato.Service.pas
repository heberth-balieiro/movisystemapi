unit Contrato.Service;

interface

uses
  Contrato.Model;

type
  TContratoService = class
  private
    class function GerarCodigoPublico: string; static;
    class procedure ValidarDados(const ADados: TContratoCadastro); static;
  public
    class function Listar(
      const AIdInstituicao, AIdUsuario: Int64;
      const ABusca, ASituacao: string;
      const APagina, APorPagina: Integer
    ): TContratoLista; static;

    class function BuscarPorId(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64
    ): TContratoItem; static;

    class function Cadastrar(
      const AIdInstituicao, AIdUsuario: Int64;
      const ADados: TContratoCadastro
    ): TContratoItem; static;

    class function Atualizar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
      const ADados: TContratoCadastro
    ): TContratoItem; static;

    class function Encerrar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
      const AMotivo: string
    ): TContratoItem; static;

    class function Cancelar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
      const AMotivo: string
    ): TContratoItem; static;
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
  Contrato.DAO,
  ContratoProjecao.DAO;

class function TContratoService.GerarCodigoPublico: string;
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

class procedure TContratoService.ValidarDados(const ADados: TContratoCadastro);
begin
  if Trim(ADados.Numero).IsEmpty then
    TAppErrors.RaiseBadRequest('Número do contrato não informado.');

  if Trim(ADados.NomeContratado).IsEmpty then
    TAppErrors.RaiseBadRequest('Contratado não informado.');

  if Trim(ADados.Titulo).IsEmpty then
    TAppErrors.RaiseBadRequest('Título do contrato não informado.');

  if Trim(ADados.Objeto).IsEmpty then
    TAppErrors.RaiseBadRequest('Objeto do contrato não informado.');

  if ADados.DataInicio <= 0 then
    TAppErrors.RaiseBadRequest('Data inicial não informada.');

  if ADados.DataFim <= 0 then
    TAppErrors.RaiseBadRequest('Data final não informada.');

  if ADados.DataFim < ADados.DataInicio then
    TAppErrors.RaiseBadRequest('A data final não pode ser menor que a data inicial.');

  if ADados.ValorInicial < 0 then
    TAppErrors.RaiseBadRequest('Valor inicial inválido.');

  if ADados.ValorAtual < 0 then
    TAppErrors.RaiseBadRequest('Valor atual inválido.');

  if not MatchText(UpperCase(Trim(ADados.TipoGestao)), ['PUBLICA','PRIVADA']) then
    TAppErrors.RaiseBadRequest('Tipo de gestão inválido.');

  if not MatchText(UpperCase(Trim(ADados.Situacao)), ['RASCUNHO','ATIVO','ENCERRADO','CANCELADO']) then
    TAppErrors.RaiseBadRequest('Situação do contrato inválida.');
end;

class function TContratoService.Listar(
  const AIdInstituicao, AIdUsuario: Int64;
  const ABusca, ASituacao: string;
  const APagina, APorPagina: Integer
): TContratoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TContratoFiltro;
begin
  TInstituicaoPermissaoService.Exigir(AIdInstituicao, AIdUsuario, 'contrato.visualizar');

  Filtro := Default(TContratoFiltro);
  Filtro.Busca := Trim(ABusca);
  Filtro.Situacao := UpperCase(Trim(ASituacao));
  Filtro.Pagina := APagina;
  if Filtro.Pagina < 1 then Filtro.Pagina := 1;
  Filtro.PorPagina := APorPagina;
  if Filtro.PorPagina < 1 then Filtro.PorPagina := 20;
  if Filtro.PorPagina > 100 then Filtro.PorPagina := 100;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TContratoDAO.Listar(Conn, AIdInstituicao, Filtro);
  finally
    Conn.Free;
  end;
end;

class function TContratoService.BuscarPorId(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64
): TContratoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdContrato <= 0 then
    TAppErrors.RaiseBadRequest('Contrato inválido.');

  TInstituicaoPermissaoService.Exigir(AIdInstituicao, AIdUsuario, 'contrato.visualizar');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TContratoDAO.BuscarPorId(Conn, AIdInstituicao, AIdContrato);
    if Result = nil then
      TAppErrors.RaiseBadRequest('Contrato não encontrado.');
  finally
    Conn.Free;
  end;
end;

class function TContratoService.Cadastrar(
  const AIdInstituicao, AIdUsuario: Int64;
  const ADados: TContratoCadastro
): TContratoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TContratoCadastro;
  IdEntidade, IdContrato: Int64;
  Codigo: string;
begin
  Result := nil;
  TInstituicaoPermissaoService.Exigir(AIdInstituicao, AIdUsuario, 'contrato.cadastrar');

  Dados := ADados;
  Dados.TipoGestao := UpperCase(Trim(Dados.TipoGestao));
  if Dados.TipoGestao.IsEmpty then Dados.TipoGestao := 'PUBLICA';
  Dados.Tipo := UpperCase(Trim(Dados.Tipo));
  if Dados.Tipo.IsEmpty then Dados.Tipo := 'SERVICO';
  Dados.Situacao := UpperCase(Trim(Dados.Situacao));
  if Dados.Situacao.IsEmpty then Dados.Situacao := 'RASCUNHO';
  if Dados.ValorAtual = 0 then Dados.ValorAtual := Dados.ValorInicial;
  ValidarDados(Dados);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TContratoDAO.ExisteNumero(Conn, AIdInstituicao, Dados.Numero) then
      TAppErrors.RaiseBadRequest('Já existe um contrato com este número nesta instituição.');

    Conn.StartTransaction;
    try
      IdEntidade := TContratoDAO.GarantirEntidade(
        Conn, AIdInstituicao, Dados.DocumentoContratado, Dados.NomeContratado
      );

      Codigo := GerarCodigoPublico;
      IdContrato := TContratoDAO.Inserir(
        Conn, AIdInstituicao, AIdUsuario, IdEntidade, Codigo, Dados
      );

      TContratoDAO.InserirHistorico(
        Conn, AIdInstituicao, IdContrato, AIdUsuario,
        'CRIADO', 'Contrato criado.'
      );

      TContratoProjecaoDAO.GerarAutomaticas(
        Conn,
        AIdInstituicao,
        IdContrato,
        AIdUsuario,
        Dados.DataInicio,
        Dados.DataFim,
        Dados.ValorAtual,
        False
      );

      Result := TContratoDAO.BuscarPorId(Conn, AIdInstituicao, IdContrato);
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


class function TContratoService.Encerrar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
  const AMotivo: string
): TContratoItem;
var
  Config:TAppApiConfig;
  Conn:TUniConnection;
  Atual:TContratoItem;
begin
  Result:=nil;
  if Trim(AMotivo).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o motivo do encerramento.');

  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.encerrar');

  Config:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn:=TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual:=TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
    try
      if Atual=nil then TAppErrors.RaiseBadRequest('Contrato não encontrado.');
      if SameText(Atual.Situacao,'ENCERRADO') or SameText(Atual.Situacao,'CANCELADO') then
        TAppErrors.RaiseBadRequest('Contrato já finalizado.');

      Conn.StartTransaction;
      try
        TContratoDAO.AlterarSituacaoFinal(Conn,AIdInstituicao,AIdContrato,AIdUsuario,'ENCERRADO',AMotivo);
        TContratoDAO.InserirHistorico(
          Conn,AIdInstituicao,AIdContrato,AIdUsuario,
          'ENCERRADO','Contrato encerrado. Motivo: '+Trim(AMotivo)
        );
        Result:=TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
        Conn.Commit;
      except
        if Conn.InTransaction then Conn.Rollback;
        Result.Free; Result:=nil; raise;
      end;
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TContratoService.Cancelar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
  const AMotivo: string
): TContratoItem;
var
  Config:TAppApiConfig;
  Conn:TUniConnection;
  Atual:TContratoItem;
begin
  Result:=nil;
  if Trim(AMotivo).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o motivo do cancelamento.');

  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.cancelar');

  Config:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn:=TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual:=TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
    try
      if Atual=nil then TAppErrors.RaiseBadRequest('Contrato não encontrado.');
      if SameText(Atual.Situacao,'ENCERRADO') or SameText(Atual.Situacao,'CANCELADO') then
        TAppErrors.RaiseBadRequest('Contrato já finalizado.');

      Conn.StartTransaction;
      try
        TContratoDAO.AlterarSituacaoFinal(Conn,AIdInstituicao,AIdContrato,AIdUsuario,'CANCELADO',AMotivo);
        TContratoDAO.InserirHistorico(
          Conn,AIdInstituicao,AIdContrato,AIdUsuario,
          'CANCELADO','Contrato cancelado. Motivo: '+Trim(AMotivo)
        );
        Result:=TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
        Conn.Commit;
      except
        if Conn.InTransaction then Conn.Rollback;
        Result.Free; Result:=nil; raise;
      end;
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TContratoService.Atualizar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
  const ADados: TContratoCadastro
): TContratoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TContratoItem;
  Dados: TContratoCadastro;
  IdEntidade: Int64;
begin
  Result := nil;
  if AIdContrato <= 0 then
    TAppErrors.RaiseBadRequest('Contrato inválido.');

  TInstituicaoPermissaoService.Exigir(AIdInstituicao, AIdUsuario, 'contrato.editar');

  Dados := ADados;
  Dados.TipoGestao := UpperCase(Trim(Dados.TipoGestao));
  Dados.Tipo := UpperCase(Trim(Dados.Tipo));
  Dados.Situacao := UpperCase(Trim(Dados.Situacao));
  ValidarDados(Dados);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TContratoDAO.BuscarPorId(Conn, AIdInstituicao, AIdContrato);
    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest('Contrato não encontrado.');

      if TContratoDAO.ExisteNumero(Conn, AIdInstituicao, Dados.Numero, AIdContrato) then
        TAppErrors.RaiseBadRequest('Já existe outro contrato com este número nesta instituição.');

      Conn.StartTransaction;
      try
        IdEntidade := TContratoDAO.GarantirEntidade(
          Conn, AIdInstituicao, Dados.DocumentoContratado, Dados.NomeContratado
        );

        TContratoDAO.Atualizar(
          Conn, AIdInstituicao, AIdContrato, AIdUsuario, IdEntidade, Dados
        );

        TContratoDAO.InserirHistorico(
          Conn, AIdInstituicao, AIdContrato, AIdUsuario,
          'ALTERADO', 'Dados gerais do contrato atualizados.'
        );

        if (Atual.DataInicio <> Dados.DataInicio) or
           (Atual.DataFim <> Dados.DataFim) or
           (Atual.ValorAtual <> Dados.ValorAtual) then
          TContratoProjecaoDAO.GerarAutomaticas(
            Conn,
            AIdInstituicao,
            AIdContrato,
            AIdUsuario,
            Dados.DataInicio,
            Dados.DataFim,
            Dados.ValorAtual,
            True
          );

        Result := TContratoDAO.BuscarPorId(Conn, AIdInstituicao, AIdContrato);
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
