unit App.JWT;

interface

uses
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  App.Config,
  Winapi.ActiveX;

type
  TJWTClaims = record
    UserId: Int64;
    Issuer: string;
    Roles: TArray<string>;
    ExpUnix: Int64;
    IssuedAtUnix: Int64;

    // Contexto legado
    IdEmpresa: Int64;
    EleicaoSlug: string;

    // Contexto SaaS Cursos
    IdInstituicao: Int64;
    IdUsuarioInstituicao: Int64;
  end;

  TAppJWT = class
  private
    class function RemoverChaves(
      const AString: string
    ): string; static;

  public
    // Token dos módulos legados
    class function GerarToken(
      const ACfg: TAppJWTConfig;
      const AUserId, AIdEmpresa: Int64;
      const ARoles: TArray<string>;
      const AEleicaoSlug: string = '';
      const ATtlMinutos: Integer = 0
    ): string; static;

    // Token do administrador global da plataforma
    class function GerarTokenGlobal(
      const ACfg: TAppJWTConfig;
      const AUserId: Int64;
      const ARoles: TArray<string>;
      const ATtlMinutos: Integer = 0
    ): string; static;

    // Token de usuário vinculado a uma instituição
    class function GerarTokenInstituicao(
      const ACfg: TAppJWTConfig;
      const AUserId, AIdInstituicao: Int64;
      const ARoles: TArray<string>;
      const AIdUsuarioInstituicao: Int64;
      const ATtlMinutos: Integer = 0
    ): string; static;

    class function ValidarEExtrair(
      const ACfg: TAppJWTConfig;
      const AToken: string;
      out AClaims: TJWTClaims
    ): Boolean; static;

    class function ExtrairBearerToken(
      const AAuthorizationHeader: string
    ): string; static;

    class function GerarGuid: string;
  end;

implementation

uses
  JOSE.Core.JWS,
  JOSE.Types.JSON;

{ TAppJWT }

class function TAppJWT.ExtrairBearerToken(
  const AAuthorizationHeader: string
): string;
var
  S: string;
begin
  Result := '';

  S := Trim(AAuthorizationHeader);

  if S.IsEmpty then
    Exit;

  if S.ToLower.StartsWith('bearer ') then
    Result := Trim(
      Copy(
        S,
        8,
        MaxInt
      )
    );
end;

class function TAppJWT.GerarGuid: string;
var
  NewGUID: TGUID;
begin
  Result := '';

  CoInitialize(nil);
  try
    CreateGUID(NewGUID);

    Result :=
      RemoverChaves(
        GUIDToString(NewGUID)
      );
  finally
    CoUninitialize;
  end;
end;

class function TAppJWT.RemoverChaves(
  const AString: string
): string;
begin
  Result :=
    StringReplace(
      AString,
      '{',
      '',
      [rfReplaceAll]
    );

  Result :=
    StringReplace(
      Result,
      '}',
      '',
      [rfReplaceAll]
    );
end;

{ Token legado }

class function TAppJWT.GerarToken(
  const ACfg: TAppJWTConfig;
  const AUserId, AIdEmpresa: Int64;
  const ARoles: TArray<string>;
  const AEleicaoSlug: string;
  const ATtlMinutos: Integer
): string;
var
  LJWT: TJWT;
  Arr: TJSONArray;
  Role: string;
  TtlMinutos: Integer;
begin
  TtlMinutos := ATtlMinutos;

  if TtlMinutos <= 0 then
    TtlMinutos := ACfg.TtlMinutos;

  if TtlMinutos <= 0 then
    TtlMinutos := 60;

  if ACfg.Secret.Trim.IsEmpty then
    raise Exception.Create(
      'JWT Secret vazio.'
    );

  if ACfg.Issuer.Trim.IsEmpty then
    raise Exception.Create(
      'JWT Issuer vazio.'
    );

  if (AUserId <= 0) or
     (AIdEmpresa <= 0) then
    raise Exception.Create(
      'Usuário/empresa inválido para geração do token.'
    );

  LJWT := TJWT.Create;
  try
    LJWT.Claims.Issuer :=
      ACfg.Issuer;

    LJWT.Claims.Subject :=
      AUserId.ToString;

    LJWT.Claims.IssuedAt :=
      Now;

    LJWT.Claims.Expiration :=
      IncMinute(
        Now,
        TtlMinutos
      );

    LJWT.Claims.JSON.AddPair(
      'id_empresa',
      TJSONNumber.Create(
        AIdEmpresa
      )
    );

    if not Trim(AEleicaoSlug).IsEmpty then
    begin
      LJWT.Claims.JSON.AddPair(
        'eleicao_slug',
        UpperCase(
          Trim(AEleicaoSlug)
        )
      );
    end;

    Arr := TJSONArray.Create;

    for Role in ARoles do
    begin
      if not Trim(Role).IsEmpty then
      begin
        Arr.Add(
          UpperCase(
            Trim(Role)
          )
        );
      end;
    end;

    LJWT.Claims.JSON.AddPair(
      'roles',
      Arr
    );

    Result :=
      TJOSE.SHA256CompactToken(
        ACfg.Secret,
        LJWT
      );

  finally
    LJWT.Free;
  end;
