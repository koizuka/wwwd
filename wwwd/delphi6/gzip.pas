unit gzip;
(*
 simple gzip compess/decompress procedures for Delphi

 see: RFC1952 GZIP file format specification version 4.3
 license: LGPL

 written by Akihiko Koizuka <koizuka@ss.iij4u.or.jp>
*)

interface
uses
  zlib,
  SysUtils,
  Classes;

const
  XFL_Deflate_Maximum = 2;
  XFL_Deflate_Fastest = 4;

  OS_FAT = 0;
  OS_AMIGA = 1;
  OS_VMS = 2;
  OS_UNIX = 3;
  OS_VM_CMS = 4;
  OS_ATARI_TOS = 5;
  OS_HPFS = 6;
  OS_MACINTOSH = 7;
  OS_Z_SYSTEM = 8;
  OS_CP_M = 9;
  OS_TOPS_20 = 10;
  OS_NTFS = 11;
  OS_QDOS = 12;
  OS_ACORN_RISCOS = 13;
  OS_UNKNOWN = 255;

type
  TCompressionMethod = (cmUnknown, cmDeflate);

  EGzipError = class (Exception);
  EGzipInvalidFileError = class (EGzipError);
  EGzipUnknownMethodError = class (EGzipError);
  EGzipCorruptDataError = class (EGzipError);

  TGZipRecord = record
    isText: boolean;
    method: TCompressionMethod;
    xfl: integer;
    os: integer;
    extra: string;
    fname: string;
    comment: string;
    mtime: TDateTime;
    rawdata: TStream;
  end;

  (* TGzipDecompressStream class

   raises in Write:
     EGzipInvalidFileError
     EGzipUnknownMethodError
     EGzipCorruptDataError

   raises in Seek:
     EStreamError
  *)
  TGzipDecompressState = (gzdsHead1, gzdsExtra, gzdsFileName, gzdsComment, gzdsHCRC, gzdsBody, gzdsTail, gzdsEOF);
  TGzipDecompressStream = class(TStream)
  private
    FState: TGzipDecompressState;

    FReadbuf: string;
    FCount: integer;

    FHeader: TGZipRecord;
    FFlags: integer;

    FBodyBuf: TStringStream;
    FDeflate: TDecompressionStream;

    FCrc: LongInt;
    FExpandedLength: LongInt;
  public
    constructor Create( dest: TStream );
    function Write(const Buffer; Count: Longint): Longint; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    destructor Destroy; override;
    property Header: TGZipRecord read FHeader;
  end;

  (* gunzip
   引数に渡すdestのrawdataに書き込み先streamを書いてから呼ぶこと。
   それがnilならばどこにも書き込まない。

   Make sure rawdata are filled before decompress!
   When rawdata is Nil, decompressed data will not be written.

   raises:
     EGzipInvalidFileError
     EGzipUnknownMethodError
     EGzipCorruptDataError
  *)
  procedure gzDecompress( in_stream: TStream; var dest:TGzipRecord );

  (* gzip
   src.rawdataは圧縮したいデータの先頭を指していること。
   Make sure src.rawdata sought at beginning of the data to be compressed beforehand.

   raises:
    EGzipUnknownMethodError
    EGzipCorruptDataError
  *)
  procedure gzCompress( const src:TGzipRecord; out_stream: TStream );

implementation
uses
  crc;

const
  ID1 = #$1f;
  ID2 = #$8b;
  CM_Deflate = #8;

  Flag_Text = 1;
  Flag_HeaderCRC = 2;
  Flag_ExtraData = 4;
  Flag_FileName = 8;
  Flag_Comment = 16;

{TGzipDecompressStream}

constructor TGzipDecompressStream.Create( dest: TStream );
begin
  inherited Create;

  FState := gzdsHead1;
  FReadbuf := '';
  FFlags := 0;

  FBodyBuf := nil;
  FDeflate := nil;

  FCrc := 0;
  FExpandedLength := 0;

  FCount := 0;

  with FHeader do
  begin
    isText := false;
    mtime := 0.;
    extra := '';
    fname := '';
    comment := '';
    rawdata := dest;
  end;
end;

destructor TGzipDecompressStream.Destroy;
begin
  FDeflate.Free;
  FBodyBuf.Free;
  inherited;
end;

(*
 resultは変則的。
 足りないデータがあって次回繰越になった場合、resultは少ないが
 次に処理できたときには引数のCountより大きな値が返ることがある。
 また、すべて処理が済んだ場合は処理しなかった分は引いて返す。
*)
function TGzipDecompressStream.Write(const Buffer; Count: Longint): Longint;
var
  retry: boolean;

  procedure NextState;
  begin
    retry := true;
    FState := Succ(FState);
  end;

