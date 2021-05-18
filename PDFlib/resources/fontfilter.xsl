<?xml version="1.0" encoding="UTF-8"?>
<!--
           Copyright (c) 2008-2019 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.

    Purpose: List all words in a document which use a particular font in
    a size larger than a specified value. A word may contain multiple
    font/size combinations; only unique combinations are printed.
    
    Expected input: TETML in "glyph" or "wordplus" mode.
    
    Stylesheet parameters:
    font-name:		Name of the font to search for.
    min-size:		Minimum font size to search for.
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0">
    <xsl:output method="text" />
    
    <!-- Font to search for. -->
    <xsl:param name="font-name">ThesisAntiqua-Bold</xsl:param>
    
    <!-- Minimum font size to search for. -->
    <xsl:param name="min-size">10</xsl:param>
    
    <!--
        Template to print a heading and for looping over all the paragraphs. 
    -->
    <xsl:template match="/">
	<!-- Make sure that font information is present in the input TETML. -->
	<xsl:if test="tet:TET/tet:Document/tet:Pages//tet:Content[not(@font = 'true')]">
		<xsl:message terminate="yes">
			<xsl:text>Stylesheet fontfilter.xsl processing TETML for document '</xsl:text>
			<xsl:value-of select="tet:TET/tet:Document/@filename" />
			<xsl:text>': this stylesheet requires font info in TETML. </xsl:text>
			<xsl:text>Create the input in page mode "glyph" or "wordplus".</xsl:text>
		</xsl:message>
	</xsl:if>
	
        <xsl:text>Text containing font '</xsl:text>
        <xsl:value-of select="$font-name" />
        <xsl:text>' with size greater than </xsl:text>
        <xsl:value-of select="$min-size" />
        <xsl:text>:&#xa;&#xa;</xsl:text>
        <xsl:apply-templates select="tet:TET/tet:Document/tet:Pages" />
    </xsl:template>
        
    <!--
        Find all Words where at least one Glyph satisfies
        the search criteria. 
    -->
    <xsl:template match="tet:Pages">
        <!-- Get the unique ID for the font name. -->
        <xsl:variable name="font-id" select="tet:Resources/tet:Fonts/tet:Font[@name = $font-name]/@id" />
        
        <!--
            On all pages select all Words that have at least one Glyph
            sub-element that fulfills the required conditions.
        -->
        <xsl:apply-templates select="tet:Page//tet:Word[tet:Box/tet:Glyph[@font = $font-id and @size > $min-size]]" />
    </xsl:template>
    
    <!--
        Print the fonts for the matching words.
    -->
    <xsl:template match="tet:Word">
        <!-- Produce a list of unique font/size combinations for the word. -->
        <xsl:variable name="font-sets"
                select="tet:Box/tet:Glyph[not(@font = preceding-sibling::tet:Glyph/@font) or not(@size = preceding-sibling::tet:Glyph/@size)]" />

        <xsl:text>[</xsl:text>        
        <xsl:for-each select="$font-sets">
            <xsl:variable name="font-ref" select="@font" />

            <!-- Separate multiple font/size pairs by blanks. -->
            <xsl:if test="position() != 1">
                <xsl:text> </xsl:text>
            </xsl:if>
            
            <!--
                Output the human-readable name of the font, and afterwards
                the font size separated by a slash.
            -->
            <xsl:value-of select="ancestor::tet:Pages[1]//tet:Font[@id = $font-ref]/@name" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="@size" />
        </xsl:for-each>
        <xsl:text>] </xsl:text>
        
        <!--
            Output the Text contents of the Word and terminate with a new-line
            character.
        -->
        <xsl:value-of select="tet:Text" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>
    
</xsl:stylesheet>
