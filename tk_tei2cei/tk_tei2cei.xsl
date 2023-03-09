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
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates/>
            </cei:pb>
            <xsl:apply-templates select="following-sibling::ab[contains(@facs, concat(current()/@facs, '_'))]" mode="tenor"/>
        </cei:tenor>
    </xsl:template>

    <xsl:template match="ab" mode="tenor">
        <cei:pTenor>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </cei:pTenor>
    </xsl:template>
    
    <xsl:template match="ab"/>

    <xsl:template match="ab//*">
        <xsl:element name="cei:{name()}" namespace="http://www.monasterium.net/NS/cei">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
