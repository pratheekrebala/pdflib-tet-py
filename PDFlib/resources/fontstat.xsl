<?xml version="1.0" encoding="UTF-8"?>
<!--
           Copyright (c) 2008-2019 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.

    Purpose: generate font and glyph statistics from TETML input
    
    Expected input: TETML in "glyph" or "wordplus" mode.
    
    Stylesheet parameters: none
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0"
>
	<xsl:output method="text" />

        <!-- Index the Glyph element by their font ids -->
        <xsl:key name="glyphs" match="tet:TET/tet:Document/tet:Pages//tet:Glyph" use="@font" />
        
	<xsl:variable name="total-glyph-count" select="count(/tet:TET/tet:Document/tet:Pages//tet:Glyph)" />
	
	<xsl:template match="/">
		<!-- Make sure that font information is present in the input TETML. -->
		<xsl:if test="tet:TET/tet:Document/tet:Pages//tet:Content[not(@font = 'true')]">
			<xsl:message terminate="yes">
				<xsl:text>Stylesheet fontstat.xsl processing TETML for document '</xsl:text>
				<xsl:value-of select="tet:TET/tet:Document/@filename" />
				<xsl:text>': this stylesheet requires font info in TETML. </xsl:text>
				<xsl:text>Create the input in page mode "glyph" or "wordplus".</xsl:text>
			</xsl:message>
		</xsl:if>

                <xsl:value-of select="$total-glyph-count" />
                <xsl:text> total glyphs in the document; breakdown by font:&#xa;&#xa;</xsl:text>
                
		<xsl:apply-templates select="tet:TET/tet:Document/tet:Pages//tet:Font">
        		<!-- Sort descending by number of Glyph elements that refer to the Font element. -->
        		<xsl:sort select="count(key('glyphs', @id))" data-type="number" order="descending" />
		</xsl:apply-templates>
	</xsl:template>

	<!-- Iterate over all fonts in the document. -->
	<xsl:template match="tet:Font">
                <!-- Compute the total number of references to the font -->
                <xsl:variable name="count" select="count(key('glyphs', @id))" />
                
		<!-- Print the percentage, font name, and glyph count, with two digits after the decimal point. -->
		<xsl:value-of select="round($count div $total-glyph-count * 10000) div 100" />
		<xsl:text>% </xsl:text>

		<xsl:value-of select="@name" />
		<xsl:text>: </xsl:text>

		<!-- Emit the total number of glyphs in this font -->
		<xsl:value-of select="$count" />
		<xsl:text> glyphs</xsl:text>

		<!-- Determine the number of unknown glyphs for this font, i .e. those without proper
		     Unicode mapping.
		-->
		<xsl:variable name="unknown-glyph-count" select="count(key('glyphs', @id)[@unknown = 'true'])" />
		<xsl:if test="$unknown-glyph-count > 0">
			<xsl:text> (</xsl:text>
			<xsl:value-of select="$unknown-glyph-count" />
			<xsl:text> unknown)</xsl:text> 
		</xsl:if>

		<!-- Determine the number of ligatures for this font, i.e. Glyph elements
		     with more than one character.
		-->

		<xsl:variable name="ligatures" select="key('glyphs', @id)[string-length() > 1]" />		
		<xsl:variable name="ligature-count" select="count($ligatures)" />
		<xsl:if test="$ligature-count > 0">
			<xsl:text>, </xsl:text>
			<xsl:value-of select="$ligature-count" />
			<xsl:text> uses of ligatures: </xsl:text>

			<xsl:for-each select="$ligatures[not(. = preceding::tet:Glyph[@font=current()/@id])]">
				<xsl:value-of select="." />
				<xsl:text> </xsl:text>
			</xsl:for-each>
		</xsl:if>
		
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
</xsl:stylesheet>
