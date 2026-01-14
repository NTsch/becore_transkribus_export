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
            <xsl:apply-templates/>
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
    
    <xsl:template match="hi[@text-decoration='line-through']">
        <cei:del>
            <xsl:apply-templates/>
        </cei:del>
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

    <xsl:template match="date">
        <cei:date value="99999999">
            <xsl:apply-templates/>
        </cei:date>
    </xsl:template>

    <xsl:template match="date" mode="write">
        <cei:date value="99999999">
            <xsl:apply-templates/>
        </cei:date>
    </xsl:template>

    <xsl:template match="date[@continued]" mode="write">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="rs">
        <xsl:choose>
            <xsl:when test="@type = 'person'">
                <cei:persName>
                    <xsl:apply-templates/>
                </cei:persName>
            </xsl:when>
            <xsl:when test="@type = 'place'">
                <cei:placeName>
                    <xsl:apply-templates/>
                </cei:placeName>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="rs" mode="write">
        <xsl:choose>
            <xsl:when test="@type = 'person'">
                <cei:persName>
                    <xsl:apply-templates/>
                </cei:persName>
            </xsl:when>
            <xsl:when test="@type = 'place'">
                <cei:placeName>
                    <xsl:apply-templates/>
                </cei:placeName>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="rs[@continued]" mode="write">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template
        match="lb[preceding-sibling::node()[2][@continued]][following-sibling::node()[1][@continued]]"
        mode="write">
        <xsl:element name="cei:{name()}" namespace="http://www.monasterium.net/NS/cei">
            <xsl:copy-of select="@*[normalize-space()]"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template
        match="lb[preceding-sibling::node()[2][@continued]][following-sibling::node()[1][@continued]]"/>

    <!-- ########## process date element that has been split into several elements due to line breaks in original PAGE file ########## -->

    <xsl:template
        match="date[@continued][following-sibling::*[1][local-name() = 'lb'][following-sibling::*[1][local-name() = 'date'][@continued]]]">
        <!--apply beginning element-->
        <cei:date value="99999999">
            <xsl:apply-templates/>
            <!--apply middle element, if exists-->
            <!--start with lb of middle element-->
            <xsl:apply-templates
                select="./following-sibling::date[@continued][following-sibling::node()[2][local-name() = 'lb']][preceding-sibling::node()[1][local-name() = 'lb']][following-sibling::node()[3][local-name() = 'date']][1]/preceding-sibling::lb[1]"
                mode="write"/>
            <!--then content of middle element-->
            <xsl:apply-templates
                select="./following-sibling::date[@continued][following-sibling::node()[2][local-name() = 'lb']][preceding-sibling::node()[1][local-name() = 'lb']][following-sibling::node()[3][local-name() = 'date']][1]"
                mode="write"/>
            <!--apply end element-->
            <!--start with lb of end element-->
            <xsl:apply-templates
                select="./following-sibling::date[@continued][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[3][local-name() = 'date'])][1]/preceding-sibling::lb[1]"
                mode="write"/>
            <!--then content of end element-->
            <xsl:apply-templates
                select="./following-sibling::date[@continued][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[3][local-name() = 'date'])][1]"
                mode="write"/>
        </cei:date>
    </xsl:template>

    <!--prevent date middle element from executing regularly-->
    <xsl:template
        match="date[@continued][following-sibling::node()[2][local-name() = 'lb']][preceding-sibling::node()[1][local-name() = 'lb']][following-sibling::node()[3][local-name() = 'date']]"/>

    <!--prevent date end element from executing regularly-->
    <xsl:template
        match="date[@continued][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[3][local-name() = 'date'])][preceding-sibling::node()[3][local-name() = 'date']]"/>

    <!-- ############################################################################### -->

    <!-- ########## process rs element that has been split into several elements due to line breaks in original PAGE file ########## -->

    <xsl:template
        match="rs[@continued][@type = 'person'][following-sibling::*[1][local-name() = 'lb'][following-sibling::*[1][local-name() = 'rs'][@continued]]]">
        <!--apply beginning element-->
        <cei:persName>
            <xsl:apply-templates/>
            <!--apply all middle elements-->
            <xsl:apply-templates
                select="./following-sibling::rs[@continued][@type = 'person'][following-sibling::node()[2][local-name() = 'lb']][preceding-sibling::node()[1][local-name() = 'lb']][following-sibling::node()[3][local-name() = 'rs'][@type = 'person']][1]/preceding-sibling::lb[1]"
                mode="write"/>
            <xsl:apply-templates
                select="./following-sibling::rs[@continued][@type = 'person'][following-sibling::node()[2][local-name() = 'lb']][preceding-sibling::node()[1][local-name() = 'lb']][following-sibling::node()[3][local-name() = 'rs'][@type = 'person']][1]"
                mode="write"/>
            <!--apply end element-->
            <!--start with lb of end element-->
            <xsl:apply-templates
                select="./following-sibling::rs[@continued][@type = 'person'][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[3][local-name() = 'rs'][@type = 'person'])][1]/preceding-sibling::lb[1]"
                mode="write"/>
            <!--then content of end element-->
            <xsl:apply-templates
                select="./following-sibling::rs[@continued][@type = 'person'][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[3][local-name() = 'rs'][@type = 'person'])][1]"
                mode="write"/>
        </cei:persName>
    </xsl:template>

    <xsl:template
        match="rs[@continued][@type = 'place'][following-sibling::*[1][local-name() = 'lb'][following-sibling::*[1][local-name() = 'rs'][@continued]]]">
        <!--apply beginning element-->
        <cei:placeName>
            <xsl:apply-templates/>
            <!--apply all middle elements-->
            <xsl:apply-templates
                select="./following-sibling::rs[@continued][@type = 'place'][following-sibling::node()[2][local-name() = 'lb']][preceding-sibling::node()[1][local-name() = 'lb']][following-sibling::node()[3][local-name() = 'rs'][@type = 'place']][1]/preceding-sibling::lb[1]"
                mode="write"/>
            <xsl:apply-templates
                select="./following-sibling::rs[@continued][@type = 'place'][following-sibling::node()[2][local-name() = 'lb']][preceding-sibling::node()[1][local-name() = 'lb']][following-sibling::node()[3][local-name() = 'rs'][@type = 'place']][1]"
                mode="write"/>
            <!--apply end element-->
            <!--start with lb of end element-->
            <xsl:apply-templates
                select="./following-sibling::rs[@continued][@type = 'place'][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[3][local-name() = 'rs'][@type = 'place'])][1]/preceding-sibling::lb[1]"
                mode="write"/>
            <!--then content of end element-->
            <xsl:apply-templates
                select="./following-sibling::rs[@continued][@type = 'place'][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[3][local-name() = 'rs'][@type = 'place'])][1]"
                mode="write"/>
        </cei:placeName>
    </xsl:template>

    <!--prevent rs middle elements from executing regularly-->
    <xsl:template
        match="rs[@continued][following-sibling::node()[2][local-name() = 'lb']][preceding-sibling::node()[1][local-name() = 'lb']][following-sibling::node()[3][local-name() = 'rs']]"/>

    <!--prevent rs end element from executing regularly-->
    <xsl:template
        match="rs[@continued][preceding-sibling::node()[1][local-name() = 'lb']][not(following-sibling::node()[3][local-name() = 'rs'])]"/>

    <!-- ############################################################################### -->

</xsl:stylesheet>
