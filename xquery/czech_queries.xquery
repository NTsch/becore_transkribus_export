xquery version "3.1";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace cei = "http://www.monasterium.net/NS/cei";

let $rs:= collection('../transcriptions/cei')//cei:rs
return $rs[not(@type)]