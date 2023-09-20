<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cei="http://www.monasterium.net/NS/cei" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="2.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0">

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="TEI">
        <cei:cei>
            <xsl:apply-templates/>
        </cei:cei>
    </xsl:template>

    <xsl:template match="teiHeader//descendant-or-self::*">
        <xsl:element name="cei:{name()}" namespace="http://www.monasterium.net/NS/cei">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="facsimile"/>

    <xsl:template match="pb[following-sibling::ab[contains(@facs, @facs/current())]]">
        <cei:tenor>
            <cei:pb>
                <xsl:copy-of select="@*[not(name() = 'xml:id')]"/>
                <xsl:attribute name="id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
                <xsl:apply-templates/>
            </cei:pb>
            <xsl:apply-templates
                select="following-sibling::ab[contains(@facs, concat(current()/@facs, '_'))]"
                mode="tenor"/>
        </cei:tenor>
    </xsl:template>

    <xsl:template match="ab" mode="tenor">
        <cei:pTenor>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates
                select="node()[not(count(preceding-sibling::*[@continued]) mod 2 ne 0)]"/>
        </cei:pTenor>
    </xsl:template>

    <xsl:template match="ab"/>

    <xsl:template
        match="ab//*[not(name() = 'hi' or name() = 'choice' or name() = 'foreign' or name() = 'sic' or name() = 'rs' or name() = 'date' or name() = 'comment')]">
        <xsl:element name="cei:{name()}" namespace="http://www.monasterium.net/NS/cei">
            <xsl:copy-of select="@*[normalize-space()]"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="hi">
        <cei:hi>
            <xsl:copy-of select="@*[not(name() = 'style')]"/>
            <xsl:attribute name="rend">
                <xsl:value-of select="@style"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </cei:hi>
    </xsl:template>

    <xsl:template match="foreign">
        <cei:foreign>
            <xsl:copy-of select="@*[not(name() = 'continued')]"/>
            <xsl:apply-templates/>
        </cei:foreign>
    </xsl:template>

    <xsl:template match="choice[sic and corr]">
        <cei:sic corr="{corr}">
            <xsl:copy-of select="sic/@*[normalize-space()]"/>
            <xsl:if test="sic/@corresp">
                <xsl:attribute name="n">
                    <xsl:value-of select="sic/@corresp"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="sic"/>
        </cei:sic>
    </xsl:template>

    <xsl:template match="sic[parent::choice]">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="rs">
        <xsl:choose>
            <xsl:when test="@type = 'person'">
                <cei:persName>
                    <xsl:apply-templates/>
                    <xsl:if
                        test="@continued = 'true' and (count(preceding-sibling::rs[@continued and @type = 'person']) mod 2 = 0)">
                        <xsl:call-template name="combine-split">
                            <xsl:with-param name="element-name" select="'rs'"/>
                            <xsl:with-param name="type-name" select="'person'"/>
                            <xsl:with-param name="nth-instance"
                                select="count(preceding-sibling::rs[@continued = 'true' and @type = 'person']) + 1"
                            />
                        </xsl:call-template>
                    </xsl:if>
                </cei:persName>
            </xsl:when>
            <xsl:when test="@type = 'place'">
                <cei:placeName>
                    <xsl:apply-templates/>
                    <xsl:if
                        test="@continued = 'true' and (count(preceding-sibling::rs[@continued and @type = 'place']) mod 2 = 0)">
                        <xsl:call-template name="combine-split">
                            <xsl:with-param name="element-name" select="'rs'"/>
                            <xsl:with-param name="type-name" select="'place'"/>
                            <xsl:with-param name="nth-instance"
                                select="count(preceding-sibling::rs[@continued = 'true' and @type = 'place']) + 1"
                            />
                        </xsl:call-template>
                    </xsl:if>
                </cei:placeName>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="date">
        <cei:date value="99999999">
            <xsl:apply-templates/>
        </cei:date>
    </xsl:template>

    <!-- ########## process date element that has been split into several elements due to line breaks in original PAGE file ########## -->

    <xsl:template
        match="date[@continued = 'true'][following-sibling::*[position() mod 2 = 0][local-name() = 'date']][not(preceding-sibling::*[position() mod 2 = 0][local-name() = 'date'])]">
        <!--apply beginning element-->
        <cei:date value="99999999">
            <xsl:apply-templates/>
            <!--apply all middle elements-->
            <xsl:apply-templates
                select="./following-sibling::date[@continued = 'true'][following-sibling::*[position() = 1][local-name() = 'lb']][preceding-sibling::*[position() = 1][local-name() = 'lb']][following-sibling::*[position() = 2][local-name() = 'date']][preceding-sibling::*[position() = 2][local-name() = 'date']]/preceding-sibling::lb[1]"/>
            <xsl:apply-templates
                select="./following-sibling::date[@continued = 'true'][following-sibling::*[position() = 1][local-name() = 'lb']][preceding-sibling::*[position() = 1][local-name() = 'lb']][following-sibling::*[position() = 2][local-name() = 'date']][preceding-sibling::*[position() = 2][local-name() = 'date']]//node()"/>
            <!--apply end element-->
            <xsl:apply-templates
                select="./following-sibling::date[@continued = 'true'][preceding-sibling::*[position() = 1][local-name() = 'lb']][not(following-sibling::*[position() = 2][local-name() = 'date'])][preceding-sibling::*[position() = 2][local-name() = 'date']]/preceding-sibling::lb[1]"/>
            <xsl:apply-templates
                select="./following-sibling::date[@continued = 'true'][preceding-sibling::*[position() = 1][local-name() = 'lb']][not(following-sibling::*[position() = 2][local-name() = 'date'])][preceding-sibling::*[position() = 2][local-name() = 'date']]//node()"
            />
        </cei:date>
    </xsl:template>

    <xsl:template
        match="date[@continued = 'true'][following-sibling::*[position() = 1][local-name() = 'lb']][preceding-sibling::*[position() = 1][local-name() = 'lb']][following-sibling::*[position() = 2][local-name() = 'date']][preceding-sibling::*[position() = 2][local-name() = 'date']]"
        mode="write">
        <!--date middle-->
    </xsl:template>
    <xsl:template
        match="date[@continued = 'true'][following-sibling::*[position() = 1][local-name() = 'lb']][preceding-sibling::*[position() = 1][local-name() = 'lb']][following-sibling::*[position() = 2][local-name() = 'date']][preceding-sibling::*[position() = 2][local-name() = 'date']]"/>

    <xsl:template
        match="date[@continued = 'true'][preceding-sibling::*[position() = 1][local-name() = 'lb']][not(following-sibling::*[position() = 2][local-name() = 'date'])][preceding-sibling::*[position() = 2][local-name() = 'date']]"
        mode="write">
        <!--date end-->
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template
        match="date[@continued = 'true'][preceding-sibling::*[position() = 1][local-name() = 'lb']][not(following-sibling::*[position() = 2][local-name() = 'date'])][preceding-sibling::*[position() = 2][local-name() = 'date']]"/>

    <!-- ############################################################################### -->

    <!-- ########## process rs element that has been split into several elements due to line breaks in original PAGE file ########## -->

    <xsl:template
        match="rs[@continued = 'true'][following-sibling::*[position() mod 2 = 0][local-name() = 'date']][not(preceding-sibling::*[position() mod 2 = 0][local-name() = 'date'])]">
        <xsl:variable name="type" select="./@type/data()"/>
        <!--apply beginning element-->
        <cei:rs type="{$type}">
            <xsl:apply-templates/>
            <!--apply all middle elements-->
            <xsl:apply-templates
                select="./following-sibling::rs[@continued = 'true'][@type = $type][following-sibling::*[position() = 1][local-name() = 'lb']][preceding-sibling::*[position() = 1][local-name() = 'lb']][following-sibling::*[position() = 2][local-name() = 'rs'][@type = $type]][preceding-sibling::*[position() = 2][local-name() = 'rs'][@type = $type]]/preceding-sibling::lb[1]"/>
            <xsl:apply-templates
                select="./following-sibling::rs[@continued = 'true'][@type = $type][following-sibling::*[position() = 1][local-name() = 'lb']][preceding-sibling::*[position() = 1][local-name() = 'lb']][following-sibling::*[position() = 2][local-name() = 'rs'][@type = $type]][preceding-sibling::*[position() = 2][local-name() = 'rs'][@type = $type]]//node()"/>
            <!--apply end element-->
            <xsl:apply-templates
                select="./following-sibling::rs[@continued = 'true'][@type = 'person'][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[1][local-name() = 'lb'] and not(following-sibling::node()[2][local-name() = 'rs'][@type = 'person']))][preceding-sibling::*[2][local-name() = 'rs'][@type = 'person'][@continued = 'true']]/preceding-sibling::lb[1]"/>
            <xsl:apply-templates
                select="./following-sibling::rs[@continued = 'true'][@type = 'person'][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[1][local-name() = 'lb'] and not(following-sibling::node()[2][local-name() = 'rs'][@type = 'person']))][preceding-sibling::*[2][local-name() = 'rs'][@type = 'person'][@continued = 'true']]//node()"
            />
        </cei:rs>
    </xsl:template>

    <xsl:template
        match="rs[@continued = 'true'][following-sibling::*[position() = 1][local-name() = 'lb']][preceding-sibling::*[position() = 1][local-name() = 'lb']][following-sibling::*[position() = 2][local-name() = 'rs']][preceding-sibling::*[position() = 2][local-name() = 'rs']]"
        mode="write">
        <!--date middle-->
    </xsl:template>
    <xsl:template
        match="rs[@continued = 'true'][following-sibling::*[position() = 1][local-name() = 'lb']][preceding-sibling::*[position() = 1][local-name() = 'lb']][following-sibling::*[position() = 2][local-name() = 'rs']][preceding-sibling::*[position() = 2][local-name() = 'rs']]"/>

    <xsl:template
        match="rs[@continued = 'true'][preceding-sibling::*[position() = 1][local-name() = 'lb']][not(following-sibling::*[position() = 2][local-name() = 'rs'])][preceding-sibling::*[position() = 2][local-name() = 'rs']]"
        mode="write">
        <!--date end-->
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template
        match="rs[@continued = 'true'][preceding-sibling::*[position() = 1][local-name() = 'lb']][not(following-sibling::*[position() = 2][local-name() = 'rs'])][preceding-sibling::*[position() = 2][local-name() = 'rs']]"/>

    <!-- ############################################################################### -->

    <xsl:template name="combine-split">
        <xsl:param name="element-name"/>
        <xsl:param name="type-name"/>
        <xsl:param name="nth-instance"/>
        <xsl:choose>
            <xsl:when test="string-length($type-name) > 0">
                <xsl:apply-templates
                    select="//*[count(preceding-sibling::*[name() = $element-name and @type = $type-name and @continued]) = $nth-instance and not(name() = $element-name and @type = $type-name and @continued)]"/>
                <xsl:apply-templates
                    select="//*[name() = $element-name and @type = $type-name and @continued and count(preceding-sibling::*[name() = $element-name and @type = $type-name and @continued]) = $nth-instance]//node()"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates
                    select="//*[count(preceding-sibling::*[name() = $element-name and @continued]) = $nth-instance and not(name() = $element-name and @continued)]"/>
                <xsl:apply-templates
                    select="//*[name() = $element-name and @continued and count(preceding-sibling::*[name() = $element-name and @continued]) = $nth-instance]//node()"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
