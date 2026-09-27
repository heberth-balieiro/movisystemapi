unit EleicaoAuditoriaAPI.Dao;

interface

uses
  Uni, System.Generics.Collections;

type
  TEleicaoAuditoriaItem = record
    Id: Integer;
    UsuarioId: Integer;
    TipoEvento: string;
    Origem: string;
    Sucesso: string;
    Descricao: string;
    IP: string;
    UserAgent: string;
    CriadoEm: TDateTime;
  end;

  TEleicaoAuditoriaLista = TList<TEleicaoAuditoriaItem>;

type
  TEleicaoAuditoriaFiltro = record
    TipoEvento: string;
    Origem: string;
    Sucesso: string;
    DataInicial: TDateTime;
    DataFinal: TDateTime;
    TemDataInicial: Boolean;
    TemDataFinal: Boolean;
  end;

type
  TEleicaoAuditoriaAPIDao = class
  public
    class procedure RegistrarEvento(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdUsuario: Integer;
      const ATipoEvento: string;
      const AOrigem: string;
      const ASucesso: string;
      const ADescricao: string;
      const AIP: string = '';
      const AUserAgent: string = ''
    ); static;

    class procedure BuscarAuditoria(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AFiltro: TEleicaoAuditoriaFiltro;
      const ALista: TEleicaoAuditoriaLista
    ); static;
  end;

implementation

uses
  System.SysUtils,
  DB;

{ TEleicaoAuditoriaAPIDao }

class procedure TEleicaoAuditoriaAPIDao.RegistrarEvento(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdUsuario: Integer;
  const ATipoEvento: string;
  const AOrigem: string;
  const ASucesso: string;
  const ADescricao: string;
  const AIP: string;
  const AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO eleicao_auditoria (' +
      ' empresa_id, eleicao_id, usuario_id, tipo_evento, origem, sucesso, descricao, ip, user_agent ' +
      ') VALUES (' +
      ' :idempresa, :ideleicao, :idusuario, :tipoevento, :origem, :sucesso, :descricao, :ip, :useragent ' +
      ')';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;

    if AIdUsuario > 0 then
      Qry.ParamByName('idusuario').AsInteger := AIdUsuario
    else
    begin
      Qry.ParamByName('idusuario').DataType := ftInteger;
      Qry.ParamByName('idusuario').Clear;
    end;

    Qry.ParamByName('tipoevento').AsString := UpperCase(Trim(ATipoEvento));
    Qry.ParamByName('origem').AsString := UpperCase(Trim(AOrigem));
    Qry.ParamByName('sucesso').AsString := UpperCase(Trim(ASucesso));

    if Trim(ADescricao) <> '' then
      Qry.ParamByName('descricao').AsString := Trim(ADescricao)
    else
    begin
      Qry.ParamByName('descricao').DataType := ftString;
      Qry.ParamByName('descricao').Clear;
    end;

    if Trim(AIP) <> '' then
      Qry.ParamByName('ip').AsString := Trim(AIP)
    else
    begin
      Qry.ParamByName('ip').DataType := ftString;
      Qry.ParamByName('ip').Clear;
    end;

    if Trim(AUserAgent) <> '' then
      Qry.ParamByName('useragent').AsString := Trim(AUserAgent)
    else
    begin
      Qry.ParamByName('useragent').DataType := ftString;
      Qry.ParamByName('useragent').Clear;
    end;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoAuditoriaAPIDao.BuscarAuditoria(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AFiltro: TEleicaoAuditoriaFiltro;
  const ALista: TEleicaoAuditoriaLista
);
var
  Qry: TUniQuery;
  Item: TEleicaoAuditoriaItem;
begin
  ALista.Clear;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
            'SELECT id, usuario_id, tipo_evento, origem, sucesso, descricao, ip, user_agent, criado_em ' +
            'FROM eleicao_auditoria ' +
            'WHERE empresa_id = :idempresa ' +
            'AND eleicao_id = :ideleicao ';

    if not Trim(AFiltro.TipoEvento).IsEmpty then
    Qry.SQL.Add('AND tipo_evento = :tipoevento');
    if not Trim(AFiltro.Origem).IsEmpty then
    Qry.SQL.Add('AND origem = :origem');
    if not Trim(AFiltro.Sucesso).IsEmpty then
    Qry.SQL.Add('AND sucesso = :sucesso');
    if AFiltro.TemDataInicial then
    Qry.SQL.Add('AND criado_em >= :datainicial');
    if AFiltro.TemDataFinal then
    Qry.SQL.Add('AND criado_em <= :datafinal');

    Qry.SQL.Add('ORDER BY criado_em DESC, id DESC');

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;

    if not Trim(AFiltro.TipoEvento).IsEmpty then
    Qry.ParamByName('tipoevento').AsString := UpperCase(Trim(AFiltro.TipoEvento));
    if not Trim(AFiltro.Origem).IsEmpty then
    Qry.ParamByName('origem').AsString := UpperCase(Trim(AFiltro.Origem));
    if not Trim(AFiltro.Sucesso).IsEmpty then
    Qry.ParamByName('sucesso').AsString := UpperCase(Trim(AFiltro.Sucesso));
    if AFiltro.TemDataInicial then
    Qry.ParamByName('datainicial').AsDateTime := AFiltro.DataInicial;
    if AFiltro.TemDataFinal then
    Qry.ParamByName('datafinal').AsDateTime := AFiltro.DataFinal;

    Qry.Open;

    while not Qry.Eof do
    begin
      Item := Default(TEleicaoAuditoriaItem);

      Item.Id := Qry.FieldByName('id').AsInteger;

      if not Qry.FieldByName('usuario_id').IsNull then
        Item.UsuarioId := Qry.FieldByName('usuario_id').AsInteger;

      Item.TipoEvento := Qry.FieldByName('tipo_evento').AsString;
      Item.Origem := Qry.FieldByName('origem').AsString;
      Item.Sucesso := Qry.FieldByName('sucesso').AsString;
      Item.Descricao := Qry.FieldByName('descricao').AsString;
      Item.IP := Qry.FieldByName('ip').AsString;
      Item.UserAgent := Qry.FieldByName('user_agent').AsString;
      Item.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;

      ALista.Add(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;



end.
