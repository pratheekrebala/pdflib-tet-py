<?xml version="1.0" encoding="UTF-8"?>
<!--
           Copyright (c) 2008-2015 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.


    Purpose: Create a concordance, i.e. a list of unique words in a
    document sorted by descending frequency
    
    Expected input: TETML in "word" or "wordplus" mode.
    
    Stylesheet parameters: none
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0">
    <xsl:output method="text"/>
    
    <!-- Characters that may appear at the beginning of a word -->
    <xsl:variable name="allowed-chars"
        select="'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvw'" />
        
    <!--  Index required by the "Muenchian" method. -->
    <xsl:key name="text-elements" match="tet:Text" use="."/>

    <xsl:template match="/">
	<!-- Make sure that word information is present in the input TETML. -->
	<xsl:if test="tet:TET/tet:Document/tet:Pages/tet:Page/tet:Content[not(@granularity = 'word')]">
		<xsl:message terminate="yes">
			<xsl:text>Stylesheet concordance.xsl processing TETML for document '</xsl:text>
			<xsl:value-of select="tet:TET/tet:Document/@filename" />
			<xsl:text>': this stylesheet requires font info in TETML. </xsl:text>
			<xsl:text>Create the input in page mode "word" or "wordplus".</xsl:text>
		</xsl:message>
	</xsl:if>

        <xsl:text>List of words in the document along with the number of occurrences:&#xa;&#xa;</xsl:text>
        
        <!--
            With the "Muenchian" method, generate a list of unique words in the
            document. Filter out all words that do not start with one of
            the characters contained in the $allowed-chars variable.
        -->
        <xsl:variable name="unique-words"
            select="tet:TET/tet:Document/tet:Pages//tet:Text[generate-id() = generate-id(key('text-elements', .)[1])
                    and string-length(translate(substring(., 1, 1), $allowed-chars, '')) = 0]" />

        <xsl:for-each select="$unique-words">
            <!-- Sort numerically descending according to the frequency. -->
            <xsl:sort select="count(key('text-elements', .))" 
                data-type="number" order="descending"/>

            <!-- Output the keyword. -->
            <xsl:value-of select="." />
            <xsl:text> </xsl:text>
            
            <!-- Output the number of times the keyword appears. -->
            <xsl:value-of select="count(key('text-elements', .))" />
            
            <!-- Terminate with a newline character. -->
            <xsl:text>&#xa;</xsl:text>
        </xsl:for-each>

        <xsl:text>&#xa;Total unique words: </xsl:text>
        <xsl:value-of select="count($unique-words)" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>
</xsl:stylesheet>
