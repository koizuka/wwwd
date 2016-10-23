unit TestCharSetDetector;

interface
uses
  TestFrameWork,
  CharSetDetector;

type
  TTestCaseCharSetDetector = class(TTestCase)
  private
    FDetector: TCharSetDetector;

    function LoadStringFromFile( filename: string ): string;
    function GetSjisTime( const testname: string ): string;

  protected
   procedure CheckEquals(expected, actual: TCharSet; msg: string = ''); overload; virtual;
   procedure SetUp; override;
   procedure TearDown; override;

  public

  published
    procedure TestCharSet;
    procedure TestAscii;
    procedure TestUnknown;
    procedure TestUnknown2;
    procedure TestSjis;
    procedure TestSjis2;
    procedure TestSjisSpeed;
    procedure TestEuc;
    procedure TestEuc2;
    procedure TestEucByte;
    procedure TestEucSpeed;
    procedure TestJis;
    procedure TestJis2;
    procedure TestJisByte;
    procedure TestJisSpeed;
    procedure TestUtf8;
    procedure TestUtf82;
    procedure TestUtf8Byte;
    procedure TestUtf8Speed;
    procedure TestRewind;
  end;


implementation
uses
  SysUtils,
  Windows,
  Classes;

const
  DataPath = 'CharSetDetector\';
  JisDataFileName = DataPath + 'jis.txt';
  EucDataFileName = DataPath + 'euc.txt';
  Utf8DataFileName = DataPath + 'utf8.txt';

  JisSpeedDataFileName = DataPath + 'agentgripes_jis.html';
  SJisSpeedDataFileName = DataPath + 'agentgripes_sjis.html';
  EucSpeedDataFileName = DataPath + 'agentgripes_euc.html';
  Utf8SpeedDataFileName = DataPath + 'agentgripes_utf8.html';

  AsciiTestText = 'This is ASCII text.'#10;
  ShiftJisTestText = 'シフトJISの漢字';
  JISTestText = 'じす漢字です。JISともいう。ﾊﾝｶｸｶﾅもね(o^-'')b'#10;
  EUCTestText = 'ＥＵＣなのです。漢字が必要でしょうか。'#10;
  UTF8TestText = 'これはUTF-8のテストなのじゃ';

{ TTestCaseCharSetDetector }

procedure TTestCaseCharSetDetector.CheckEquals(expected, actual: TCharSet;
  msg: string);
begin
  if (expected <> actual) then
    FailNotEquals(TCharSetDetector.GetCharSetName(expected), TCharSetDetector.GetCharSetName(actual), msg, CallerAddr);
end;

function TTestCaseCharSetDetector.GetSjisTime(
  const testname: string): string;
var
  starttime, endtime: Int64;
begin
  QueryPerformanceCounter(starttime);
  result := FDetector.GetSjis;
  QueryPerformanceCounter(endtime);
  OutputDebugString( pchar( ClassName + '.' + testname + ' ' + IntToStr(endtime - starttime)));
end;

function TTestCaseCharSetDetector.LoadStringFromFile(filename: string): string;
var
  fs: TFileStream;
begin
  fs := TFileStream.Create( filename, fmOpenRead );
  try
    SetLength( result, fs.Size );
    fs.Read( result[1], fs.Size );
  finally
    fs.Free;
  end;
end;

procedure TTestCaseCharSetDetector.SetUp;
begin
  FDetector := TCharSetDetector.Create;
end;

procedure TTestCaseCharSetDetector.TearDown;
begin
  FDetector.Free;
end;

procedure TTestCaseCharSetDetector.TestAscii;
begin
  FDetector.Append(AsciiTestText);
  CheckEquals( csASCII, FDetector.CharSet, 'CharSet');
  CheckEquals( AsciiTestText, FDetector.GetSjis, 'GetSjis');
  CheckEquals( '', FDetector.GetSjis, 'GetSjis 2');
end;

procedure TTestCaseCharSetDetector.TestCharSet;
const
  InvalidText = #$80#27;
begin
  FDetector.Append( InvalidText );
  CheckEquals( csUnknown, FDetector.CharSet, 'CharSet' );

  FDetector.Rewind;
  CheckEquals( csUnknown, FDetector.CharSet, 'CharSet after Rewind' );

  FDetector.Clear;
  CheckEquals( csUnknown, FDetector.CharSet, 'CharSet after Clear' );
end;

procedure TTestCaseCharSetDetector.TestEuc;
begin
  FDetector.Append( LoadStringFromFile(EucDataFileName) );
  CheckEquals( csUnknown, FDetector.CharSet, 'CharSet' );
  CheckEquals( csEUC, FDetector.GetProbableCharSet, 'GetProbableCharSet' );

  FDetector.CharSet := csEUC;

  CheckEquals( AdjustLineBreaks(EUCTestText), FDetector.GetSjis, 'GetSjis' );
  CheckEquals( '', FDetector.GetSjis, 'GetSjis 2');
