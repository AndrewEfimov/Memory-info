unit Utils;

interface

uses
  System.Types, System.SysUtils, FMX.Types, FMX.Graphics, FMX.Objects, Androidapi.JNIBridge;

type
  TUtils = class
    class function BooleanToString(const Value: Boolean): string;
    class function FormatBytes(const Value: Int64): string;
    class function GetTextSize(AText: string; AHorzTextAlign: TTextAlign; AFont: TFont): TSizeF;
    class function IntArrayToJArray(const OrigArray: array of Integer): TJavaArray<Integer>;
  end;

implementation

{ TUtils }

class function TUtils.BooleanToString(const Value: Boolean): string;
const
  Values: array [Boolean] of string = ('False', 'True');
begin
  Result := Values[Value];
end;

class function TUtils.FormatBytes(const Value: Int64): string;
const
  KbyteInBytes = 1024;
  MbyteInBytes = KbyteInBytes * KbyteInBytes;
  GbyteInBytes = MbyteInBytes * KbyteInBytes;
begin
  Result := FormatFloat('0.0 รม', Value / GbyteInBytes);
  if Value < GbyteInBytes then
    Result := FormatFloat('0.0 ฬม', Value / MbyteInBytes);
  if Value < MbyteInBytes then
    Result := FormatFloat('0.0 สม', Value / KbyteInBytes);
  if Value < KbyteInBytes then
    Result := Format('%d ม', [Value]);
end;

class function TUtils.GetTextSize(AText: string; AHorzTextAlign: TTextAlign; AFont: TFont): TSizeF;
var
  TextObject: TText;
begin
  TextObject := TText.Create(nil);
  try
    TextObject.BeginUpdate;
    try
      with TextObject do
      begin
        Align := TAlignLayout.None;
        VertTextAlign := TTextAlign.Center;
        HorzTextAlign := AHorzTextAlign;
        Font := AFont;
        WordWrap := False;
        Trimming := TTextTrimming.None;
        Text := AText;
        AutoSize := True;
      end;
    finally
      TextObject.EndUpdate;
    end;
    Result.Width := TextObject.Width;
    Result.Height := TextObject.Height;
  finally
    FreeAndNil(TextObject);
  end;
end;

class function TUtils.IntArrayToJArray(const OrigArray: array of Integer): TJavaArray<Integer>;
var
  I: Integer;
begin
  Result := TJavaArray<Integer>.Create(Length(OrigArray));
  for I := Low(OrigArray) to High(OrigArray) do
    Result.Items[I] := OrigArray[I];
end;

end.
