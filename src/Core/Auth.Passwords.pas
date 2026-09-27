//unit Auth.Passwords;
//
//interface
//
//uses
//  System.SysUtils;
//
//function HashSenha(const ASenha: string): string;
//function VerifySenha(const ASenha, AHashArmazenado: string): Boolean;
//
//implementation
//
//uses
//  System.Hash,
//  System.NetEncoding,
//  System.Classes,
//  {$IFDEF MSWINDOWS}
//   Winapi.Windows;
//  {$ENDIF}
//
//const
//  ALGO_TAG   = 'pbkdf2$sha256';
//  ITERATIONS = 100000;
//  SALT_LEN   = 16;
//  DK_LEN     = 32;
//  BCRYPT_USE_SYSTEM_PREFERRED_RNG = $00000002;
//
//function BCryptGenRandom(hAlgorithm: Pointer; pbBuffer: PByte; cbBuffer: ULONG; dwFlags: ULONG): ULONG; stdcall;
//  external 'bcrypt.dll' name 'BCryptGenRandom';
//
//function CryptoRandomBytes(ALen: Integer): TBytes;
//var
//  Status: ULONG;
//begin
//  if ALen <= 0 then
//    Exit(nil);
//
//  SetLength(Result, ALen);
//
//  Status := BCryptGenRandom(nil, @Result[0], ALen, BCRYPT_USE_SYSTEM_PREFERRED_RNG);
//  if Status <> 0 then
//    raise Exception.CreateFmt('BCryptGenRandom falhou. Status=%d', [Status]);
//end;
//
//function SecureEquals(const A, B: TBytes): Boolean;
//var
//  i: Integer;
//  Diff: Byte;
//begin
//  if Length(A) <> Length(B) then
//    Exit(False);
//
//  Diff := 0;
//  for i := 0 to High(A) do
//    Diff := Diff or (A[i] xor B[i]);
//
//  Result := Diff = 0;
//end;
//
//function RandomSalt(ALen: Integer): TBytes;
//begin
//  Result := CryptoRandomBytes(ALen);
//end;
//
//function IntToBytesBE(Value: Cardinal): TBytes;
//begin
//  SetLength(Result, 4);
//  Result[0] := Byte((Value shr 24) and $FF);
//  Result[1] := Byte((Value shr 16) and $FF);
//  Result[2] := Byte((Value shr 8) and $FF);
//  Result[3] := Byte(Value and $FF);
//end;
//
//function PBKDF2_HMAC_SHA256(
//  const Password, Salt: TBytes;
//  Iterations, DKLen: Integer
//): TBytes;
//var
//  i, j, k, L, R, HLen: Integer;
//  U, T, SaltBlock, BlockIndex: TBytes;
//begin
//  HLen := 32;
//  L := (DKLen + HLen - 1) div HLen;
//  R := DKLen - (L - 1) * HLen;
//
//  SetLength(Result, DKLen);
//  SetLength(SaltBlock, Length(Salt) + 4);
//  Move(Salt[0], SaltBlock[0], Length(Salt));
//
//  k := 0;
//  for i := 1 to L do
//  begin
//    BlockIndex := IntToBytesBE(i);
//    Move(BlockIndex[0], SaltBlock[Length(Salt)], 4);
//
//    U := THashSHA2.GetHMACAsBytes(SaltBlock, Password, SHA256);
//    T := Copy(U, 0, Length(U));
//
//    for j := 2 to Iterations do
//    begin
//      U := THashSHA2.GetHMACAsBytes(U, Password, SHA256);
//      for var x := 0 to High(T) do
//        T[x] := T[x] xor U[x];
//    end;
//
//    if i = L then
//      Move(T[0], Result[k], R)
//    else
//    begin
//      Move(T[0], Result[k], HLen);
//      Inc(k, HLen);
//    end;
//  end;
//end;
//
//function HashSenha(const ASenha: string): string;
unit Auth.Passwords;

interface

uses
  System.SysUtils;

