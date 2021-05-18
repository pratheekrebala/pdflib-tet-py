<?xml version="1.0" encoding="UTF-8"?>
<!--
           Copyright (c) 2008-2019 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.

    Purpose: For all fonts in a document, list all occurrences along with
    page number and position information.
    
    Expected input: TETML in "glyph" or "wordplus" mode.
    
    Stylesheet parameters: none
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0">
    <xsl:output method="text" />
    
    <xsl:template match="/">
	<!-- Make sure that font information is present in the input TETML. -->
	<xsl:if test="tet:TET/tet:Document/tet:Pages//tet:Content[not(@font = 'true')]">
		<xsl:message terminate="yes">
			<xsl:text>Stylesheet fontfinder.xsl processing TETML for document '</xsl:text>
			<xsl:value-of select="tet:TET/tet:Document/@filename" />
			<xsl:text>': this stylesheet requires font info in TETML. </xsl:text>
			<xsl:text>Create the input in page mode "glyph" or "wordplus".</xsl:text>
		</xsl:message>
	</xsl:if>
		
        <!-- Iterate over all fonts in the document. -->
        <xsl:for-each select="tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font">
            <xsl:variable name="current-font-id" select="@id" />
            
            <!-- Leave an empty line after each font block. -->
            <xsl:if test="position() != 1">
                <xsl:text>&#xa;</xsl:text>
            </xsl:if>
            
            <!-- Print header for current font. -->
            <xsl:value-of select="@name" />
            <xsl:text> used on:&#xa;</xsl:text>
            
            <!-- Select all pages in the document where the current font occurs. -->
            <xsl:for-each select="ancestor::tet:Pages[1]/tet:Page[.//tet:Word[tet:Box/tet:Glyph/@font = $current-font-id]]">
                <!-- Header for each page. -->
                <xsl:text>page </xsl:text>
                <xsl:value-of select="@number" />
                <xsl:text>:&#xa;</xsl:text>
                
                <!-- Select all words in the page that refer to the current font. -->
                <xsl:for-each select=".//tet:Word[tet:Box/tet:Glyph/@font = $current-font-id]">
                    <xsl:variable name="font-index" select="position() - 1" />
                    <!--
                        Separate coordinates within line by commata, and begin a
                        new line after each eighth coordinate.
                    -->
                    <xsl:choose>
                        <xsl:when test="$font-index = 0" />
                        <xsl:when test="$font-index mod 8 = 0">
                            <xsl:text>,&#xa;</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>, </xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <!-- Print lower left coordinates. -->
                    <xsl:text>(</xsl:text>
                    <xsl:value-of select="round(tet:Box/@llx)" />
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="round(tet:Box/@lly)" />
                    <xsl:text>)</xsl:text>
                </xsl:for-each>
                
                <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
