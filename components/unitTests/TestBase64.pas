unit TestBase64;

interface
uses
  TestFrameWork,
  Base64;

type
  TTestCaseBase64 = class(TTestCase)
  private

  protected
   procedure SetUp; override;
   procedure TearDown; override;

  public

  published
    procedure TestEncodeBase64;
    procedure TestDecodeBase64;
  end;

implementation
uses
  SysUtils;

const
  Base64Text1: string = 'FPucA9l+';
  Base64Binary1: string = #$14#$fb#$9c#$03#$d9#$7e;
  Base64Text2: string = 'FPucA9k=';
  Base64Binary2: string = #$14#$fb#$9c#$03#$d9;
  Base64Text3: string = 'FPucAw==';
  Base64Binary3: string = #$14#$fb#$9c#$03;

{ TTestCaseBase64 }

function tohex(s: string): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to Length(s) - 1 do
  begin
    result := result + IntToHex(Ord(s[i]), 2);
  end;
end;

procedure TTestCaseBase64.SetUp;
begin
  inherited;

end;

procedure TTestCaseBase64.TearDown;
begin
  inherited;

end;

procedure TTestCaseBase64.TestDecodeBase64;
begin
  CheckEquals( tohex(Base64Binary1), tohex(DecodeBase64(Base64Text1)), 'test1' );
  CheckEquals( tohex(Base64Binary2), tohex(DecodeBase64(Base64Text2)), 'test2' );
  CheckEquals( tohex(Base64Binary3), tohex(DecodeBase64(Base64Text3)), 'test3' );
end;

procedure TTestCaseBase64.TestEncodeBase64;
begin
  CheckEquals( Base64Text1, EncodeBase64(Base64Binary1) );
  CheckEquals( Base64Text2, EncodeBase64(Base64Binary2) );
  CheckEquals( Base64Text3, EncodeBase64(Base64Binary3) );
end;

initialization
  TestFramework.RegisterTest(TTestCaseBase64.Suite);
end.
