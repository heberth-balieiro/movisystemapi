unit Auditoria.DAO;

interface

uses
  Uni;

type
  TAuditoriaRegistro = record
    IdInstituicao: Int64;
    IdUsuario: Int64;
    IdUsuarioInstituicao: Int64;
    Acao: string;
    Entidade: string;
    RegistroId: string;
    MetodoHttp: string;
    Rota: string;
    IP: string;
    UserAgent: string;
    Sucesso: Boolean;
    Mensagem: string;
    DadosAnteriores: string;
    DadosNovos: string;
  end;

  TAuditoriaDAO = class
  public
    class procedure Inserir(
      const AConn: TUniConnection;
      const ARegistro: TAuditoriaRegistro
    ); static;
  end;

implementation

uses
  System.SysUtils;

class procedure TAuditoriaDAO.Inserir(
  const AConn: TUniConnection;
  const ARegistro: TAuditoriaRegistro
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO auditoria_log (' +
      'id_instituicao, id_usuario, id_usuario_instituicao, ' +
      'acao, entidade, registro_id, metodo_http, rota, ip, user_agent, ' +
      'sucesso, mensagem, dados_anteriores, dados_novos' +
      ') VALUES (' +
      ':id_instituicao, :id_usuario, :id_usuario_instituicao, ' +
      ':acao, :entidade, :registro_id, :metodo_http, :rota, :ip, :user_agent, ' +
      ':sucesso, :mensagem, :dados_anteriores, :dados_novos' +
      ')';

    if ARegistro.IdInstituicao > 0 then
      Qry.ParamByName('id_instituicao').AsLargeInt := ARegistro.IdInstituicao
    else
      Qry.ParamByName('id_instituicao').Clear;

    if ARegistro.IdUsuario > 0 then
      Qry.ParamByName('id_usuario').AsLargeInt := ARegistro.IdUsuario
    else
      Qry.ParamByName('id_usuario').Clear;

    if (ARegistro.IdInstituicao > 0) and
       (ARegistro.IdUsuarioInstituicao > 0) then
      Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
        ARegistro.IdUsuarioInstituicao
    else
      Qry.ParamByName('id_usuario_instituicao').Clear;

    Qry.ParamByName('acao').AsString :=
      Copy(UpperCase(Trim(ARegistro.Acao)), 1, 80);

    if Trim(ARegistro.Entidade).IsEmpty then
      Qry.ParamByName('entidade').Clear
    else
      Qry.ParamByName('entidade').AsString :=
        Copy(LowerCase(Trim(ARegistro.Entidade)), 1, 80);

    if Trim(ARegistro.RegistroId).IsEmpty then
      Qry.ParamByName('registro_id').Clear
    else
      Qry.ParamByName('registro_id').AsString :=
        Copy(Trim(ARegistro.RegistroId), 1, 100);

    if Trim(ARegistro.MetodoHttp).IsEmpty then
      Qry.ParamByName('metodo_http').Clear
    else
      Qry.ParamByName('metodo_http').AsString :=
        Copy(UpperCase(Trim(ARegistro.MetodoHttp)), 1, 10);

    if Trim(ARegistro.Rota).IsEmpty then
      Qry.ParamByName('rota').Clear
    else
      Qry.ParamByName('rota').AsString :=
        Copy(Trim(ARegistro.Rota), 1, 500);

    if Trim(ARegistro.IP).IsEmpty then
      Qry.ParamByName('ip').Clear
    else
      Qry.ParamByName('ip').AsString :=
        Copy(Trim(ARegistro.IP), 1, 45);

    if Trim(ARegistro.UserAgent).IsEmpty then
      Qry.ParamByName('user_agent').Clear
    else
      Qry.ParamByName('user_agent').AsString :=
        Copy(Trim(ARegistro.UserAgent), 1, 1000);

    Qry.ParamByName('sucesso').AsInteger := Ord(ARegistro.Sucesso);

    if Trim(ARegistro.Mensagem).IsEmpty then
      Qry.ParamByName('mensagem').Clear
    else
      Qry.ParamByName('mensagem').AsString :=
        Copy(Trim(ARegistro.Mensagem), 1, 1000);

    if Trim(ARegistro.DadosAnteriores).IsEmpty then
      Qry.ParamByName('dados_anteriores').Clear
    else
      Qry.ParamByName('dados_anteriores').AsString :=
        ARegistro.DadosAnteriores;

    if Trim(ARegistro.DadosNovos).IsEmpty then
      Qry.ParamByName('dados_novos').Clear
    else
      Qry.ParamByName('dados_novos').AsString :=
        ARegistro.DadosNovos;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