const
  blocksize = 4096;
var
  len: LongInt;
  blockbuf: array[0..blocksize-1] of char;
  lastpos: LongInt;
begin
  len := Length(FReadbuf);
  SetLength(FReadbuf, len + Count);
  Move(Buffer, (@FReadbuf[len+1])^, Count);

  result := 0;

  repeat
    retry := false;

    case FState of
    gzdsHead1:
      if Length(FReadbuf) >= 2 then
      begin
        if (FReadbuf[1] <> ID1) or (FReadbuf[2] <> ID2) then
          raise EGzipInvalidFileError.Create('This is not gzip!');

        if Length(FReadbuf) >= 10 then
        begin
          with FHeader do
          begin
            // CM: compression method
            if FReadbuf[3] <> CM_Deflate then
              raise EGzipUnknownMethodError.Create('Unknown Compression Method!');
            method := cmDeflate;

            // FLG
            FFlags := Ord(FReadbuf[4]);
            isText := (FFlags and Flag_Text) <> 0;

            // MTIME
            mtime := Ord(FReadbuf[5]) + (Ord(FReadbuf[6]) shl 8) + (Ord(FReadbuf[7]) shl 16) + (Ord(FReadbuf[8]) shl 24);
            mtime := EncodeDate(1970,1,1) + mtime / (24.*60*60);

            // XFL
            xfl := Ord(FReadbuf[9]);

            // OS
            os := Ord(FReadbuf[10]);
          end;

          Delete(FReadbuf, 1, 10);
          Inc(result, 10);
          NextState;
        end;
      end;

    gzdsExtra:
      if (FFlags and Flag_ExtraData) <> 0 then
      begin
        if Length(FReadbuf) >= 2 then
        begin
          len := Ord(FReadbuf[1]) + (Ord(FReadbuf[2]) shl 8);
          if Length(FReadbuf) >= 2+len then
          begin
            FHeader.extra := Copy( FReadbuf, 3, len );
            Delete(FReadbuf, 1, 2+len);
            Inc(result, 2+len);
            NextState;
          end;
        end;
      end else
        NextState;

    gzdsFileName:
      if (FFlags and Flag_FileName) <> 0 then
      begin
        if FReadbuf <> '' then
        begin
          len := Pos( #0, FReadbuf );
          if len = 0 then
          begin
            FHeader.fname := FHeader.fname + FReadbuf;
            Inc(result, Length(FReadBuf));
            FReadbuf := '';
          end else
          begin
            FHeader.fname := FHeader.fname + Copy( FReadbuf, 1, len - 1 );
            Delete(FReadbuf, 1, len);
            Inc(result, len);
            NextState;
          end;
        end;
      end else
        NextState;

    gzdsComment:
      if (FFlags and Flag_Comment) <> 0 then
      begin
        if FReadbuf <> '' then
        begin
          len := Pos( #0, FReadbuf );
          if len = 0 then
          begin
            FHeader.comment := FHeader.comment + FReadbuf;
            Inc(result, Length(FReadBuf));
            FReadbuf := '';
          end else
          begin
            FHeader.comment := FHeader.comment + Copy( FReadbuf, 1, len - 1 );
            Delete(FReadbuf, 1, len);
            Inc(result, len);
            NextState;
          end;
        end;
      end else
        NextState;

    gzdsHCRC:
      if (FFlags and Flag_Comment) <> 0 then
      begin
        if Length(FReadbuf) >= 2 then
        begin
          // simply ignore
          Delete(FReadbuf, 1, 2);
          Inc(result, 2);
          NextState;
        end;
      end else
        NextState;

    gzdsBody:
      if FReadbuf <> '' then
      begin
        if FBodyBuf = nil then
          FBodyBuf := TStringStream.Create('');
        if FDeflate = nil then
          FDeflate := TDecompressionStream.CreateNoHeader(FBodyBuf);

        (* seek positionはそのままに末尾にデータ追加 *)
        lastpos := FBodyBuf.Position;
        FBodyBuf.Seek(0, soFromEnd);
        FBodyBuf.WriteString(FReadbuf);
        FBodyBuf.Seek(lastpos, soFromBeginning);
        Inc(result, Length(FReadbuf)); // まずは処理したことに /
        FReadbuf := '';

        repeat
          len := FDeflate.Read(blockbuf, blocksize);
          FCrc := crc32_block(FCrc, pchar(@blockbuf[0]), len);
          if FHeader.rawdata <> nil then
            FHeader.rawdata.Write(blockbuf, len);
          Inc(FExpandedLength, len);
        until len < blocksize;

        if FDeflate.EOF then
        begin
          FDeflate.Free;
          FDeflate := nil;

          // 取りすぎた分を戻す /
          Dec(result, (FBodyBuf.Size - FBodyBuf.Position) );
          FReadBuf := FBodyBuf.ReadString(FBodyBuf.Size - FBodyBuf.Position);
          FBodyBuf.Free;
          FBodyBuf := nil;

          NextState;
        end;
      end;

    gzdsTail:
      if Length(FReadbuf) >= 8 then
      begin
        len := Ord(FReadbuf[1]) + (Ord(FReadbuf[2]) shl 8) + (Ord(FReadbuf[3]) shl 16) + (Ord(FReadbuf[4]) shl 24);
        if len <> FCrc then
          raise EGzipCorruptDataError.Create('Invalid CRC');

        len := Ord(FReadbuf[5]) + (Ord(FReadbuf[6]) shl 8) + (Ord(FReadbuf[7]) shl 16) + (Ord(FReadbuf[8]) shl 24);
        if len <> FExpandedLength then
          raise EGzipCorruptDataError.Create('Invalid Length');

        Delete(FReadBuf, 1, 8);
        Inc(result, 8);

        NextState;
      end;

    gzdsEOF:
      ; // nothing to do /
    end;
  until not retry;
  Inc(FCount, result);
end;

function TGzipDecompressStream.Read(var Buffer; Count: Longint): Longint;
begin
  result := 0;
end;

function TGzipDecompressStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  result := FCount;

  case Origin of
  soFromBeginning:
    if Offset = FCount then
      Exit;
  soFromCurrent:
    if Offset = 0 then
      Exit;
  soFromEnd:
    if Offset = 0 then
      Exit;
  end;

  raise EStreamError.Create('TGzipDecompressStream can''t change seek position');
end;


procedure gzDecompress( in_stream: TStream; var dest:TGzipRecord );
const
  blocksize = 4096;
var
  h: array[0..9] of char;
  flags: cardinal;
  mtime: LongInt;
  len: cardinal;
  decomp: TDecompressionStream;
  buf: array[0..blocksize-1] of char;
  crcval: Cardinal;
  total_len: Cardinal;
begin
  dest.isText := false;
  dest.mtime := 0.;
  dest.extra := '';
  dest.fname := '';
  dest.comment := '';

  in_stream.Read(h, 10);
  if (h[0] <> ID1) or (h[1] <> ID2) then
    raise EGzipInvalidFileError.Create('This is not gzip!');

  // CM: compression method
  if h[2] <> CM_Deflate then
    raise EGzipUnknownMethodError.Create('Unknown Compression Method!');
  dest.method := cmDeflate;

  // FLG
  flags := Ord(h[3]);
  dest.isText := (flags and Flag_Text) <> 0;

  // MTIME
  mtime := Ord(h[4]) + (Ord(h[5]) shl 8) + (Ord(h[6]) shl 16) + (Ord(h[7]) shl 24);
  dest.mtime := EncodeDate(1970,1,1) + mtime / (24.*60*60);

  // XFL
  dest.xfl := Ord(h[8]);

  // OS
  dest.os := Ord(h[9]);

  if (flags and Flag_ExtraData) <> 0 then
  begin
    in_stream.Read(h, 2);
    len := Ord(h[0]) + (Ord(h[1]) shl 8);
    SetLength(dest.extra, len);
    in_stream.Read(pchar(dest.extra)^, len);
  end;

  if (flags and Flag_FileName) <> 0 then
  begin
    in_stream.Read(h, 1);
    while h[0] <> #0 do
    begin
      dest.fname := dest.fname + h[0];
      in_stream.Read(h, 1);
    end;
  end;

  if (flags and Flag_Comment) <> 0 then
  begin
    in_stream.Read(h, 1);
    while h[0] <> #0 do
    begin
      dest.comment := dest.comment + h[0];
      in_stream.Read(h, 1);
    end;
  end;

  if (flags and Flag_HeaderCRC) <> 0 then
  begin
    in_stream.Read(h, 2); // simply ignore
  end;

  crcval := 0;
  total_len := 0;

  // now begins compressed block
  decomp := TDecompressionStream.CreateNoHeader(in_stream);
  try
    repeat
      len := decomp.Read(buf, blocksize);
      crcval := crc32_block(crcval, pchar(@buf[0]), len);
      if dest.rawdata <> nil then
        dest.rawdata.Write(buf, len);
      Inc(total_len, len);
    until len < blocksize;
  finally
    decomp.Free;
  end;

  // tail data(CRC)
  in_stream.Read(h, 4);
  len := Ord(h[0]) + (Ord(h[1]) shl 8) + (Ord(h[2]) shl 16) + (Ord(h[3]) shl 24);
  if len <> crcval then
    raise EGzipCorruptDataError.Create('Invalid CRC');

  // ISIZE
  in_stream.Read(h, 4);
  len := Ord(h[0]) + (Ord(h[1]) shl 8) + (Ord(h[2]) shl 16) + (Ord(h[3]) shl 24);
  if len <> total_len then
    raise EGzipCorruptDataError.Create('Invalid Length');
end;

procedure gzCompress( const src:TGzipRecord; out_stream: TStream );
var
  h: array[0..9] of char;
  flags: cardinal;
  mtime: LongInt;
  len: cardinal;
  comp: TCompressionStream;
  crcval: Cardinal;
  total_len: Cardinal;
  compLevel:  TCompressionLevel;
  buf: TMemoryStream;
begin
  h[0] := ID1;
  h[1] := ID2;

  // CM: compression method
  if src.method <> cmDeflate then
    raise EGzipUnknownMethodError.Create('Unknown Compression Method!');

  // FLG
  flags := 0;
  if src.isText then
    flags := flags or Flag_Text;
  if src.extra <> '' then
    flags := flags or Flag_ExtraData;
  if src.fname <> '' then
    flags := flags or Flag_FileName;
  if src.comment <> '' then
    flags := flags or Flag_Comment;
  h[3] := Char(flags);

  // MTIME
  mtime := Round((src.mtime - EncodeDate(1970,1,1)) * 24.*60*60);
  h[4] := Char(mtime and $ff);
  h[5] := Char((mtime shr 8) and $ff);
  h[6] := Char((mtime shr 16) and $ff);
  h[7] := Char((mtime shr 24) and $ff);

  // XFL
  h[8] := Char(src.xfl);
  case src.xfl of
  XFL_Deflate_Maximum:
    compLevel := clMax;
  XFL_Deflate_Fastest:
    compLevel := clFastest;
  else
    compLevel := clDefault;
  end;

  // OS
  h[9] := Char(src.os);

  out_stream.Write(h, 10);

  if (flags and Flag_ExtraData) <> 0 then
  begin
    len := Length(src.extra);
    h[0] := Char(len and $ff);
    h[1] := Char((len shr 8) and $ff);
    out_stream.Write(h, 2);
    out_stream.Write(pchar(src.extra)^, len);
  end;

  if (flags and Flag_FileName) <> 0 then
  begin
    if Pos(#0, src.fname) > 0 then
      raise EGzipCorruptDataError.Create('fname must not include #0');
    out_stream.Write(pchar(src.fname)^, Length(src.fname));
    h[0] := #0;
    out_stream.Write(h, 1);
  end;

  if (flags and Flag_Comment) <> 0 then
  begin
    if Pos(#0, src.comment) > 0 then
      raise EGzipCorruptDataError.Create('comment must not include #0');
    out_stream.Write(pchar(src.comment)^, Length(src.comment));
    h[0] := #0;
    out_stream.Write(h, 1);
  end;

  crcval := 0;

  // now being compressed the block
  comp := TCompressionStream.CreateNoHeader(compLevel, out_stream);
  try
    buf := TMemoryStream.Create;
    try
      buf.LoadFromStream(src.rawdata);
      len := buf.Size;
      crcval := crc32_block(crcval, buf.Memory, len);
      comp.Write(buf.Memory^, len);
      total_len := len;
    finally
      buf.Free;
    end;
  finally
    comp.Free;
  end;

  // tail data(CRC)
  h[0] := Char(crcval and $ff);
  h[1] := Char((crcval shr 8) and $ff);
  h[2] := Char((crcval shr 16) and $ff);
  h[3] := Char((crcval shr 24) and $ff);
  // ISIZE
  h[4] := Char(total_len and $ff);
  h[5] := Char((total_len shr 8) and $ff);
  h[6] := Char((total_len shr 16) and $ff);
  h[7] := Char((total_len shr 24) and $ff);
  out_stream.Write(h, 8);
end;

end.
