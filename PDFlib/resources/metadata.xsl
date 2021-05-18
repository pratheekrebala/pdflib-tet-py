<?xml version="1.0" encoding="UTF-8"?>
<!--
           Copyright (c) 2008-2019 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.

    Purpose: Extract selected fields from document-level XMP metadata from TETML
    for the document and all nested attachments.
    
    Required input: TETML in any mode.
    
    Stylesheet parameters: none
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xmp="http://ns.adobe.com/xap/1.0/"
    xmlns:x="adobe:ns:meta/"
>
    <xsl:output method="text" />
    
    <xsl:template match="/">
        <xsl:apply-templates select="tet:TET/tet:Document" />
    </xsl:template>

    <xsl:template match="tet:TET/tet:Document">
        <xsl:call-template name="extract-metadata">
            <xsl:with-param name="metadata-node" select="tet:Metadata" />
        </xsl:call-template>

        <!-- Recurse into attachments -->
        <xsl:apply-templates select="tet:Attachments/tet:Attachment/tet:Document" />
    </xsl:template>

    <xsl:template match="tet:Attachment/tet:Document">
        <xsl:variable name="attachment-id">
            <xsl:text>attachment: </xsl:text>
            <xsl:value-of select="@filename" />
            <xsl:text> level: </xsl:text>
            <xsl:value-of select="../@level" />
        </xsl:variable>

        <xsl:text>--- begin </xsl:text>
        <xsl:value-of select="$attachment-id" />
        <xsl:text> ---&#xa;</xsl:text>
        
        <xsl:call-template name="extract-metadata">
            <xsl:with-param name="metadata-node" select="tet:Metadata" />
        </xsl:call-template>
        <xsl:apply-templates select="tet:Attachments/tet:Attachment/tet:Document" />
        
        <xsl:text>--- end </xsl:text>
        <xsl:value-of select="$attachment-id" />
        <xsl:text> ---&#xa;</xsl:text>
    </xsl:template>
    
    <xsl:template name="extract-metadata">
        <xsl:param name="metadata-node" />
        
        <!--
            Check for presence of exception that indicates invalid metadata.
            The corresponding template will terminate with an error message
            if an exception is detected.
        -->
        <xsl:apply-templates select="$metadata-node/tet:Exception" />
        
        <!-- Report an empty Metadata element -->
        <xsl:if test="count($metadata-node/*) = 0">
            <xsl:text>No metadata found in document "</xsl:text>
            <xsl:value-of select="@filename" />
            <xsl:text>"&#xa;</xsl:text>
        </xsl:if>
        
        <!--
            According to the XMP specification there could be either an xmpmeta
            or an xapmeta element as the root of the XMP metadata tree.
        -->
        <xsl:apply-templates select="$metadata-node/*/rdf:RDF" />
    </xsl:template>
    
    <!--
        Extract the desired properties from the XMP RDF element. 
    -->
    <xsl:template match="rdf:RDF">
        <!--
            Extract Dublin Core property "creator" from XMP.
        -->
        <xsl:apply-templates select="rdf:Description/dc:creator" />
        
        <!--
            Extract XMP Basic property "CreatorTool" from XMP. We account for
            the two possible RDF notations for the properties, either as nested
            element inside the rdf:Description element or as an attribute
            of the rdf:Description element.
        -->
        <xsl:apply-templates select="rdf:Description/xmp:CreatorTool | rdf:Description/@xmp:CreatorTool" />
    </xsl:template>
    
    <xsl:template match="rdf:Description/dc:creator">
        <!-- dc:creator is defined as a sequence -->
        <xsl:text>dc:creator = </xsl:text>
            <xsl:apply-templates select="rdf:Seq/rdf:li" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>
    
    <!--
        Output members of the sequence, separated by commas. 
    -->
    <xsl:template match="rdf:li">
        <xsl:if test="position() > 1">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:value-of select="." />
    </xsl:template>
    
    <xsl:template match="rdf:Description/xmp:CreatorTool | rdf:Description/@xmp:CreatorTool">
        <xsl:text>xmp:CreatorTool = </xsl:text>
        <xsl:value-of select="." />
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>
    
    <!--
        Print out an error message and the contents of the exception
    -->
    <xsl:template match="tet:Exception">
        <xsl:text>Invalid metadata found in document "</xsl:text>
        <xsl:value-of select="../../@filename" />
        <xsl:text>", exception text is:&#xa;"</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>"&#xa;</xsl:text>
    </xsl:template>
</xsl:stylesheet>