function HashSenha(const ASenha: string): string;
function VerifySenha(const ASenha, AHashArmazenado: string): Boolean;

implementation

uses
  System.Hash,
  System.NetEncoding,
  System.Classes
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  {$ELSE}
  , Posix.Fcntl
  , Posix.Unistd
  , Posix.SysTypes
  {$ENDIF}
  ;

const
  ALGO_TAG   = 'pbkdf2$sha256';
  ITERATIONS = 100000;
  SALT_LEN   = 16;
  DK_LEN     = 32;

{$IFDEF MSWINDOWS}
const
  BCRYPT_USE_SYSTEM_PREFERRED_RNG = $00000002;

function BCryptGenRandom(
  hAlgorithm: Pointer;
  pbBuffer: PByte;
  cbBuffer: ULONG;
  dwFlags: ULONG
): ULONG; stdcall;
  external 'bcrypt.dll' name 'BCryptGenRandom';
{$ENDIF}

function CryptoRandomBytes(ALen: Integer): TBytes;
{$IFDEF MSWINDOWS}
var
  Status: ULONG;
{$ELSE}
var
  FD: Integer;
  ReadBytes: Integer;
  TotalRead: Integer;
{$ENDIF}
begin
  if ALen <= 0 then
    Exit(nil);

  SetLength(Result, ALen);

  {$IFDEF MSWINDOWS}
  Status := BCryptGenRandom(nil, @Result[0], ALen, BCRYPT_USE_SYSTEM_PREFERRED_RNG);

  if Status <> 0 then
    raise Exception.CreateFmt('BCryptGenRandom falhou. Status=%d', [Status]);
  {$ELSE}
  FD := Posix.Fcntl.open('/dev/urandom', Posix.Fcntl.O_RDONLY);

  if FD < 0 then
    raise Exception.Create('Não foi possível abrir /dev/urandom.');

  try
    TotalRead := 0;

    while TotalRead < ALen do
    begin
      ReadBytes := Posix.Unistd.__read(
        FD,
        @Result[TotalRead],
        ALen - TotalRead
      );

      if ReadBytes <= 0 then
        raise Exception.Create('Falha ao ler bytes aleatórios de /dev/urandom.');

      Inc(TotalRead, ReadBytes);
    end;
  finally
    Posix.Unistd.__close(FD);
  end;
  {$ENDIF}
end;

function SecureEquals(const A, B: TBytes): Boolean;
var
  i: Integer;
  Diff: Byte;
begin
  if Length(A) <> Length(B) then
    Exit(False);

  Diff := 0;

  for i := 0 to High(A) do
    Diff := Diff or (A[i] xor B[i]);

  Result := Diff = 0;
end;

function RandomSalt(ALen: Integer): TBytes;
begin
  Result := CryptoRandomBytes(ALen);
end;

function IntToBytesBE(Value: Cardinal): TBytes;
begin
  SetLength(Result, 4);

  Result[0] := Byte((Value shr 24) and $FF);
  Result[1] := Byte((Value shr 16) and $FF);
  Result[2] := Byte((Value shr 8) and $FF);
  Result[3] := Byte(Value and $FF);
end;

function PBKDF2_HMAC_SHA256(
  const Password, Salt: TBytes;
  Iterations, DKLen: Integer
): TBytes;
var
  i, j, k, L, R, HLen: Integer;
  x: Integer;
  U, T, SaltBlock, BlockIndex: TBytes;
begin
  HLen := 32;
  L := (DKLen + HLen - 1) div HLen;
  R := DKLen - (L - 1) * HLen;

  SetLength(Result, DKLen);
  SetLength(SaltBlock, Length(Salt) + 4);

  if Length(Salt) > 0 then
    Move(Salt[0], SaltBlock[0], Length(Salt));

  k := 0;

  for i := 1 to L do
  begin
    BlockIndex := IntToBytesBE(i);
    Move(BlockIndex[0], SaltBlock[Length(Salt)], 4);

    U := THashSHA2.GetHMACAsBytes(
      SaltBlock,
      Password,
      THashSHA2.TSHA2Version.SHA256
    );

    T := Copy(U, 0, Length(U));

    for j := 2 to Iterations do
    begin
      U := THashSHA2.GetHMACAsBytes(
        U,
        Password,
        THashSHA2.TSHA2Version.SHA256
      );

      for x := 0 to High(T) do
        T[x] := T[x] xor U[x];
    end;

    if i = L then
      Move(T[0], Result[k], R)
    else
    begin
      Move(T[0], Result[k], HLen);
      Inc(k, HLen);
    end;
  end;
