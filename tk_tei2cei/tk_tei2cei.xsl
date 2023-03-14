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

    <xsl:template match="pb">
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
        match="ab//*[not(name() = 'hi' or name() = 'choice' or name() = 'foreign' or name() = 'sic' or name() = 'rs' or name() = 'date')]">
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

    <xsl:template match="rs[@type = 'person']">
        <cei:persName>
            <xsl:apply-templates/>
        </cei:persName>
    </xsl:template>
    
    <xsl:template match="rs[@type = 'place']">
        <cei:placeName>
            <xsl:apply-templates/>
        </cei:placeName>
    </xsl:template>
    
    <xsl:template match="date">
        <cei:date value="99999999">
            <xsl:apply-templates/>
        </cei:date>
    </xsl:template>
    
</xsl:stylesheet>