end;

{ Token global da plataforma }

class function TAppJWT.GerarTokenGlobal(
  const ACfg: TAppJWTConfig;
  const AUserId: Int64;
  const ARoles: TArray<string>;
  const ATtlMinutos: Integer
): string;
var
  LJWT: TJWT;
  Arr: TJSONArray;
  Role: string;
  TtlMinutos: Integer;
begin
  TtlMinutos := ATtlMinutos;

  if TtlMinutos <= 0 then
    TtlMinutos := ACfg.TtlMinutos;

  if TtlMinutos <= 0 then
    TtlMinutos := 60;

  if ACfg.Secret.Trim.IsEmpty then
    raise Exception.Create(
      'JWT Secret vazio.'
    );

  if ACfg.Issuer.Trim.IsEmpty then
    raise Exception.Create(
      'JWT Issuer vazio.'
    );

  if AUserId <= 0 then
    raise Exception.Create(
      'Usuário inválido para geração do token.'
    );

  LJWT := TJWT.Create;
  try
    LJWT.Claims.Issuer :=
      ACfg.Issuer;

    LJWT.Claims.Subject :=
      AUserId.ToString;

    LJWT.Claims.IssuedAt :=
      Now;

    LJWT.Claims.Expiration :=
      IncMinute(
        Now,
        TtlMinutos
      );

    Arr := TJSONArray.Create;

    for Role in ARoles do
    begin
      if not Trim(Role).IsEmpty then
      begin
        Arr.Add(
          UpperCase(
            Trim(Role)
          )
        );
      end;
    end;

    LJWT.Claims.JSON.AddPair(
      'roles',
      Arr
    );

    Result :=
      TJOSE.SHA256CompactToken(
        ACfg.Secret,
        LJWT
      );

  finally
    LJWT.Free;
  end;
end;

{ Token da instituição }

class function TAppJWT.GerarTokenInstituicao(
  const ACfg: TAppJWTConfig;
  const AUserId, AIdInstituicao: Int64;
  const ARoles: TArray<string>;
  const AIdUsuarioInstituicao: Int64;
  const ATtlMinutos: Integer
): string;
var
  LJWT: TJWT;
  Arr: TJSONArray;
  Role: string;
  TtlMinutos: Integer;
begin
  TtlMinutos := ATtlMinutos;

  if TtlMinutos <= 0 then
    TtlMinutos := ACfg.TtlMinutos;

  if TtlMinutos <= 0 then
    TtlMinutos := 60;

  if ACfg.Secret.Trim.IsEmpty then
    raise Exception.Create(
      'JWT Secret vazio.'
    );

  if ACfg.Issuer.Trim.IsEmpty then
    raise Exception.Create(
      'JWT Issuer vazio.'
    );

  if (AUserId <= 0) or
     (AIdInstituicao <= 0) or
     (AIdUsuarioInstituicao <= 0) then
  begin
    raise Exception.Create(
      'Usuário/instituição/vínculo inválido para geração do token.'
    );
  end;

  LJWT := TJWT.Create;
  try
    LJWT.Claims.Issuer :=
      ACfg.Issuer;

    LJWT.Claims.Subject :=
      AUserId.ToString;

    LJWT.Claims.IssuedAt :=
      Now;

    LJWT.Claims.Expiration :=
      IncMinute(
        Now,
        TtlMinutos
      );

    // Tenant da plataforma Cursos.
    // Não reutilizar id_empresa.
    LJWT.Claims.JSON.AddPair(
      'id_instituicao',
      TJSONNumber.Create(
        AIdInstituicao
      )
    );

    // Vínculo do usuário com a instituição.
    LJWT.Claims.JSON.AddPair(
      'id_usuario_instituicao',
      TJSONNumber.Create(
        AIdUsuarioInstituicao
      )
    );

    Arr := TJSONArray.Create;

    for Role in ARoles do
    begin
      if not Trim(Role).IsEmpty then
      begin
        Arr.Add(
          UpperCase(
            Trim(Role)
          )
        );
      end;
    end;

    LJWT.Claims.JSON.AddPair(
      'roles',
      Arr
    );

    Result :=
      TJOSE.SHA256CompactToken(
        ACfg.Secret,
        LJWT
      );

  finally
    LJWT.Free;
  end;
