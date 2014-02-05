{
 open TomlParser
}

(** TODO:
    - datetime
    - \uXXXX \f \/ escaped characters
 *)

let t_white   = ['\t' ' ']
(** Tab char or space char *)
let t_eol     = ['\n' '\r']
(** Cross platform end of lines *)
let t_blank   = (t_white|t_eol)
(** Blank characters as specified by the ref *)
let t_digit   = ['0'-'9']
let t_int     = '-'?t_digit+
let t_float   = '-'?t_digit+'.'t_digit+
(** digits are needed in both side of the dot *)
let t_bool    = ("true"|"false")
(** booleans are full undercase *)
let t_key     = [^ '\t' '\n' ' ' '\r' '"' '=' '[' ',' ']']+
(** keys begins with non blank char and end with the first blank *)
(* very ugly, beark ! But how doing it right in ocamllex ? *)
let t_date    = t_digit t_digit t_digit t_digit '-' t_digit t_digit '-' t_digit t_digit 'T' t_digit t_digit ':' t_digit t_digit ':' t_digit t_digit 'Z'
(** ISO8601 date of form 1979-05-27T07:32:00Z *)
let t_escape  =  '\\' ['b' 't' 'n' 'f' 'r' '"' '/' '\\']

rule tomlex = parse
  | t_int as value   { INTEGER (int_of_string value) }
  | t_float as value { FLOAT (float_of_string value) }
  | t_bool as value  { BOOL (bool_of_string value) }
  | t_date as value  { DATE value }
  | t_white+ { tomlex lexbuf }
  | t_eol+ { tomlex lexbuf }
  | "[[" { failwith "Array of tables is not supported" }
  | '=' { EQUAL }
  | '[' { LBRACK }
  | ']' { RBRACK }
  | '"' { stringify (Buffer.create 13) lexbuf }
  | ',' { COMMA }
  | '#' (_ # t_eol)* { tomlex lexbuf }
  | t_key as value { KEY (value) }
  | eof   { EOF }

and stringify buff = parse
  | t_escape as value
    { Buffer.add_string buff (Scanf.unescaped value); stringify buff lexbuf }
  | '\\' { failwith "Forbidden escaped char" }
  (* no unterminated strings *)
  | eof  { failwith "Unterminated string" }
  | '"'  { STRING (Buffer.contents buff) }
  | _ as c { Buffer.add_char buff c; stringify buff lexbuf }

{}
