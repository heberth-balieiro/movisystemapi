unit EleicaoComprovantePDF.Service;

interface

uses
  System.SysUtils;

type
  TEleicaoComprovantePDFService = class
  private
    class function NormalizarASCII(const AValor: string): string; static;
    class function EscapePDF(const AValor: string): string; static;
  public
    class function GerarBase64(
      const AEleicao: string;
      const ANomeEleitor: string;
      const AComprovante: string;
      const ADataHora: TDateTime
    ): string; static;
  end;

implementation

uses
  System.NetEncoding,
  System.Classes;

class function TEleicaoComprovantePDFService.NormalizarASCII(
  const AValor: string): string;
begin
  Result := AValor;

  Result := StringReplace(Result, 'á', 'a', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'à', 'a', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ã', 'a', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'â', 'a', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ä', 'a', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'é', 'e', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ê', 'e', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ë', 'e', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'í', 'i', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ï', 'i', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ó', 'o', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ô', 'o', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'õ', 'o', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ö', 'o', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ú', 'u', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ü', 'u', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ç', 'c', [rfReplaceAll, rfIgnoreCase]);
end;

class function TEleicaoComprovantePDFService.EscapePDF(
  const AValor: string): string;
begin
  Result := NormalizarASCII(AValor);
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '(', '\(', [rfReplaceAll]);
  Result := StringReplace(Result, ')', '\)', [rfReplaceAll]);
end;

class function TEleicaoComprovantePDFService.GerarBase64(
  const AEleicao: string;
  const ANomeEleitor: string;
  const AComprovante: string;
  const ADataHora: TDateTime): string;
var
  PDF: string;
  Conteudo: string;
  Offsets: array[1..6] of Integer;
  XRefOffset: Integer;
  I: Integer;
  Codigo1: string;
  Codigo2: string;

  procedure AddObject(const ANumero: Integer; const AConteudo: string);
  begin
    Offsets[ANumero] := Length(PDF);
    PDF := PDF + IntToStr(ANumero) + ' 0 obj'#13#10 +
      AConteudo + #13#10'endobj'#13#10;
  end;

begin
  Codigo1 := Copy(Trim(AComprovante), 1, 32);
  Codigo2 := Copy(Trim(AComprovante), 33, MaxInt);

  Conteudo :=
    'q 0.965 g 0 0 540 350 re f Q'#13#10 +
    'q 0.88 g 18 188 504 1 re f Q'#13#10 +
    'q 0.92 g 18 48 504 112 re f Q'#13#10 +
    'BT /F2 12 Tf 26 316 Td (COMPROVANTE DE VOTACAO) Tj ET'#13#10 +
    'BT /F1 10 Tf 26 298 Td (SISTEMA DE VOTACAO DIGITAL) Tj ET'#13#10 +
    'BT /F2 10 Tf 26 268 Td (ELEICAO:) Tj ET'#13#10 +
    'BT /F1 10 Tf 90 268 Td (' + EscapePDF(UpperCase(AEleicao)) + ') Tj ET'#13#10 +
    'BT /F2 10 Tf 26 248 Td (DATA:) Tj ET'#13#10 +
    'BT /F1 10 Tf 65 248 Td (' + EscapePDF(FormatDateTime('dd/mm/yyyy hh:nn', ADataHora)) + ') Tj ET'#13#10 +
    'BT /F2 18 Tf 26 208 Td (' + EscapePDF(UpperCase(ANomeEleitor)) + ') Tj ET'#13#10 +
    'BT /F2 9 Tf 32 137 Td (CODIGO DO COMPROVANTE) Tj ET'#13#10 +
    'BT /F1 11 Tf 32 111 Td (' + EscapePDF(Codigo1) + ') Tj ET'#13#10 +
    'BT /F1 11 Tf 32 91 Td (' + EscapePDF(Codigo2) + ') Tj ET'#13#10 +
    'BT /F1 8 Tf 26 26 Td (Este comprovante confirma apenas o registro da participacao e nao revela a opcao escolhida.) Tj ET'#13#10 +
    'BT /F2 8 Tf 389 26 Td (MoviSystem) Tj ET';

  PDF := '%PDF-1.4'#13#10'%MoviSystem'#13#10;

  AddObject(1, '<< /Type /Catalog /Pages 2 0 R >>');
  AddObject(2, '<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
  AddObject(3,
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 540 350] ' +
    '/Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> ' +
    '/Contents 6 0 R >>');
  AddObject(4, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
  AddObject(5, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>');
  AddObject(6,
    '<< /Length ' + IntToStr(Length(Conteudo)) + ' >>'#13#10 +
    'stream'#13#10 + Conteudo + #13#10'endstream');

  XRefOffset := Length(PDF);
  PDF := PDF + 'xref'#13#10'0 7'#13#10 +
    '0000000000 65535 f '#13#10;

  for I := 1 to 6 do
    PDF := PDF + Format('%.10d 00000 n ', [Offsets[I]]) + #13#10;

  PDF := PDF +
    'trailer'#13#10 +
    '<< /Size 7 /Root 1 0 R >>'#13#10 +
    'startxref'#13#10 +
    IntToStr(XRefOffset) + #13#10 +
    '%%EOF';

  Result := TNetEncoding.Base64.EncodeBytesToString(
    TEncoding.ASCII.GetBytes(PDF)
  );
end;

end.
