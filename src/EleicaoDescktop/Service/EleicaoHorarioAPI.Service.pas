{

sem início/fim
→ configuração inválida

agora < início
→ votação ainda não iniciada

agora > fim
→ período encerrado

dentro do horário + situação diferente de ABERTA
→ votação não disponível

dentro do horário + ABERTA
→ permitido


}


unit EleicaoHorarioAPI.Service;

interface

uses
  Uni;

type
  TEleicaoHorarioAPIService = class
  public
    class procedure ValidarPeriodoVotacao(
      const AConn: TUniConnection;
      const ASlug: string;
      const AIdEmpresa: Integer
    ); static;
  end;

implementation

uses
  System.SysUtils,
  App.Errors,
  EleicaoHorarioAPI.Dao,
  EleicaoAdminAPI.Dao;

class procedure TEleicaoHorarioAPIService.ValidarPeriodoVotacao(
  const AConn: TUniConnection;
  const ASlug: string;
  const AIdEmpresa: Integer
);
var
  Horario: TEleicaoHorario;
begin
  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

  if not TEleicaoHorarioAPIDao.BuscarHorario(AConn, Trim(ASlug), AIdEmpresa, Horario) then
    TAppErrors.RaiseNotFound('Eleição não encontrada.');

  // Garante as transições automáticas também quando o usuário acessa
  // diretamente login/confirmação/votação, sem depender da página inicial.
  if SameText(Trim(Horario.Situacao), 'AGENDADA') and
     Horario.TemInicio and Horario.TemFim and
     (Horario.DataHoraAtual >= Horario.DataHoraInicio) and
     (Horario.DataHoraAtual < Horario.DataHoraFim) then
  begin
    TEleicaoAdminAPIDao.AbrirAutomaticamente(
      AConn,
      AIdEmpresa,
      Horario.IdEleicao
    );

    TEleicaoHorarioAPIDao.BuscarHorario(
      AConn,
      Trim(ASlug),
      AIdEmpresa,
      Horario
    );
  end;

  if SameText(Trim(Horario.Situacao), 'ABERTA') and
     Horario.TemFim and
     (Horario.DataHoraAtual >= Horario.DataHoraFim) then
  begin
    TEleicaoAdminAPIDao.EncerrarAutomaticamente(
      AConn,
      AIdEmpresa,
      Horario.IdEleicao
    );

    TEleicaoHorarioAPIDao.BuscarHorario(
      AConn,
      Trim(ASlug),
      AIdEmpresa,
      Horario
    );
  end;

  if not Horario.TemInicio then
    TAppErrors.RaiseBadRequest('Data e hora de início da votação não configuradas.');

  if not Horario.TemFim then
    TAppErrors.RaiseBadRequest('Data e hora de encerramento da votação não configuradas.');

  if Horario.DataHoraFim <= Horario.DataHoraInicio then
    TAppErrors.RaiseBadRequest('Período da votação configurado incorretamente.');

  if Horario.DataHoraAtual < Horario.DataHoraInicio then
    TAppErrors.RaiseBadRequest('A votação ainda não foi iniciada.');

  if Horario.DataHoraAtual >= Horario.DataHoraFim then
    TAppErrors.RaiseBadRequest('O período de votação foi encerrado.');

  if not SameText(Trim(Horario.Situacao), 'ABERTA') then
    TAppErrors.RaiseBadRequest('A votação não está disponível.');
end;

end.
