<?xml version="1.0" encoding="UTF-8"?>
<!--
           Copyright (c) 2008-2015 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.

    Purpose: Create a listing of all fields used in the document.
    
    Expected input: TETML in "glyph", "word" or "wordplus" mode.
    
    Stylesheet parameters:
    
    print-javascript:
        0: do not print JavaScript code
        1: print JavaScript code (can make output convoluted)
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0"
>
    <xsl:output method="text"/>

    <xsl:param name="print-javascript">0</xsl:param>

    <xsl:template match="/">

        <xsl:text>List of form fields in the document:&#xa;&#xa;</xsl:text>
        
        <!-- For all pages that have form fields -->
        <xsl:apply-templates select="tet:TET/tet:Document/tet:Pages/tet:Page[tet:Fields]" />

    </xsl:template>

    <xsl:template match="tet:Page">
        <xsl:text>Page </xsl:text>
        <xsl:value-of select="count(preceding-sibling::tet:Page) + 1" />
        <xsl:text>:&#xa;</xsl:text>
        
        <xsl:apply-templates select="tet:Fields/tet:Field" >
            <xsl:with-param name="indent"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="tet:Field">
        <!-- Indent according to the number of Field parent elements -->
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="2 * count(ancestor::tet:Field) + 2" />
        </xsl:call-template>
        
        <xsl:text>Field </xsl:text>
        <xsl:value-of select="count(preceding-sibling::tet:Field) + 1" />
        <xsl:text>: fullname='</xsl:text>
        
        <xsl:value-of select="@name" />
        
        <xsl:text>' type=</xsl:text>
        <xsl:value-of select="@type" />
        <xsl:text>&#xa;</xsl:text>
        
        <xsl:apply-templates select="tet:Tooltip | tet:DefaultValue | tet:Value | tet:Field | tet:Action" />
    </xsl:template>

    <xsl:template match="tet:Action">
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="2 * (count(ancestor::tet:Field) - 1) + 4" />
        </xsl:call-template>
        
        <xsl:text>Action: type=</xsl:text>
        <xsl:value-of select="@type" />
        
        <xsl:if test="@trigger">
            <xsl:text> trigger=</xsl:text>
            <xsl:value-of select="@trigger" />
        </xsl:if>
        
        <xsl:if test="@filename">
            <xsl:text> filename='</xsl:text>
            <xsl:value-of select="@filename" />
            <xsl:text>'</xsl:text>
        </xsl:if>
        
        <xsl:if test="@URI">
            <xsl:text> URI='</xsl:text>
            <xsl:value-of select="@URI" />
            <xsl:text>'</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
        
        <xsl:if test="@javascript and $print-javascript != 0">
            <xsl:call-template name="blanks">
                <xsl:with-param name="count" select="2 * (count(ancestor::tet:Field) - 1) + 6" />
            </xsl:call-template>
            
            <xsl:text> JavaScript code: '</xsl:text>
            <xsl:value-of select="/tet:TET/tet:Document/tet:JavaScripts/tet:JavaScript[@id = current()/@javascript]" />
            <xsl:text>'&#xa;</xsl:text>
        </xsl:if>
        
    </xsl:template>

    <xsl:template match="tet:Tooltip">
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="2 * (count(ancestor::tet:Field) - 1) + 4" />
        </xsl:call-template>
        
        <xsl:text>Tooltip: '</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>'&#xa;</xsl:text>
    </xsl:template>
    
    <xsl:template match="tet:DefaultValue">
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="2 * (count(ancestor::tet:Field) - 1) + 4" />
        </xsl:call-template>
        
        <xsl:text>Default value: '</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>'&#xa;</xsl:text>
    </xsl:template>
    
    <xsl:template match="tet:Value">
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="2 * (count(ancestor::tet:Field) - 1) + 4" />
        </xsl:call-template>
        
        <xsl:text>Value: '</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>'&#xa;</xsl:text>
    </xsl:template>
    
    <xsl:template match="tet:OptionalValue">
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="2 * (count(ancestor::tet:Field) - 1) + 4" />
        </xsl:call-template>
        
        <xsl:text>Optional value: '</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>'&#xa;</xsl:text>
    </xsl:template>
    
    <!-- Produce a sequence of count blanks for indenting -->
    <xsl:template name="blanks">
        <xsl:param name="count"/>
        
        <xsl:if test="$count &gt; 0">
            <xsl:text> </xsl:text>
            <xsl:call-template name="blanks">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
