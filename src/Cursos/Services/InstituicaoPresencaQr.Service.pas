unit InstituicaoPresencaQr.Service;

interface

uses
  InstituicaoPresenca.Model;

type
  TInstituicaoPresencaQrService = class
  private
    class function ExtrairCodigo(
      const AConteudoQr: string
    ): string; static;

  public
    class function Registrar(
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro,
            ARegistradoPor: Int64;
      const AConteudoQr: string
    ): TInstituicaoPresencaItem; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPresenca.DAO,
  InstituicaoPresencaQr.DAO;

class function TInstituicaoPresencaQrService.ExtrairCodigo(
  const AConteudoQr: string
): string;
const
  PREFIXO = 'CERTIFICA:P:';
var
  S: string;
begin
  S := Trim(AConteudoQr);

  if S.IsEmpty then
    TAppErrors.RaiseBadRequest('QR Code não informado.');

  if Length(S) > 150 then
    TAppErrors.RaiseBadRequest('Conteúdo do QR Code inválido.');

  if SameText(Copy(S, 1, Length(PREFIXO)), PREFIXO) then
    Delete(S, 1, Length(PREFIXO));

  S := UpperCase(Trim(S));

  if S.IsEmpty then
    TAppErrors.RaiseBadRequest('Código do participante não informado.');

  Result := S;
end;

class function TInstituicaoPresencaQrService.Registrar(
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        ARegistradoPor: Int64;
  const AConteudoQr: string
): TInstituicaoPresencaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Codigo: string;
  Participante: TParticipanteQrInfo;
  Inscricao: TInscricaoQrInfo;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if ARegistradoPor <= 0 then
    TAppErrors.RaiseUnauthorized('Usuário da instituição não identificado.');

  if (AIdTurma <= 0) or (AIdEncontro <= 0) then
    TAppErrors.RaiseBadRequest('Turma/encontro inválido.');

  Codigo := ExtrairCodigo(AConteudoQr);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TInstituicaoPresencaQrDAO.EncontroValido(
      Conn,
      AIdInstituicao,
      AIdTurma,
      AIdEncontro
    ) then
      TAppErrors.RaiseBadRequest(
        'Encontro não encontrado ou cancelado.'
      );

    Participante := TInstituicaoPresencaQrDAO.BuscarParticipante(
      Conn,
      AIdInstituicao,
      Codigo
    );

    if not Participante.Encontrado then
      TAppErrors.RaiseBadRequest(
        'Participante não encontrado para este QR Code.'
      );

    Inscricao := TInstituicaoPresencaQrDAO.BuscarInscricaoAprovada(
      Conn,
      AIdInstituicao,
      AIdTurma,
      Participante.IdParticipante
    );

    if not Inscricao.Encontrada then
      TAppErrors.RaiseBadRequest(
        'O participante não possui inscrição confirmada nesta turma.'
      );

    Conn.StartTransaction;
    try
      TInstituicaoPresencaQrDAO.RegistrarPresenca(
        Conn,
        AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        Inscricao.IdInscricao,
        ARegistradoPor
      );

      Result := TInstituicaoPresencaDAO.BuscarRegistro(
        Conn,
        AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        Inscricao.IdInscricao
      );

      if Result = nil then
        raise Exception.Create(
          'Presença registrada, mas não foi possível recuperar o registro.'
        );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;

      Result.Free;
      Result := nil;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

end.