end;

procedure TTestCaseCharSetDetector.TestEuc2;
var
  eucfile: string;
begin
  eucfile := LoadStringFromFile(EucDataFileName);
  FDetector.CharSet := csEUC;

  FDetector.Append( eucfile[1] );
  CheckEquals( '', FDetector.GetSjis, 'first byte empty' );
  FDetector.Append( eucfile[2] );
  CheckEquals( Copy(EUCTestText, 1, 2), FDetector.GetSjis, 'second byte' );
end;

procedure TTestCaseCharSetDetector.TestEucByte;
var
  eucfile: string;
  i: integer;
begin
  eucfile := LoadStringFromFile(EucDataFileName);
  FDetector.CharSet := csEUC;

  for i := 1 to Length(eucfile) do
    FDetector.Append( eucfile[i] );

  CheckEquals( AdjustLineBreaks(EUCTestText), FDetector.GetSjis, 'GetSjis' );
end;

procedure TTestCaseCharSetDetector.TestEucSpeed;
var
  sjis: string;
  sjisfile: string;
  i: integer;
begin
  FDetector.Append( LoadStringFromFile(EucSpeedDataFileName) );
  CheckEquals( csEuc, FDetector.CharSet, 'CharSet' );

  sjis := GetSjisTime('TestEucSpeed');

  sjisfile := LoadStringFromFile(SJisSpeedDataFileName);
  CheckEquals( Length(sjisfile), Length(sjis), 'compare length failure' );
  if sjisfile <> sjis then
  begin
    for i := 1 to Length(sjisfile) do
    begin
      CheckEquals( Ord(sjisfile[i]), Ord(sjis[i]), 'compare['+IntToStr(i)+'] failure' );
    end;
  end;
end;

procedure TTestCaseCharSetDetector.TestJis;
begin
  FDetector.Append( LoadStringFromFile(JisDataFileName) );
  CheckEquals( csJIS, FDetector.CharSet, 'CharSet' );

  CheckEquals( AdjustLineBreaks(JISTestText), FDetector.GetSjis, 'GetSjis' );
  CheckEquals( '', FDetector.GetSjis, 'GetSjis 2');
end;

procedure TTestCaseCharSetDetector.TestJis2;
var
  jisfile: string;
  i: integer;
begin
  jisfile := LoadStringFromFile(JisDataFileName);
  FDetector.CharSet := csJIS;

  for i := 1 to 4 do
  begin
    FDetector.Append( jisfile[i] );
    CheckEquals( '', FDetector.GetSjis, IntToStr(i) + ' byte empty test' );
  end;
  CheckEquals( Copy(jisfile, 4, 1), FDetector.GetNextBuffer, 'GetNextBuffer' );

  FDetector.Append( jisfile[5] );
  CheckEquals( Copy(JISTestText, 1, 2), FDetector.GetSjis, '5th byte test' );
end;

procedure TTestCaseCharSetDetector.TestJisByte;
var
  jisfile: string;
  i: integer;
begin
  jisfile := LoadStringFromFile(JisDataFileName);
  FDetector.CharSet := csJIS;

  for i := 1 to Length(jisfile) do
    FDetector.Append( jisfile[i] );

  CheckEquals( AdjustLineBreaks(JISTestText), FDetector.GetSjis, 'GetSjis' );
end;

procedure TTestCaseCharSetDetector.TestJisSpeed;
var
  jisfile: string;
  sjis: string;
  sjisfile: string;
begin
  jisfile := LoadStringFromFile(JisSpeedDataFileName);
  FDetector.Append( jisfile );
  CheckEquals( csJIS, FDetector.CharSet, 'CharSet' );

  sjis := GetSjisTime('TestJisSpeed');

  sjisfile := LoadStringFromFile(SJisSpeedDataFileName);
  CheckEquals( Length(sjisfile), Length(sjis), 'compare length failure' );
  Check( sjisfile = sjis, 'GetSjis' );
end;

procedure TTestCaseCharSetDetector.TestRewind;
var
  jisfile: string;
  sjisfile: string;
begin
  jisfile := LoadStringFromFile(JisDataFileName);
  sjisfile := AdjustLineBreaks(JISTestText);
  FDetector.Append( jisfile );
  CheckEquals( csJIS, FDetector.CharSet, 'CharSet' );

  CheckEquals( sjisfile, FDetector.GetSjis, 'GetSjis' );
  FDetector.Rewind;
  CheckEquals( sjisfile, FDetector.GetSjis, 'GetSjis 2' );

  FDetector.Append( jisfile );
  CheckEquals( sjisfile, FDetector.GetSjis, 'GetSjis 3' );
  FDetector.Rewind;
  CheckEquals( (sjisfile+sjisfile), FDetector.GetSjis, 'GetSjis 4' );
