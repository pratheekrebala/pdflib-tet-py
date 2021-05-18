<?xml version="1.0" encoding="UTF-8"?>
<!--
    (C) PDFlib GmbH 2015 www.pdflib.com

    Purpose: generate input for the Solr enterprise search server
                http://lucene.apache.org/solr/
    
    Expected input: TETML in any mode except "glyph".
    
    Stylesheet parameters: none
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0"
    exclude-result-prefixes="tet"
>
	<xsl:output method="xml" indent="yes"/>
	
	<xsl:template match="/">
                <!-- Make sure that the input TETML was not prepared in glyph mode -->
                <xsl:if test=".//tet:Content[@granularity = 'glyph']">
                        <xsl:message terminate="yes">
                                <xsl:text>Stylesheet solr.xsl processing TETML for document '</xsl:text>
                                <xsl:value-of select="/tet:TET/tet:Document/@filename" />
                                <xsl:text>': this stylesheet does not work with TETML in glyph mode. </xsl:text>
                                <xsl:text>Create the input in mode "word" or "page".</xsl:text>
                        </xsl:message>
                </xsl:if>
                
                <add>
                        <doc>
                                <xsl:apply-templates select="tet:TET/tet:Document" />
                                <xsl:apply-templates select="tet:TET/tet:Document/tet:DocInfo/*" />
                                <xsl:apply-templates select=".//tet:Text" />
                        </doc>
                </add>
	</xsl:template>

        <xsl:template match="tet:Document">
                <field>
                        <xsl:attribute name="name">
                                <xsl:text>id</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of select="@filename" />
                </field>
        </xsl:template>

        <!-- Catch the Custom DocInfo elements that have their name in the @key attribute -->
        <xsl:template match="tet:DocInfo/tet:Custom">
                <field>
                        <xsl:attribute name="name">
                                <xsl:value-of select="@key" />
                                <xsl:text>_s</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of select="." />
                </field>
        </xsl:template>
         
        <!-- Catch the standard DocInfo elements and use their name to construct the field name -->       
        <xsl:template match="tet:DocInfo/*">
                <field>
                        <xsl:attribute name="name">
                                <xsl:value-of select="local-name()" />
                                <xsl:text>_s</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of select="." />
                </field>
        </xsl:template>
                
	<xsl:template match="tet:Text">
                <field>
                        <xsl:attribute name="name">
                                <xsl:text>text</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of select="." />
                </field>
        </xsl:template>
</xsl:stylesheet>