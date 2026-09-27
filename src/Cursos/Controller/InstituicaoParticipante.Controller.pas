unit InstituicaoParticipante.Controller;

interface

type
  TInstituicaoParticipanteController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  InstituicaoParticipante.Model,
  InstituicaoParticipante.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(
    Req,
    Res,
    AClaims
  ) then
    Exit;

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto de instituição.'
    );

    Exit;
  end;

  Result := True;
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: string = ''
): string;
var
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    Valor.Value;
end;

function JsonInt64(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Int64 = 0
): Int64;
var
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    StrToInt64Def(
      Valor.Value,
      ADefault
    );
end;

procedure LerCpfAlteracao(
  const AObj: TJSONObject;
  out ATemCpfInformado: Boolean;
  out ACpf: string
);
var
  Valor: TJSONValue;
begin
  ATemCpfInformado := False;
  ACpf := '';

  Valor :=
    AObj.GetValue(
      'cpf'
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  ACpf :=
    Trim(
      Valor.Value
    );

  ATemCpfInformado :=
    not ACpf.IsEmpty;
end;

procedure AddNullableString(
  const AObj: TJSONObject;
  const ANome,
        AValor: string
);
begin
  if Trim(AValor).IsEmpty then
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    )
  else
    AObj.AddPair(
      ANome,
      AValor
    );
end;

procedure AddNullableInt64(
  const AObj: TJSONObject;
  const ANome: string;
  const ATemValor: Boolean;
  const AValor: Int64
);
begin
  if ATemValor then
    AObj.AddPair(
      ANome,
      TJSONNumber.Create(
        AValor
      )
    )
  else
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    );
end;

function DataHoraISO(
  const AData: TDateTime
): string;
begin
  Result :=
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AData
    );
end;

function ParticipanteParaJson(
  const AItem: TInstituicaoParticipanteItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(
      AItem.Id
    )
  );

  Result.AddPair(
    'codigo_publico',
    AItem.CodigoPublico
  );

  AddNullableInt64(
    Result,
    'id_unidade_organizacional',
    AItem.TemUnidadeOrganizacional,
    AItem.IdUnidadeOrganizacional
  );

  AddNullableString(
    Result,
    'unidade_organizacional_nome',
    AItem.UnidadeOrganizacionalNome
  );

  AddNullableInt64(
    Result,
    'id_usuario_instituicao',
    AItem.TemUsuarioInstituicao,
    AItem.IdUsuarioInstituicao
  );

  AddNullableString(
    Result,
    'usuario_nome',
    AItem.UsuarioNome
  );

  AddNullableString(
    Result,
    'usuario_email',
    AItem.UsuarioEmail
  );

  Result.AddPair(
    'nome',
    AItem.Nome
  );

  AddNullableString(
    Result,
    'cpf_mascarado',
    AItem.CpfMascarado
  );

  AddNullableString(
    Result,
    'email',
    AItem.Email
  );

  AddNullableString(
    Result,
    'matricula',
    AItem.Matricula
  );

  AddNullableString(
    Result,
    'telefone',
    AItem.Telefone
  );

  AddNullableString(
    Result,
    'orgao_empresa',
    AItem.OrgaoEmpresa
  );

  AddNullableString(
    Result,
    'cargo',
    AItem.Cargo
  );

  Result.AddPair(
    'situacao',
    AItem.Situacao
  );

  if AItem.TemAnonimizadoEm then
    Result.AddPair(
      'anonimizado_em',
      DataHoraISO(
        AItem.AnonimizadoEm
      )
    )
  else
    Result.AddPair(
      'anonimizado_em',
      TJSONNull.Create
    );

  AddNullableString(
    Result,
    'motivo_anonimizacao',
    AItem.MotivoAnonimizacao
  );

  Result.AddPair(
    'criado_em',
    DataHoraISO(
      AItem.CriadoEm
    )
  );

  Result.AddPair(
    'atualizado_em',
    DataHoraISO(
      AItem.AtualizadoEm
    )
  );
end;

