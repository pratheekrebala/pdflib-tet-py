<?xml version="1.0" encoding="UTF-8"?>
<!--
           Copyright (c) 2008-2019 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.

    Purpose: Extract a table to CSV file (comma-separated values).
    
    Required input: TETML in "word", "wordplus", or "page" mode.
    
    Stylesheet parameters:
    page-number:	The number of the page in the document where the desired
			table is located. If this is 0, the parameter $table-number
			is interpreted as the absolute number of the desired table
			in the document. Default: 0
    table-number:	The number of the table in the document or, if parameter
    			$page-number is greater than zero, the number of the table
    			on the selected page. Default: 1
    separator-char:	Character to use as field separator. Default: comma
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0">
    <xsl:output method="text" />
    
    <!-- Number of the target page -->
    <xsl:param name="page-number" select="0" />
    
    <!-- Number of the table in the document or on the page -->
    <xsl:param name="table-number" select="1" />
    
    <!--  Separator character -->
    <xsl:param name="separator-char" select="','" />
    
    <!-- The double quote as a variable, to avoid quoting confusion. -->
    <xsl:variable name="double-quote">"</xsl:variable>
    
    <xsl:template match="/">
	<!-- Make sure that word information is present in the input TETML. -->
	<xsl:if test="tet:TET/tet:Document/tet:Pages/tet:Page/tet:Content[not(@granularity = 'word' or @granularity= 'page')]">
		<xsl:message terminate="yes">
			<xsl:text>Stylesheet table.xsl processing TETML for document '</xsl:text>
			<xsl:value-of select="tet:TET/tet:Document/@filename" />
			<xsl:text>': this stylesheet requires word info in TETML. </xsl:text>
			<xsl:text>Create the input in page mode "word" or "wordplus".</xsl:text>
		</xsl:message>
	</xsl:if>
	
        <xsl:choose>
            <xsl:when test="$page-number = 0">
                <!-- Select the table that has number $table-number. -->
                <xsl:variable name="table" select="(tet:TET/tet:Document/tet:Pages/tet:Page//tet:Table)[$table-number]"/>
                <xsl:if test="count($table) = 0">
                    <xsl:call-template name="table-not-found" />
                </xsl:if>
                <xsl:apply-templates select="$table"/>
            </xsl:when>
            <xsl:otherwise>
                <!--
                    Select the page with page number $page-number, and on that
                    page select the table that has number $table-number.
                -->
                <xsl:variable name="table" select="(tet:TET/tet:Document/tet:Pages/tet:Page[@number = $page-number]//tet:Table)[$table-number]"/>
                <xsl:if test="count($table) = 0">
                    <xsl:call-template name="table-not-found" />
                </xsl:if>
                <xsl:apply-templates select="$table"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tet:Table">
        <xsl:apply-templates select="tet:Row"/>
    </xsl:template>
    
    <xsl:template match="tet:Row">
        <xsl:for-each select="tet:Cell">
            <!--
                Join all Text children of the Cell into a string variable
                separated by blanks
            -->
            <xsl:variable name="text">
                <xsl:for-each select=".//tet:Text">
                    <xsl:if test="position() != 1">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="." />
                </xsl:for-each>
            </xsl:variable>
            
            <!-- Suppress output of a separator char for the first cell in a row. -->
            <xsl:if test="position() != 1">
                <xsl:value-of select="$separator-char"/>
            </xsl:if>
            
            <!-- Output leading double quote if there are special characters in the cell -->
            <xsl:if test="contains($text, $double-quote) or contains($text, $separator-char) or contains($text, '&#xa;')">
                <xsl:value-of select="$double-quote"/>
            </xsl:if>

            <xsl:call-template name="escape-quotes">
                <xsl:with-param name="input" select="$text"/>
            </xsl:call-template>

            <xsl:if test="contains($text, $double-quote) or contains($text, $separator-char) or contains($text, '&#xa;')">
                <xsl:value-of select="$double-quote"/>
            </xsl:if>
            
            <!--
                If there is a colSpan attribute, emit empty columns accordingly,
                as colSpan can't be expressed in CSV files.
            -->
            <xsl:if test="@colSpan">
                <xsl:call-template name="empty-cells">
                        <xsl:with-param name="count" select="number(@colSpan) - 1"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>
    
    <!-- Recursive template to output the separator for creating empty cells. -->
    <xsl:template name="empty-cells">
        <xsl:param name="count"/>
        
        <xsl:value-of select="$separator-char"/>
        
        <xsl:if test="$count - 1 &gt; 0">
            <xsl:call-template name="empty-cells">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- Recursive template to escape double quotes in the input string. -->
    <xsl:template name="escape-quotes">
        <xsl:param name="input"/>
        
        <!--
            Test if the input string contains a double quote. If yes, process
            the string before the double quote, output two double quotes, and
            process the rest of the string. If no, we are finished.
        -->
        <xsl:choose>
            <xsl:when test="contains($input, $double-quote)">
                <xsl:value-of select="substring-before($input, $double-quote)"/>
                <xsl:value-of select="$double-quote"/>
                <xsl:value-of select="$double-quote"/>
                <xsl:call-template name="escape-quotes">
                    <xsl:with-param name="input" select="substring-after($input, $double-quote)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="table-not-found">
        <xsl:message>
            <xsl:text>No table was found with the parameters:&#xa;</xsl:text>
            <xsl:text>page-number=</xsl:text><xsl:value-of select="$page-number" />
            <xsl:text>, table-number=</xsl:text><xsl:value-of select="$table-number" />
            <xsl:text>&#xa;</xsl:text>
        </xsl:message>
    </xsl:template>
</xsl:stylesheet>
