xquery version "3.1";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace cei = "http://www.monasterium.net/NS/cei";

<result>
{
  let $tenors := collection('../transcriptions/cei')//cei:pTenor
  let $elements := distinct-values($tenors//*/name())
  for $element-name in $elements
  return
    element { $element-name }
    {
      for $doc in collection('../transcriptions/cei')
      where $doc//*[name() = $element-name]
      return <uri>{substring-after($doc/base-uri(), 'transcriptions/cei/')}</uri>
    }
}
</result>