class procedure TInstituicaoParticipanteController.Registry;
begin

  THorse.Get(
    '/v1/certifica/instituicao/participantes',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoParticipanteLista;
      Item: TInstituicaoParticipanteItem;
      Dados: TJSONObject;
      Paginacao: TJSONObject;
      Itens: TJSONArray;
      Pagina: Integer;
      PorPagina: Integer;
      TotalPaginas: Integer;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Pagina :=
          StrToIntDef(
            Req.Query.Items['page'],
            1
          );

        PorPagina :=
          StrToIntDef(
            Req.Query.Items['page_size'],
            20
          );

        Resultado :=
          TInstituicaoParticipanteService.Listar(
            Claims.IdInstituicao,
            Req.Query.Items['busca'],
            Req.Query.Items['situacao'],
            Pagina,
            PorPagina
          );

        try
          Itens :=
            TJSONArray.Create;

          for Item in Resultado.Itens do
            Itens.AddElement(
              ParticipanteParaJson(
                Item
              )
            );

          if Resultado.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas :=
              (
                Resultado.Total +
                Resultado.PorPagina -
                1
              ) div Resultado.PorPagina;

          Paginacao :=
            TJSONObject.Create;

          Paginacao.AddPair(
            'pagina',
            TJSONNumber.Create(
              Resultado.Pagina
            )
          );

          Paginacao.AddPair(
            'por_pagina',
            TJSONNumber.Create(
              Resultado.PorPagina
            )
          );

          Paginacao.AddPair(
            'total',
            TJSONNumber.Create(
              Resultado.Total
            )
          );

          Paginacao.AddPair(
            'total_paginas',
            TJSONNumber.Create(
              TotalPaginas
            )
          );

          Dados :=
            TJSONObject.Create;

          Dados.AddPair(
            'itens',
            Itens
          );

          Dados.AddPair(
            'paginacao',
            Paginacao
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Participantes carregados com sucesso.'
          );

        finally
          Resultado.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );


  THorse.Post(
    '/v1/certifica/instituicao/participantes',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoParticipanteCadastro;
      Participante: TInstituicaoParticipanteItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Dados :=
            Default(
              TInstituicaoParticipanteCadastro
            );

          Dados.IdUnidadeOrganizacional :=
            JsonInt64(
              Body,
              'id_unidade_organizacional',
              0
            );

          Dados.IdUsuarioInstituicao :=
            JsonInt64(
              Body,
              'id_usuario_instituicao',
              0
            );

          Dados.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Dados.Cpf :=
            JsonString(
              Body,
              'cpf'
            );

          Dados.Email :=
            JsonString(
              Body,
              'email'
            );

          Dados.Matricula :=
            JsonString(
              Body,
              'matricula'
            );

          Dados.Telefone :=
            JsonString(
              Body,
              'telefone'
            );

          Dados.OrgaoEmpresa :=
            JsonString(
              Body,
              'orgao_empresa'
            );

          Dados.Cargo :=
            JsonString(
              Body,
              'cargo'
            );

        finally
          Body.Free;
        end;

        Participante :=
          TInstituicaoParticipanteService.Cadastrar(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            Dados
          );

        try
          TAppResponse.Ok(
            Res,
            ParticipanteParaJson(
              Participante
            ),
            'Participante cadastrado com sucesso.'
          );

        finally
          Participante.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );


  THorse.Get(
    '/v1/certifica/instituicao/participantes/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdParticipante: Int64;
      Participante: TInstituicaoParticipanteItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdParticipante :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Participante :=
          TInstituicaoParticipanteService.BuscarPorId(
            Claims.IdInstituicao,
            IdParticipante
          );

        try
          TAppResponse.Ok(
            Res,
            ParticipanteParaJson(
              Participante
            ),
            'Participante carregado com sucesso.'
          );

        finally
          Participante.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );


  THorse.Put(
    '/v1/certifica/instituicao/participantes/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdParticipante: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoParticipanteAlteracao;
      Participante: TInstituicaoParticipanteItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdParticipante :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Dados :=
            Default(
              TInstituicaoParticipanteAlteracao
            );

          Dados.IdUnidadeOrganizacional :=
            JsonInt64(
              Body,
              'id_unidade_organizacional',
              0
            );

          Dados.IdUsuarioInstituicao :=
            JsonInt64(
              Body,
              'id_usuario_instituicao',
              0
            );

          Dados.Nome :=
            JsonString(
              Body,
              'nome'
            );

          LerCpfAlteracao(
            Body,
            Dados.TemCpfInformado,
            Dados.Cpf
          );

          Dados.Email :=
            JsonString(
              Body,
              'email'
            );

          Dados.Matricula :=
            JsonString(
              Body,
              'matricula'
            );

          Dados.Telefone :=
            JsonString(
              Body,
              'telefone'
            );

          Dados.OrgaoEmpresa :=
            JsonString(
              Body,
              'orgao_empresa'
            );

          Dados.Cargo :=
            JsonString(
              Body,
              'cargo'
            );

        finally
          Body.Free;
        end;

        Participante :=
          TInstituicaoParticipanteService.Atualizar(
            Claims.IdInstituicao,
            IdParticipante,
            Dados
          );

        try
          TAppResponse.Ok(
            Res,
            ParticipanteParaJson(
              Participante
            ),
            'Participante atualizado com sucesso.'
          );

        finally
          Participante.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );


  THorse.Patch(
    '/v1/certifica/instituicao/participantes/:id/situacao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdParticipante: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao: string;
      Participante: TInstituicaoParticipanteItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdParticipante :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Situacao :=
            JsonString(
              Body,
              'situacao'
            );

        finally
          Body.Free;
        end;

        Participante :=
          TInstituicaoParticipanteService.AlterarSituacao(
            Claims.IdInstituicao,
            IdParticipante,
            Situacao
          );

        try
          TAppResponse.Ok(
            Res,
            ParticipanteParaJson(
              Participante
            ),
            'Situação do participante atualizada com sucesso.'
          );

        finally
          Participante.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

end;

end.
