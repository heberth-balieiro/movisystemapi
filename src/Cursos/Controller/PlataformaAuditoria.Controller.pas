unit PlataformaAuditoria.Controller;

interface

type
  TPlataformaAuditoriaController = class
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
  PlataformaAuditoria.Model,
  PlataformaAuditoria.Service;

function AutorizarSuperAdminAuditoria(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if not TAppToken.PossuiRole(AClaims.Roles, 'SUPER_ADMIN') then
  begin
    TAppResponse.Forbidden(
      Res,
      'Sem permissão para consultar a auditoria da plataforma.'
    );
    Exit;
  end;

  Result := True;
end;

class procedure TPlataformaAuditoriaController.Registry;
begin
  THorse.Get(
    '/v1/certifica/plataforma/auditoria',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TPlataformaAuditoriaResultado;
      Item: TPlataformaAuditoriaItem;
      Dados, Paginacao, UsuarioJson, ItemJson: TJSONObject;
      Itens: TJSONArray;
      Busca, Acao, DataInicio, DataFim: string;
      Pagina, PorPagina, TotalPaginas: Integer;
    begin
      try
        if not AutorizarSuperAdminAuditoria(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Busca := Trim(Req.Query.Items['busca']);
        Acao := Trim(Req.Query.Items['acao']);
        DataInicio := Trim(Req.Query.Items['data_inicio']);
        DataFim := Trim(Req.Query.Items['data_fim']);

        Pagina := StrToIntDef(
          Req.Query.Items['page'],
          1
        );

        PorPagina := StrToIntDef(
          Req.Query.Items['page_size'],
          50
        );

        Resultado :=
          TPlataformaAuditoriaService.Listar(
            Busca,
            Acao,
            DataInicio,
            DataFim,
            Pagina,
            PorPagina
          );

        try
          Itens := TJSONArray.Create;

          for Item in Resultado.Itens do
          begin
            ItemJson := TJSONObject.Create;

            ItemJson.AddPair(
              'id',
              TJSONNumber.Create(Item.Id)
            );

            ItemJson.AddPair(
              'criado_em',
              FormatDateTime(
                'yyyy-mm-dd"T"hh:nn:ss',
                Item.CriadoEm
              )
            );

            if Item.IdUsuario > 0 then
            begin
              UsuarioJson := TJSONObject.Create;

              UsuarioJson.AddPair(
                'id',
                TJSONNumber.Create(Item.IdUsuario)
              );

              UsuarioJson.AddPair(
                'nome',
                Item.UsuarioNome
              );

              UsuarioJson.AddPair(
                'email',
                Item.UsuarioEmail
              );

              ItemJson.AddPair(
                'usuario',
                UsuarioJson
              );
            end
            else
              ItemJson.AddPair(
                'usuario',
                TJSONNull.Create
              );

            ItemJson.AddPair('acao', Item.Acao);
            ItemJson.AddPair('entidade', Item.Entidade);
            ItemJson.AddPair('registro_id', Item.RegistroId);
            ItemJson.AddPair('metodo_http', Item.MetodoHttp);
            ItemJson.AddPair('rota', Item.Rota);
            ItemJson.AddPair('ip', Item.IP);

            ItemJson.AddPair(
              'sucesso',
              TJSONBool.Create(Item.Sucesso)
            );

            ItemJson.AddPair(
              'mensagem',
              Item.Mensagem
            );

            Itens.AddElement(ItemJson);
          end;

          if Resultado.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas :=
              (Resultado.Total + Resultado.PorPagina - 1)
              div Resultado.PorPagina;

          Paginacao := TJSONObject.Create;

          Paginacao.AddPair(
            'pagina',
            TJSONNumber.Create(Resultado.Pagina)
          );

          Paginacao.AddPair(
            'por_pagina',
            TJSONNumber.Create(Resultado.PorPagina)
          );

          Paginacao.AddPair(
            'total',
            TJSONNumber.Create(Resultado.Total)
          );

          Paginacao.AddPair(
            'total_paginas',
            TJSONNumber.Create(TotalPaginas)
          );

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', Itens);
          Dados.AddPair('paginacao', Paginacao);

          TAppResponse.Ok(
            Res,
            Dados,
            'Auditoria carregada com sucesso.'
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
end;

end.