end;

{ Validação }

class function TAppJWT.ValidarEExtrair(
  const ACfg: TAppJWTConfig;
  const AToken: string;
  out AClaims: TJWTClaims
): Boolean;
var
  LToken: TJWT;
  Obj: TJSONObject;
  RolesVal: TJSONValue;
  RolesArr: TJSONArray;
  Roles: TArray<string>;
  SubStr: string;
  I: Integer;
  EhSuperAdmin: Boolean;
begin
  Result := False;

  // Inicialização completa das claims.
  AClaims.UserId := 0;
  AClaims.IdEmpresa := 0;
  AClaims.IdInstituicao := 0;
  AClaims.IdUsuarioInstituicao := 0;

  AClaims.Issuer := '';
  AClaims.ExpUnix := 0;
  AClaims.IssuedAtUnix := 0;
  AClaims.EleicaoSlug := '';

  SetLength(
    AClaims.Roles,
    0
  );

  if AToken.Trim.IsEmpty then
    Exit(False);

  if ACfg.Secret.Trim.IsEmpty then
    Exit(False);

  LToken := nil;

  try
    try
      LToken :=
        TJOSE.DeserializeCompact(
          ACfg.Secret,
          AToken
        );

      if LToken = nil then
        Exit(False);

      Obj :=
        LToken.Claims.JSON as TJSONObject;

      if Obj = nil then
        Exit(False);

      { Issuer }

      AClaims.Issuer :=
        Obj.GetValue<string>(
          'iss',
          ''
        );

      if
        (not ACfg.Issuer.Trim.IsEmpty) and
        (not SameText(
          AClaims.Issuer,
          ACfg.Issuer
        ))
      then
        Exit(False);

      { Usuário }

      SubStr :=
        Obj.GetValue<string>(
          'sub',
          ''
        );

      if SubStr.Trim.IsEmpty then
        Exit(False);

      AClaims.UserId :=
        StrToInt64Def(
          SubStr,
          0
        );

      if AClaims.UserId <= 0 then
        Exit(False);

      { Contextos }

      AClaims.IdEmpresa :=
        Obj.GetValue<Int64>(
          'id_empresa',
          0
        );

      AClaims.IdInstituicao :=
        Obj.GetValue<Int64>(
          'id_instituicao',
          0
        );

      AClaims.IdUsuarioInstituicao :=
        Obj.GetValue<Int64>(
          'id_usuario_instituicao',
          0
        );

      AClaims.EleicaoSlug :=
        UpperCase(
          Trim(
            Obj.GetValue<string>(
              'eleicao_slug',
              ''
            )
          )
        );

      { Datas }

      AClaims.ExpUnix :=
        Obj.GetValue<Int64>(
          'exp',
          0
        );

      AClaims.IssuedAtUnix :=
        Obj.GetValue<Int64>(
          'iat',
          0
        );

      if AClaims.ExpUnix <= 0 then
        Exit(False);

      if AClaims.ExpUnix <
         DateTimeToUnix(Now) then
        Exit(False);

      { Roles }

      RolesVal :=
        Obj.GetValue('roles');

      if
        (RolesVal <> nil) and
        (RolesVal is TJSONArray)
      then
      begin
        RolesArr :=
          RolesVal as TJSONArray;

        SetLength(
          Roles,
          RolesArr.Count
        );

        for I := 0 to
          RolesArr.Count - 1 do
        begin
          Roles[I] :=
            UpperCase(
              Trim(
                RolesArr.Items[I].Value
              )
            );
        end;

        AClaims.Roles :=
          Roles;
      end
      else
      begin
        SetLength(
          AClaims.Roles,
          0
        );
      end;

      { Identifica SUPER_ADMIN }

      EhSuperAdmin := False;

      for I := 0 to
        High(AClaims.Roles) do
      begin
        if SameText(
          AClaims.Roles[I],
          'SUPER_ADMIN'
        ) then
        begin
          EhSuperAdmin := True;
          Break;
        end;
      end;

      {
        Contextos aceitos:

        1. Sistema legado:
           id_empresa > 0

        2. Plataforma Cursos:
           id_instituicao > 0

        3. Administrador global:
           role SUPER_ADMIN
      }

      if
        (AClaims.IdEmpresa <= 0) and
        (AClaims.IdInstituicao <= 0) and
        (not EhSuperAdmin)
      then
        Exit(False);

      Result := True;

    except
      // Token inválido, assinatura incorreta,
      // token malformado etc.
      Result := False;
    end;

  finally
    LToken.Free;
  end;
end;

end.
