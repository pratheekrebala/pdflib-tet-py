<?xml version="1.0" encoding="UTF-8"?>
<!--
           Copyright (c) 2008-2019 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.

    Purpose: Create an alphabetically sorted "back-of-the-book" index
    
    Required input: TETML in "word" or "wordplus" mode.
    
    Stylesheet parameters: none
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0"
>
    <xsl:output method="text" />
    
    <!-- Minimum word length for inclusion in index -->
    <xsl:param name="min-length">4</xsl:param>
    
    <!--
        Index required by the "Muenchian" method. We index the Word elements
        based on the content of the Text subelements.
    -->
    <xsl:key name="words" match="tet:TET/tet:Document/tet:Pages//tet:Word" use="tet:Text" />
    
    <!-- Characters that may appear at the beginning of a word -->
    <xsl:variable name="allowed-chars"
        select="'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvw'" />
        
    <!--
        Index for the unique letters 
    -->
    <xsl:key name="letter" match="tet:TET/tet:Document/tet:Pages//tet:Word"
        use="translate(substring(tet:Text,1,1), 
                        'abcdefghijklmnopqrstuvwxyz', 
                        'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                        
    <xsl:template match="/">
	<!-- Make sure that word information is present in the input TETML. -->
	<xsl:if test="tet:TET/tet:Document/tet:Pages//tet:Content[not(@granularity = 'word')]">
		<xsl:message terminate="yes">
			<xsl:text>Stylesheet index.xsl processing TETML for document '</xsl:text>
			<xsl:value-of select="tet:TET/tet:Document/@filename" />
			<xsl:text>': this stylesheet requires word info in TETML. </xsl:text>
			<xsl:text>Create the input in page mode "word" or "wordplus".</xsl:text>
		</xsl:message>
	</xsl:if>

        <xsl:text>Alphabetical list of words in the document along with their page number:&#xa;&#xa;</xsl:text>
        
        <!--
            Group by first letter, sort by first letter. 
        -->
        <xsl:apply-templates
            select="tet:TET/tet:Document/tet:Pages//tet:Word[generate-id() =
                                generate-id(key('letter',
                                 translate(substring(tet:Text,1,1), 
                                   'abcdefghijklmnopqrstuvwxyz', 
                                   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'))[1])]"
            mode="index-letters">
            <xsl:sort
                select="translate(tet:Text, 'abcdefghijklmnopqrstuvwxyz', 
                               'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
        </xsl:apply-templates>
    </xsl:template>
    
    
    <xsl:template match="tet:Word" mode="index-letters">
        <!-- Get the group key -->
        <xsl:variable name="key"
            select="translate(substring(tet:Text, 1, 1),
                                      'abcdefghijklmnopqrstuvwxyz', 
                                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    
        <!-- Suppress groups that are not in the allowed set of characters -->
        <xsl:if test="string-length(translate($key, $allowed-chars, '')) = 0">
        
            <!-- Select all words that start with the current group letter -->
            <xsl:variable name="letter-group"
                select="key('letter', $key)
                   [generate-id() = generate-id(key('words', tet:Text)[1])]" />
    
            <!--
                Filter out words that are not long enough or that start with
                a disallowed character.
            -->
            <xsl:variable name="allowed-words"
                select="$letter-group[string-length(tet:Text) &gt;= $min-length and
                               string-length(translate(substring(tet:Text, 1, 1), $allowed-chars, '')) = 0]"/>
            
            <!-- Suppress empty groups -->
            <xsl:if test="count($allowed-words) &gt; 0">
                <!-- Output label for current index group -->
                <xsl:value-of select="$key" />
                <xsl:text>&#xa;</xsl:text>
            
                <xsl:apply-templates select="$allowed-words" mode="index-words">
                    <xsl:sort
                        select="translate(tet:Text, 
                                            'abcdefghijklmnopqrstuvwxyz',
                                            'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                </xsl:apply-templates>
                <xsl:text>&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tet:Word" mode="index-words">
        <!-- Find all occurences of index term -->
        <xsl:variable name="occurences" select="key('words', tet:Text)" />
    
        <!-- Output text of index term -->
        <xsl:value-of select="tet:Text" />
        <xsl:text> </xsl:text>
        
        <!-- Output page numbers where the term occurs -->
        <xsl:for-each select="$occurences/ancestor::tet:Page">
            <!-- Separate multiple page numbers by blanks -->
            <xsl:if test="position() != 1">
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:value-of select="@number" />
        </xsl:for-each>
        
        <!-- Terminate word entry with new-line -->
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>
</xsl:stylesheet>
