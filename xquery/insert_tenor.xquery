xquery version "3.1";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace cei = "http://www.monasterium.net/NS/cei";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace my="http://random.org/my";

let $arch_path := '/db/mom-data/metadata.charter.public/CZ-NA/'
let $schema := doc('/db/XRX.src/mom/app/cei/xsd/cei.xsd')

for $cei_transcript in collection('/db/niklas/cei_transcriptions/test')//cei:cei
let $orig_title := $cei_transcript/cei:teiHeader[1]/cei:fileDesc[1]/cei:titleStmt[1]/cei:title[1]
let $fixed_letters := replace($orig_title, 'Č', 'C')
let $momified_title := replace($fixed_letters, '([A-Za-z]+_\d+[A-Za-z]*).*', '$1')
let $final_char := substring($momified_title, string-length($momified_title))
let $final_char_lowercase := if ($final_char = 'A') then 'a' else $final_char
let $fixed_title:= replace($momified_title, '([A-Za-z]+_\d+[A-Za-z]*)' || $final_char || '$', '$1' || $final_char_lowercase)
let $path_end := replace($fixed_title, '_', '/')
let $full_path := concat($arch_path, $path_end, '.cei.xml')
let $charter := doc($full_path)
return 
  if (exists($charter)) then
    let $transcript_tenor := $cei_transcript//cei:tenor
    return
      if ($transcript_tenor = $charter//cei:tenor) then
        ()
      else
        update insert $transcript_tenor following $charter//cei:chDesc
  else
    fn:error(xs:QName("my:error"), concat("Charter does not exist: ", $full_path))