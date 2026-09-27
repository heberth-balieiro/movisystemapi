unit InstituicaoCertificadoModelo.Controller;

interface

type
  TInstituicaoCertificadoModeloController = class
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
  InstituicaoCertificadoModelo.Model,
  InstituicaoCertificadoModelo.Service;

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
    AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result := Valor.Value;
end;

function JsonRaw(
  const AObj: TJSONObject;
  const ANome: string
): string;
var
  Valor: TJSONValue;
begin
  Result := '';

  Valor :=
    AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  if Valor is TJSONString then
    Result := Valor.Value
  else
    Result := Valor.ToJSON;
end;

function RawJsonParaValue(
  const ARaw: string
): TJSONValue;
begin
  Result := nil;

  if not Trim(ARaw).IsEmpty then
    Result :=
      TJSONObject.ParseJSONValue(
        ARaw
      );

  if Result = nil then
    Result := TJSONNull.Create;
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

function ModeloParaJson(
  const AModelo: TInstituicaoCertificadoModeloItem;
  const ADetalhado: Boolean
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(
      AModelo.Id
    )
  );

  Result.AddPair(
    'nome',
    AModelo.Nome
  );

  AddNullableString(
    Result,
    'descricao',
    AModelo.Descricao
  );

  AddNullableString(
    Result,
    'imagem_fundo_url',
    AModelo.ImagemFundoUrl
  );

  Result.AddPair(
    'situacao',
    AModelo.Situacao
  );

  if ADetalhado then
  begin
    AddNullableString(
      Result,
      'template_html',
      AModelo.TemplateHtml
    );

    Result.AddPair(
      'template_configuracao',
      RawJsonParaValue(
        AModelo.TemplateConfiguracao
      )
    );
  end;

  Result.AddPair(
    'criado_em',
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AModelo.CriadoEm
    )
  );

  Result.AddPair(
    'atualizado_em',
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AModelo.AtualizadoEm
    )
  );
end;

class procedure TInstituicaoCertificadoModeloController.Registry;
begin

  {$REGION 'Listar Modelos'}

  THorse.Get(
    '/v1/certifica/instituicao/certificado-modelos',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoCertificadoModeloLista;
      Modelo: TInstituicaoCertificadoModeloItem;
      Dados: TJSONObject;
      Paginacao: TJSONObject;
      Itens: TJSONArray;
      Busca: string;
      Situacao: string;
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

        Busca :=
          Trim(
            Req.Query.Items['busca']
          );

        Situacao :=
          Trim(
            Req.Query.Items['situacao']
          );

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
          TInstituicaoCertificadoModeloService.Listar(
            Claims.IdInstituicao,
            Busca,
            Situacao,
            Pagina,
            PorPagina
          );

        try
          Itens := TJSONArray.Create;

          for Modelo in Resultado.Itens do
            Itens.AddElement(
              ModeloParaJson(
                Modelo,
                False
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

          Paginacao := TJSONObject.Create;

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

          Dados := TJSONObject.Create;

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
            'Modelos de certificado carregados com sucesso.'
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

  {$ENDREGION}


  {$REGION 'Buscar Modelo'}

  THorse.Get(
    '/v1/certifica/instituicao/certificado-modelos/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdModelo: Int64;
      Modelo: TInstituicaoCertificadoModeloItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdModelo :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Modelo :=
          TInstituicaoCertificadoModeloService.BuscarPorId(
            Claims.IdInstituicao,
            IdModelo
          );

        try
          TAppResponse.Ok(
            Res,
            ModeloParaJson(
              Modelo,
              True
            ),
            'Modelo de certificado carregado com sucesso.'
          );
        finally
          Modelo.Free;
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

  {$ENDREGION}


  {$REGION 'Cadastrar Modelo'}

  THorse.Post(
    '/v1/certifica/instituicao/certificado-modelos',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Cadastro: TInstituicaoCertificadoModeloCadastro;
      Modelo: TInstituicaoCertificadoModeloItem;
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
          Cadastro :=
            Default(
              TInstituicaoCertificadoModeloCadastro
            );

          Cadastro.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Cadastro.Descricao :=
            JsonString(
              Body,
              'descricao'
            );

          Cadastro.TemplateHtml :=
            JsonString(
              Body,
              'template_html'
            );

          Cadastro.TemplateConfiguracao :=
            JsonRaw(
              Body,
              'template_configuracao'
            );

          Cadastro.ImagemFundoUrl :=
            JsonString(
              Body,
              'imagem_fundo_url'
            );

        finally
          Body.Free;
        end;

        Modelo :=
          TInstituicaoCertificadoModeloService.Cadastrar(
            Claims.IdInstituicao,
            Cadastro
          );

        try
          TAppResponse.Ok(
            Res,
            ModeloParaJson(
              Modelo,
              True
            ),
            'Modelo de certificado cadastrado com sucesso.'
          );
        finally
          Modelo.Free;
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

  {$ENDREGION}


  {$REGION 'Atualizar Modelo'}

  THorse.Put(
    '/v1/certifica/instituicao/certificado-modelos/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdModelo: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Alteracao: TInstituicaoCertificadoModeloAlteracao;
      Modelo: TInstituicaoCertificadoModeloItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdModelo :=
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
          Alteracao :=
            Default(
              TInstituicaoCertificadoModeloAlteracao
            );

          Alteracao.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Alteracao.Descricao :=
            JsonString(
              Body,
              'descricao'
            );

          Alteracao.TemplateHtml :=
            JsonString(
              Body,
              'template_html'
            );

          Alteracao.TemplateConfiguracao :=
            JsonRaw(
              Body,
              'template_configuracao'
            );

          Alteracao.ImagemFundoUrl :=
            JsonString(
              Body,
              'imagem_fundo_url'
            );

        finally
          Body.Free;
        end;

        Modelo :=
          TInstituicaoCertificadoModeloService.Atualizar(
            Claims.IdInstituicao,
            IdModelo,
            Alteracao
          );

        try
          TAppResponse.Ok(
            Res,
            ModeloParaJson(
              Modelo,
              True
            ),
            'Modelo de certificado atualizado com sucesso.'
          );
        finally
          Modelo.Free;
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

  {$ENDREGION}


  {$REGION 'Alterar Situação'}

  THorse.Patch(
    '/v1/certifica/instituicao/certificado-modelos/:id/situacao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdModelo: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao: string;
      Modelo: TInstituicaoCertificadoModeloItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdModelo :=
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

        Modelo :=
          TInstituicaoCertificadoModeloService.AlterarSituacao(
            Claims.IdInstituicao,
            IdModelo,
            Situacao
          );

        try
          TAppResponse.Ok(
            Res,
            ModeloParaJson(
              Modelo,
              True
            ),
            'Situação do modelo de certificado atualizada com sucesso.'
          );
        finally
          Modelo.Free;
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

  {$ENDREGION}

end;

end.
