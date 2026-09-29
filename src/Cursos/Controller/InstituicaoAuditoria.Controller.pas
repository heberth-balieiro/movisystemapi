unit InstituicaoAuditoria.Controller;

interface

type
  TInstituicaoAuditoriaController = class
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
  InstituicaoPermissao.Service,
  InstituicaoAuditoria.Model,
  InstituicaoAuditoria.Service;

function Autorizar(
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

  if (AClaims.IdInstituicao <= 0) or
     (AClaims.IdUsuarioInstituicao <= 0) then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto válido da instituição.'
    );
    Exit;
  end;

  TInstituicaoPermissaoService.Exigir(
    AClaims.IdInstituicao,
    AClaims.IdUsuarioInstituicao,
    'auditoria.visualizar'
  );

  Result := True;
end;

class procedure TInstituicaoAuditoriaController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/auditoria',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoAuditoriaResultado;
      Item: TInstituicaoAuditoriaItem;
      Dados, Paginacao, UsuarioJson, ItemJson: TJSONObject;
      Itens: TJSONArray;
      Pagina, PorPagina, TotalPaginas: Integer;
    begin
      Res.RawWebResponse.SetCustomHeader(
        'Cache-Control',
        'private, no-store'
      );

      try
        if not Autorizar(
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
            50
          );

        Resultado :=
          TInstituicaoAuditoriaService.Listar(
            Claims.IdInstituicao,
            Req.Query.Items['busca'],
            Req.Query.Items['acao'],
            Req.Query.Items['entidade'],
            Req.Query.Items['data_inicio'],
            Req.Query.Items['data_fim'],
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

            if Item.IdUsuarioInstituicao > 0 then
            begin
              UsuarioJson := TJSONObject.Create;
              UsuarioJson.AddPair(
                'id_usuario_instituicao',
                TJSONNumber.Create(
                  Item.IdUsuarioInstituicao
                )
              );
              UsuarioJson.AddPair(
                'nome',
                Item.UsuarioNome
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

            Itens.AddElement(
              ItemJson
            );
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