end;

function HashSenha(const ASenha: string): string;
var
  Salt, DK: TBytes;
begin
  if ASenha.Trim.IsEmpty then
    raise Exception.Create('Senha não informada.');

  Salt := RandomSalt(SALT_LEN);

  DK := PBKDF2_HMAC_SHA256(
    TEncoding.UTF8.GetBytes(ASenha),
    Salt,
    ITERATIONS,
    DK_LEN
  );

  Result := Format('%s$%d$%s$%s', [
    ALGO_TAG,
    ITERATIONS,
    TNetEncoding.Base64.EncodeBytesToString(Salt),
    TNetEncoding.Base64.EncodeBytesToString(DK)
  ]);
end;

function VerifySenha(const ASenha, AHashArmazenado: string): Boolean;
var
  Parts: TArray<string>;
  Iter: Integer;
  Salt, DKStored, DKTest: TBytes;
begin
  Result := False;
  Parts  := AHashArmazenado.Split(['$']);

  if Length(Parts) <> 5 then
    Exit;

  if (Parts[0] <> 'pbkdf2') or (Parts[1] <> 'sha256') then
    Exit;

  Iter := StrToIntDef(Parts[2], 0);

  if Iter <= 0 then
    Exit;

  Salt      := TNetEncoding.Base64.DecodeStringToBytes(Parts[3]);
  DKStored  := TNetEncoding.Base64.DecodeStringToBytes(Parts[4]);

  DKTest := PBKDF2_HMAC_SHA256(
    TEncoding.UTF8.GetBytes(ASenha),
    Salt,
    Iter,
    Length(DKStored)
  );

  Result := SecureEquals(DKStored, DKTest);
end;

end.



//var
//  Salt, DK: TBytes;
//begin
//  if ASenha.Trim.IsEmpty then
//    raise Exception.Create('Senha não informada.');
//
//  Salt := RandomSalt(SALT_LEN);
//  DK   := PBKDF2_HMAC_SHA256(
//            TEncoding.UTF8.GetBytes(ASenha),
//            Salt,
//            ITERATIONS,
//            DK_LEN
//          );
//
//  Result := Format('%s$%d$%s$%s', [
//    ALGO_TAG,
//    ITERATIONS,
//    TNetEncoding.Base64.EncodeBytesToString(Salt),
//    TNetEncoding.Base64.EncodeBytesToString(DK)
//  ]);
//end;
//
//function VerifySenha(const ASenha, AHashArmazenado: string): Boolean;
//var
//  Parts: TArray<string>;
//  Iter: Integer;
//  Salt, DKStored, DKTest: TBytes;
//begin
//  Result := False;
//
//  Parts := AHashArmazenado.Split(['$']);
//  if Length(Parts) <> 5 then Exit;
//
//  if (Parts[0] <> 'pbkdf2') or (Parts[1] <> 'sha256') then Exit;
//
//  Iter := StrToIntDef(Parts[2], 0);
//  if Iter <= 0 then Exit;
//
//  Salt     := TNetEncoding.Base64.DecodeStringToBytes(Parts[3]);
//  DKStored := TNetEncoding.Base64.DecodeStringToBytes(Parts[4]);
//
//  DKTest := PBKDF2_HMAC_SHA256(
//              TEncoding.UTF8.GetBytes(ASenha),
//              Salt,
//              Iter,
//              Length(DKStored)
//            );
//
//  Result := SecureEquals(DKStored, DKTest);
//end;
//
//end.