end;

procedure TTestCaseCharSetDetector.TestSjis;
begin
  FDetector.Append(ShiftJisTestText);
  CheckEquals( csShiftJis, FDetector.CharSet, 'Shift JIS Detection Failure');
  CheckEquals(ShiftJisTestText, FDetector.GetSjis, 'GetSjis');
  CheckEquals( '', FDetector.GetSjis, 'GetSjis 2');
end;

procedure TTestCaseCharSetDetector.TestSjis2;
var
  s: string;
  r: string;
begin
  s := ShiftJisTestText;

  FDetector.CharSet := csShiftJIS;

  FDetector.Append( s[1] );
  r := FDetector.GetSjis;
  CheckEquals( '', r, 'first byte empty test' );
  CheckEquals( s[1], FDetector.GetNextBuffer, 'GetNextBuffer' );
  FDetector.Append( s[2] );
  r := FDetector.GetSjis;
  CheckEquals( Copy(s, 1, 2), r, 'second byte test' );
end;

procedure TTestCaseCharSetDetector.TestSjisSpeed;
var
  sjis: string;
begin
  FDetector.Append( LoadStringFromFile(SJisSpeedDataFileName) );
  CheckEquals( csShiftJIS, FDetector.CharSet, 'CharSet' );

  sjis := GetSjisTime('TestSjisSpeed');

  Check( LoadStringFromFile(SJisSpeedDataFileName) = sjis, 'GetSjis' );
end;

procedure TTestCaseCharSetDetector.TestUnknown;
var
  eucfile: string;
begin
  eucfile := LoadStringFromFile(EucDataFileName);
  FDetector.Append( eucfile );
  CheckEquals( csUnknown, FDetector.CharSet, 'CharSet' );
  CheckEquals( '', FDetector.GetSjis, 'GetSjis');
  CheckEquals( eucfile, FDetector.GetNextBuffer, 'GetNextBuffer');
end;

procedure TTestCaseCharSetDetector.TestUnknown2;
begin
  FDetector.CharSet := csUnknown;
  FDetector.Append(AsciiTestText);
  CheckEquals( csUnknown, FDetector.CharSet, 'CharSet' );
  CheckEquals( '', FDetector.GetSjis, 'GetSjis');

  FDetector.CharSet := csAscii;
  CheckEquals( csAscii, FDetector.CharSet, 'CharSet' );
  CheckEquals( AsciiTestText, FDetector.GetSjis, 'GetSjis');
end;

procedure TTestCaseCharSetDetector.TestUtf8;
begin
  FDetector.Append( LoadStringFromFile(Utf8DataFileName) );
  CheckEquals( csUnknown, FDetector.CharSet, 'Detection1' );
  CheckEquals( csUTF8, FDetector.GetProbableCharSet, 'Detection2' );

  FDetector.CharSet := csUTF8;

  CheckEquals( UTF8TestText, FDetector.GetSjis, 'GetSjis' );
  CheckEquals( '', FDetector.GetSjis, 'GetSjis 2');
end;

procedure TTestCaseCharSetDetector.TestUtf82;
var
  utf8file: string;
  i: integer;
begin
  utf8file := LoadStringFromFile( Utf8DataFileName );
  FDetector.CharSet := csUTF8;

  // first three bytes: BOF
  // next three bytes: first japanese character

  for i := 1 to 5 do
  begin
    FDetector.Append( utf8file[i] );
    CheckEquals( '', FDetector.GetSjis, IntToStr(i) + ' byte empty test' );
  end;
  CheckEquals( Copy(utf8file, 4, 2), FDetector.GetNextBuffer, 'GetNextBuffer' );

  FDetector.Append( utf8file[6] );
  CheckEquals( Copy(UTF8TestText, 1, 2), FDetector.GetSjis, 'first character test' );
end;

procedure TTestCaseCharSetDetector.TestUtf8Byte;
var
  utf8file: string;
  i: integer;
begin
  utf8file := LoadStringFromFile(Utf8DataFileName);
  FDetector.CharSet := csUTF8;

  for i := 1 to Length(utf8file) do
    FDetector.Append( utf8file[i] );

  CheckEquals( UTF8TestText, FDetector.GetSjis, 'GetSjis' );
end;

procedure TTestCaseCharSetDetector.TestUtf8Speed;
var
  sjis: string;
begin
  FDetector.Append( LoadStringFromFile(Utf8SpeedDataFileName) );
  CheckEquals( csUtf8, FDetector.CharSet, 'CharSet' );

  sjis := GetSjisTime('TestUtf8Speed');

  Check( LoadStringFromFile(SjisSpeedDataFileName) = sjis, 'GetSjis' );
end;

initialization
  TestFramework.RegisterTest(TTestCaseCharSetDetector.Suite);
end.
