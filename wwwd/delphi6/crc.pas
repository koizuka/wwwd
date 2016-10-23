unit crc;
(* crc32.c -- compute the CRC-32 of a data stream
 * Copyright (C) 1995-1998 Mark Adler
 * For conditions of distribution and use, see copyright notice in zlib.h
 *)

(* @(#) $Id: crc.pas,v 1.4 2000/05/17 17:39:32 koizuka Exp $ *)


interface

function crc32_block( crc:Cardinal; buf:Pchar; len: Cardinal): Cardinal;
function crc32_byte( crc:Cardinal; b:Byte): Cardinal;

implementation

var
  //crc_table_empty: boolean = true;
  crc_table: array[0..255] of Cardinal;

(*
  Generate a table for a byte-wise 32-bit CRC calculation on the polynomial:
  x^32+x^26+x^23+x^22+x^16+x^12+x^11+x^10+x^8+x^7+x^5+x^4+x^2+x+1.

  Polynomials over GF(2) are represented in binary, one bit per coefficient,
  with the lowest powers in the most significant bit.  Then adding polynomials
  is just exclusive-or, and multiplying a polynomial by x is a right shift by
  one.  If we call the above polynomial p, and represent a byte as the
  polynomial q, also with the lowest power in the most significant bit (so the
  byte 0xb1 is the polynomial x^7+x^3+x+1), then the CRC is (q*x^32) mod p,
  where a mod b means the remainder after dividing a by b.

  This calculation is done using the shift-register method of multiplying and
  taking the remainder.  The register is initialized to zero, and for each
  incoming bit, x^32 is added mod p to the register if the bit is a one (where
  x^32 mod p is p+x^32 = x^26+...+1), and the register is multiplied mod p by
  x (which is shifting right by one and adding x^32 mod p if the bit shifted
  out is a one).  We start with the highest power (least significant bit) of
  q and repeat for all eight bits of q.

  The table is simply the CRC of all possible eight bit values.  This is all
  the information needed to generate CRC's on data a byte at a time for all
  combinations of CRC register values and incoming bytes.
*)
procedure make_crc_table;
var
  c: Cardinal;
  n, k: integer;
  poly: Cardinal; (* polynomial exclusive-or pattern *)
const
  (* terms of polynomial defining this crc (except x^32): *)
  num_p = 14;
  p: array[0..num_p-1] of byte = (0,1,2,4,5,7,8,10,11,12,16,22,23,26);
begin

  (* make exclusive-or pattern from polynomial (0xedb88320L) *)
  poly := 0;
  for n := 0 to num_p-1 do
    poly := poly or 1 shl (31 - p[n]);

  for n := 0 to 255 do begin
    c := n;
    for k := 0 to 7 do
    begin
      if (c and 1) <> 0 then
        c := poly xor (c shr 1)
      else
        c := c shr 1;
    end;
    crc_table[n] := c;
  end;
  //crc_table_empty := false;
end;

(* =========================================================================
 * This function can be used by asm versions of crc32()
 *)
{
const uLongf * ZEXPORT get_crc_table()
begin
#ifdef DYNAMIC_CRC_TABLE
  if (crc_table_empty) make_crc_table();
#endif
  return (const uLongf *)crc_table;
end
}

(* ========================================================================= *)
function crc32_block( crc:Cardinal; buf:Pchar; len: Cardinal): Cardinal;
begin
  if (buf = nil) or (len = 0) then begin
    result := crc;
    exit;
  end;
  //if crc_table_empty then
  //  make_crc_table;

  crc := not crc;
  while len >= 8 do
  begin
    crc := crc_table[(crc xor byte(buf[0])) and $ff] xor (crc shr 8);
    crc := crc_table[(crc xor byte(buf[1])) and $ff] xor (crc shr 8);
    crc := crc_table[(crc xor byte(buf[2])) and $ff] xor (crc shr 8);
    crc := crc_table[(crc xor byte(buf[3])) and $ff] xor (crc shr 8);
    crc := crc_table[(crc xor byte(buf[4])) and $ff] xor (crc shr 8);
    crc := crc_table[(crc xor byte(buf[5])) and $ff] xor (crc shr 8);
    crc := crc_table[(crc xor byte(buf[6])) and $ff] xor (crc shr 8);
    crc := crc_table[(crc xor byte(buf[7])) and $ff] xor (crc shr 8);

    Inc(buf, 8);
    Dec(len, 8);
  end;
  if len <> 0 then begin
    repeat
      crc := crc_table[(crc xor byte(buf^)) and $ff] xor (crc shr 8);
      Inc(buf);

      Dec(len);
    until len = 0;
  end;
  result := not crc;
end;

function crc32_byte( crc:Cardinal; b:Byte): Cardinal;
begin
  crc := crc xor $ffffffff;
  crc := crc_table[(crc xor b) and $ff] xor (crc shr 8);
  result := crc xor $ffffffff;
end;

begin
  make_crc_table;
end.
