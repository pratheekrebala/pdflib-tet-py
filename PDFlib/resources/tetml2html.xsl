<?xml version="1.0"?>
<!--
           Copyright (c) 2008-2019 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.

    Purpose: convert TETML to HTML
    
    Required input:
        TET TETML in wordplus mode. The script includes information about the
        images for each page. To make the links for the images work
        correctly, the images must be extracted together with TETML. With the
        TET command line tool this can be accomplished like this:
                tet -i -m wordplus <input PDF document>

    Stylesheet parameters:
    
    debug:              0: no debug info, >0: increasingly verbose
    
    bookmark-toc        0: no table of contents generated from PDF bookmarks
                        1: generate table of contents from PDF bookmarks if
                           bookmarks are present
                           
    toc-generate:       0: no table of contents
                        1: generate table of contents for headings recognized
                           by font size and font name, unless a table of
                           contents was generated from bookmarks
    toc-exclude-min, toc-exclude-max:
        Specify a range of pages to exclude from the generation of the HTML
        table of contents. This can be used to prevent duplicate entries if
        also entries in the PDF table of contents are detected as headings
        because of their font size.
    
    h<n>.min-size, h<n>.max-size, h<n>.font-name with n=1..5:
        "Para" elements must include at least one character whose size is greater
        or equal to the h<n>.min-size parameter and less than the
        h<n>.max-size parameter to be recognized as a h1..h5 heading.
        If h<n>.font-name is not the empty string, additionally the font name
        must match.
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0" exclude-result-prefixes="tet"
>

    <xsl:output method="html" indent="yes" />
   
    <xsl:param name="debug">0</xsl:param>

    <xsl:param name="bookmark-toc">1</xsl:param>
    
    <xsl:param name="toc-generate">1</xsl:param>
    <xsl:param name="toc-exclude-min">-1</xsl:param>
    <xsl:param name="toc-exclude-max">-1</xsl:param>
    
    <xsl:param name="h1.min-size">30</xsl:param>
    <xsl:param name="h1.max-size">10000</xsl:param>
    <xsl:param name="h1.font-name">ThesisAntiqua-Bold</xsl:param>

    <xsl:param name="h2.min-size">24</xsl:param>
    <xsl:param name="h2.max-size">30</xsl:param>
    <xsl:param name="h2.font-name" >TheSansExtraLight-Italic</xsl:param>

    <xsl:param name="h3.min-size">14</xsl:param>
    <xsl:param name="h3.max-size">24</xsl:param>
    <xsl:param name="h3.font-name">ThesisAntiqua-Bold</xsl:param>

    <xsl:param name="h4.min-size">8</xsl:param>
    <xsl:param name="h4.max-size">14</xsl:param>
    <xsl:param name="h4.font-name">ThesisAntiqua-Bold</xsl:param>

    <!-- Unused heading level, values set to make matching impossible -->
    <xsl:param name="h5.min-size">10001</xsl:param>
    <xsl:param name="h5.max-size">10000</xsl:param>
    <xsl:param name="h5.font-name" />

    <xsl:variable name="pdf-basename">
        <xsl:call-template name="pdf-basename">
            <xsl:with-param name="full-pdf-name"
                select="/tet:TET/tet:Document/@filename" />
        </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="resources"
        select="/tet:TET/tet:Document/tet:Pages/tet:Resources" />
        
    <xsl:key name="bookmark-by-destination" match="tet:Bookmark" use="@destination" />
    <xsl:key name="destination-by-anchor-id" match="tet:Destination" use="@anchor" />
    <xsl:key name="destination-by-id" match="tet:Destination" use="@id" />
    
    <!-- key for A elements of type 'start' or 'rect' -->
    <xsl:key name="anchor-by-id" match="tet:A[contains('|start|rect|', concat('|', @type, '|'))]" use="@id" />
    
    <xsl:template match="/">
        <!-- Make sure that the input TETML was prepared in wordplus mode including 
            geometry -->
        <xsl:if
            test="tet:TET/tet:Document/tet:Pages/tet:Page/tet:Content[not(@granularity = 'word') or not(@geometry = 'true')]"
        >
            <xsl:message terminate="yes">
                <xsl:text>Stylesheet tetml2html.xsl processing TETML for document '</xsl:text>
                <xsl:value-of select="tet:TET/tet:Document/@filename" />
                <xsl:text>': this stylesheet requires TETML in wordplus mode. </xsl:text>
                <xsl:text>Create the input in page mode "wordplus".</xsl:text>
            </xsl:message>
        </xsl:if>
        
        <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html&gt;</xsl:text>
        
        <html>
            <head>
                <title>
                    <xsl:text>HTML version of </xsl:text>
                    <xsl:value-of select="tet:TET/tet:Document/@filename" />
                </title>
                <style type="text/css">
                    .dropcap { float:left; font-size:88px; line-height:88px;
                    padding-top:3px; padding-right:3px; }
                    <!-- The text-shadow CSS element is not honored by IE -->
                    .shadowed { text-shadow: 2px 2px 3px #000; }
                    h2.toc { text-indent: 20px; }
                    h3.toc { text-indent: 40px; }
                    h4.toc { text-indent: 60px; }
                    h5.toc { text-indent: 80px; }
                    table, td, th { border: 1px solid gray }
                </style>
            </head>
            <body>
                <xsl:choose>
                
                    <xsl:when test="$bookmark-toc > 0 and tet:TET/tet:Document/tet:Bookmarks">
                        <xsl:apply-templates select="tet:TET/tet:Document/tet:Bookmarks" />
                    </xsl:when>
                
                    <xsl:when test="$toc-generate > 0">
                        <xsl:apply-templates
                            select="tet:TET/tet:Document/tet:Pages/tet:Page[not(@number &gt;= $toc-exclude-min and
                                                                            @number &lt;= $toc-exclude-max)]"
                            mode="toc" />
                    </xsl:when>
                
                </xsl:choose>
                
                <xsl:apply-templates select="tet:TET/tet:Document/tet:Pages/tet:Page"
                    mode="body" />
            </body>
        </html>
    </xsl:template>

    <!-- Group of templates for generating the Table of Contents. These templates 
        are all defined with mode "toc". They generate links to anchors for all the Para 
        elements that are identified as headings. -->
    <xsl:template match="tet:Page" mode="toc">
        <xsl:for-each select="tet:Content/tet:Para">
            <xsl:choose>
                <xsl:when
                    test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                                @size &gt;= $h1.min-size
                                        and @size &lt;= $h1.max-size
                                        and ($h1.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h1.font-name]/@id = @font)]"
                >
                    <xsl:call-template name="toc-entry">
                        <xsl:with-param name="toc-heading"
                            select="'h1'" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when
                    test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                                @size &gt;= $h2.min-size
                                        and @size &lt;= $h2.max-size
                                        and ($h2.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h2.font-name]/@id = @font)]"
                >
                    <xsl:call-template name="toc-entry">
                        <xsl:with-param name="toc-heading"
                            select="'h2'" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when
                    test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                                @size &gt;= $h3.min-size
                                        and @size &lt;= $h3.max-size
                                        and ($h3.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h3.font-name]/@id = @font)]"
                >
                    <xsl:call-template name="toc-entry">
                        <xsl:with-param name="toc-heading"
                            select="'h3'" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when
                    test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                                @size &gt;= $h4.min-size
                                        and @size &lt;= $h4.max-size
                                        and ($h4.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h4.font-name]/@id = @font)]"
            >
                    <xsl:call-template name="toc-entry">
                        <xsl:with-param name="toc-heading"
                            select="'h4'" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when
                    test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                                @size &gt;= $h5.min-size
                                        and @size &lt;= $h5.max-size
                                        and ($h5.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h5.font-name]/@id = @font)]"
            >
                    <xsl:call-template name="toc-entry">
                        <xsl:with-param name="toc-heading"
                            select="'h5'" />
                    </xsl:call-template>
                </xsl:when>
                <!-- no xsl:otherwise as normal Paras are suppressed in the TOC -->
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <!-- Generate an entry for the provided Para element as the specified heading 
        element $toc-heading (h1..h5) -->
    <xsl:template name="toc-entry">
        <xsl:param name="toc-heading" />

        <xsl:element name="{$toc-heading}">
            <xsl:attribute name="class"><xsl:text>toc</xsl:text></xsl:attribute>
            <a>
                <xsl:attribute name="href">
                    <xsl:text>#</xsl:text>
                    <xsl:value-of select="generate-id()" />
                </xsl:attribute>
                <xsl:apply-templates select="tet:Box/tet:Word/tet:Text | tet:Word/tet:Text" />
            </a>
        </xsl:element>
    </xsl:template>
    
    <!-- Templates to generate a table of contents from the Bookmarks elements -->
    <xsl:template match="tet:Bookmarks">
        <xsl:apply-templates select="tet:Bookmark" />
    </xsl:template>
    
    <xsl:template match="tet:Bookmark">
        <!-- Determine heading level through distance from Bookmark root. -->
        <xsl:variable name="distance" select="count(ancestor-or-self::tet:Bookmark)" />
        
        <!-- Limit heading levels to 6 according HTML restrictions. -->
        <xsl:variable name="heading-level">
            <xsl:text>h</xsl:text>
            <xsl:choose>
                <xsl:when test="$distance > 6">
                    <xsl:text>6</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$distance" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:element name="{$heading-level}">
            <xsl:attribute name="class">
                <xsl:text>toc</xsl:text>
            </xsl:attribute>
            <a>
                <xsl:variable name="destination" select="key('destination-by-id', @destination)" />
                <xsl:variable name="anchor" select="key('anchor-by-id', $destination/@anchor)" />
              
                <xsl:attribute name="href">
                    <xsl:text>#</xsl:text>
                    <xsl:value-of select="generate-id($anchor)" />
                </xsl:attribute>
                <xsl:value-of select="tet:Title" />
            </a>
        </xsl:element>
        
        <xsl:apply-templates select="tet:Bookmark" />
    </xsl:template>

    <!-- Central functions to recursively iterate over the children of
        Content elements.
        Always change the select statements in process-first-content-child
        and process-content-child-siblings in a consistent manner. --> 
    <xsl:template name="process-first-content-child">
        <!-- Select the first child of the Content element -->
        <xsl:apply-templates select="(tet:Content/tet:Para | tet:Content/tet:Table | tet:Content/tet:List)[1]" />
    </xsl:template>
    
    <xsl:template name="process-content-child-siblings">
        <!-- Select the first sibling of the current Content element child -->
        <xsl:apply-templates select="following-sibling::*[self::tet:Para or self::tet:Table or self::tet:List][1]" />
    </xsl:template>
    
    <!-- Group of templates to generate the text body of the document. The headings 
        are identified in the same manner as in toc mode, only that in this case the anchors 
        are generated through "id" attributes for the h1, h2, ... elements. -->
    <xsl:template match="tet:Page" mode="body">
        <xsl:if test="$debug &gt; 0">
            <hr />
            <i>
                <xsl:text>[Page </xsl:text>
                <xsl:value-of select="@number" />
                <xsl:text> of </xsl:text>
                <xsl:value-of select="ancestor::tet:Document[1]/@filename" />
                <xsl:text>]</xsl:text>
            </i>
            <xsl:apply-templates select="tet:Exception" />
        </xsl:if>

        <xsl:choose>
            <!-- If a Content has Words as direct children, there must not be Para 
                or Table children. Emit the Words as a single paragraph. -->
            <xsl:when test="tet:Content/tet:Word">
                <div>
                    <xsl:apply-templates
                        select="(tet:Content/tet:A | tet:Content/tet:Word)[1]" />
                </div>
            </xsl:when>

            <!-- Otherwise start recursive traversal of Content children -->
            <xsl:otherwise>
                <xsl:call-template name="process-first-content-child" />
            </xsl:otherwise>
        </xsl:choose>

        <xsl:if test=".//tet:PlacedImage">
            <!-- Create an unordered list of images on the page. They can occur at 
                arbitrary nesting depths, e.g. in Lists with nested Lists. -->
            <div>
                <span style="font-style:italic">
                    <xsl:text>Images on page </xsl:text>
                    <xsl:value-of select="@number" />
                    <xsl:text>:</xsl:text>
                </span>
                <ul>
                    <xsl:apply-templates mode="body" select=".//tet:PlacedImage" />
                </ul>
            </div>
        </xsl:if>

    </xsl:template>

    <!-- Print out exceptions in an eye-catching color -->
    <xsl:template match="tet:Exception">
        <div style="color: red">
            <xsl:text>Exception occurred at page level:&#xa;"</xsl:text>
            <xsl:value-of select="." />
            <xsl:text>"</xsl:text>
        </div>
    </xsl:template>

    <!-- Generate a heading element for the provided Para element as the specified 
        heading element $heading-type (h1..h5) -->
    <xsl:template name="heading">
        <xsl:param name="heading-type" />

        <xsl:element name="{$heading-type}">
            <xsl:attribute name="id"><xsl:value-of select="generate-id()" /></xsl:attribute>
            <xsl:apply-templates select="tet:Box/tet:Word/tet:Text | tet:Word/tet:Text" />
        </xsl:element>
    </xsl:template>

    <!-- Recurse to process next Para child -->
    <xsl:template name="process-para-child-siblings">
        <!-- Select the first sibling of the current Content element child -->
        <xsl:apply-templates select="(tet:A | tet:Box/tet:A | tet:Word | tet:Box/tet:Word)[1]" />
    </xsl:template>

    <xsl:template match="tet:Para">
        <xsl:choose>
            <xsl:when
                test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                            @size &gt;= $h1.min-size
                                    and @size &lt; $h1.max-size
                                    and ($h1.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h1.font-name]/@id = @font)]"
            >
                <xsl:element name="h1">
                    <xsl:attribute name="id"><xsl:value-of select="generate-id()" /></xsl:attribute>
                    <xsl:call-template name="process-para-child-siblings" />
                </xsl:element>
            </xsl:when>

            <xsl:when
                test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                            @size &gt;= $h2.min-size
                                    and @size &lt; $h2.max-size
                                    and ($h2.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h2.font-name]/@id = @font)]"
            >
                <xsl:element name="h2">
                    <xsl:attribute name="id"><xsl:value-of select="generate-id()" /></xsl:attribute>
                    <xsl:call-template name="process-para-child-siblings" />
                </xsl:element>
            </xsl:when>

            <xsl:when
                test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                            @size &gt;= $h3.min-size
                                    and @size &lt; $h3.max-size
                                    and ($h3.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h3.font-name]/@id = @font)]"
            >
                <xsl:element name="h3">
                    <xsl:attribute name="id"><xsl:value-of select="generate-id()" /></xsl:attribute>
                    <xsl:call-template name="process-para-child-siblings" />
                </xsl:element>
            </xsl:when>

            <xsl:when
                test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                            @size &gt;= $h4.min-size
                                    and @size &lt; $h4.max-size
                                    and ($h4.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h4.font-name]/@id = @font)]"
            >
                <xsl:element name="h4">
                    <xsl:attribute name="id"><xsl:value-of select="generate-id()" /></xsl:attribute>
                    <xsl:call-template name="process-para-child-siblings" />
                </xsl:element>
            </xsl:when>

            <xsl:when
                test="tet:Box/tet:Word/tet:Box/tet:Glyph[
                            @size &gt;= $h5.min-size
                                    and @size &lt; $h5.max-size
                                    and ($h5.font-name = '' or /tet:TET/tet:Document/tet:Pages/tet:Resources/tet:Fonts/tet:Font[@name = $h5.font-name]/@id = @font)]"
            >
                <xsl:element name="h5">
                    <xsl:attribute name="id"><xsl:value-of select="generate-id()" /></xsl:attribute>
                    <xsl:call-template name="process-para-child-siblings" />
                </xsl:element>
            </xsl:when>

            <xsl:otherwise>
                <div>
                    <xsl:call-template name="process-para-child-siblings" />
                </div>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="process-content-child-siblings" />

    </xsl:template>

    <xsl:template match="tet:List">
        <!-- There may be A anchor elements mixed with Item and PlacedImage elements 
            in the List. As it is not possible to mix HTML anchor elements with <li> elements 
            inside the unordered list and to enclose an <ul> list in an <a> element, find all
            anchor elements that are associated with tet:Bookmark elements, and generate
            HTML anchors before the list -->
        <xsl:variable name="anchor-children" select="(tet:A | tet:Item/tet:A)[@type = 'start']" />
        <xsl:variable name="destinations" select="key('destination-by-anchor-id', $anchor-children/@id)" />
        <xsl:variable name="bookmarks" select="key('bookmark-by-destination', $destinations/@id)" />
            
        <!-- Now we have the bookmarks which are associated with the tet:A elements in the tet:List.
             Work in the opposite direction to finally retrieve a list of all tet:A elements associated
             with those bookmarks. -->
        <xsl:variable name="destinations-with-bookmarks" select="key('destination-by-id', $bookmarks/@destination)" />
        <xsl:variable name="anchor-children-with-bookmarks"
                      select="key('anchor-by-id', $destinations-with-bookmarks/@anchor)" />

        <xsl:for-each select="$anchor-children-with-bookmarks">
            <xsl:element name="a">
                <xsl:attribute name="id">
                    <xsl:value-of select="generate-id(.)" />
                </xsl:attribute>
            </xsl:element>
        </xsl:for-each>
         
        <ul>
            <xsl:apply-templates select="tet:Item" />
        </ul>

        <xsl:call-template name="process-content-child-siblings" />
    </xsl:template>

    <xsl:template match="tet:Item">
        <li>
            <xsl:apply-templates select="tet:Body" />
        </li>
    </xsl:template>
    
    <!-- This starts the recursive iterating over the Body's children -->
    <xsl:template match="tet:Body">
        <xsl:apply-templates select="(tet:Para | tet:Table | tet:List)[1]" />
    </xsl:template>
    
    <xsl:template match="tet:A">
        <xsl:variable name="anchor-id" select="@id" />

        <xsl:if test="$debug > 1">
            <hr />
            <i>
                <xsl:text>A id: </xsl:text>
                <xsl:value-of select="$anchor-id" />
                <xsl:text> type: </xsl:text>
                <xsl:value-of select="@type" />
            </i>
            <hr />
        </xsl:if>
        
        <xsl:choose>
            <!-- Only a 'start' anchor for an URI annotation or for a bookmark destination
                 is relevant at the beginning of a sequence, which can be used to produce a heading
                 with a link. -->
            <xsl:when test="@type = 'start'
                        and (@id = ancestor::tet:Page[1]/tet:Annotations/tet:Annotation[tet:Action[@type = 'URI']]/@anchor
                                or @id = /tet:TET/tet:Document/tet:Destinations/tet:Destination[key('bookmark-by-destination', @id)]/@anchor)">
        
                <xsl:choose>
                    <xsl:when
                        test="(following-sibling::tet:A | following-sibling::tet:Box/tet:A | ../following-sibling::tet:Box/tet:A)[@type = 'stop' and @id = $anchor-id]"
                    >
                        <!-- Found a corresponding 'stop' anchor.  -->
                        <xsl:call-template name="link">
                            <xsl:with-param name="anchor-id" select="$anchor-id" />
                            <xsl:with-param name="link-text"
                             select="(following-sibling::tet:Word | following-sibling::tet:Box/tet:Word | ../following-sibling::tet:Box/tet:Word)
                                        [(following-sibling::tet:A | following-sibling::tet:Box/tet:A | ../following-sibling::tet:Box/tet:A)[@type = 'stop' and @id = $anchor-id][1]]/tet:Text" />
                        </xsl:call-template>
                        
                        <xsl:if test="$debug > 1">
                            <hr />
                            <i>
                                <xsl:text>A id: </xsl:text>
                                <xsl:value-of select="$anchor-id" />
                                <xsl:text> type: </xsl:text>
                                <xsl:value-of select="'stop'" />
                            </i>
                            <hr />
                        </xsl:if>
        
                        <!-- Recurse after the stop anchor. -->
                        <xsl:apply-templates
                                select="((following-sibling::tet:A | following-sibling::tet:Box/tet:A | ../following-sibling::tet:Box/tet:A)
                                                [@type = 'stop' and @id = $anchor-id][1]/following-sibling::*[self::tet:A or self::tet:Word]
                                            | (following-sibling::tet:A | following-sibling::tet:Box/tet:A | ../following-sibling::tet:Box/tet:A)
                                                [@type = 'stop' and @id = $anchor-id][1]/following-sibling::tet:Box/*[self::tet:A or self::tet:Word]
                                            | (following-sibling::tet:A | following-sibling::tet:Box/tet:A | ../following-sibling::tet:Box/tet:A)
                                                [@type = 'stop' and @id = $anchor-id][1]/../following-sibling::tet:Box/*[self::tet:A or self::tet:Word])[1]" />
                    </xsl:when>
                
                    <!-- No corresponding stop anchor. Include text until end of paragraph in link.
                         Then we are done with the paragraph. -->
                    <xsl:otherwise>
                        <xsl:call-template name="link">
                            <xsl:with-param name="anchor-id" select="$anchor-id" />
                            <xsl:with-param name="link-text"
                             select="(following-sibling::tet:Word | following-sibling::tet:Box/tet:Word | ../following-sibling::tet:Box/tet:Word)/tet:Text" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            
            <!-- For an anchor of type "rect" only include a linked self-contained anchor.
                 Then recurse with next Word or A element -->
            <xsl:when test="@type = 'rect'">
                <xsl:element name="a">
                    <xsl:attribute name="id">
                        <xsl:value-of select="generate-id(.)" />
                    </xsl:attribute>
                </xsl:element>
                
                <xsl:apply-templates
                            select="(following-sibling::*[self::tet:A or self::tet:Word]
                                    | following-sibling::tet:Box/*[self::tet:A or self::tet:Word]
                                    | ../following-sibling::tet:Box/*[self::tet:A or self::tet:Word])[1]" />
            </xsl:when>
            
            <!-- Ignore A element, recurse with next Word or A element -->
            <xsl:otherwise>
                <xsl:apply-templates
                        select="(following-sibling::*[self::tet:A or self::tet:Word]
                                | following-sibling::tet:Box/*[self::tet:A or self::tet:Word]
                                | ../following-sibling::tet:Box/*[self::tet:A or self::tet:Word])[1]" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Process the sequence of words before the desired anchor type,
         and recurse with the anchor that terminates the Word sequence -->
    <xsl:template name="process-words-and-anchor">
        <xsl:param name="anchor-type" />
        
        <xsl:variable name="anchor-id"
                select="(following-sibling::tet:A | following-sibling::tet:Box/tet:A)
                                    [@type = $anchor-type
                                            and (@id = ancestor::tet:Page[1]/tet:Annotations/tet:Annotation[tet:Action[@type = 'URI']]/@anchor
                                                    or @id = /tet:TET/tet:Document/tet:Destinations/tet:Destination[key('bookmark-by-destination', @id)]/@anchor)][1]/@id" />

        <xsl:variable name="unique-anchor-id"
            select="generate-id((following-sibling::tet:A | following-sibling::tet:Box/tet:A | ../following-sibling::tet:Box/tet:A)[@type = $anchor-type and @id = $anchor-id][1])" />

        <!-- Process Text elements of Words before the anchor -->
        <xsl:apply-templates
            select="(. | following-sibling::tet:Word | following-sibling::tet:Box/tet:Word | ../following-sibling::tet:Box/tet:Word)
                                        [following-sibling::tet:A[generate-id() = $unique-anchor-id] or ../following-sibling::tet:Box/tet:A[generate-id() = $unique-anchor-id]]/tet:Text" />

        <!-- Recurse with anchor -->
        <xsl:apply-templates
            select="(following-sibling::tet:A | following-sibling::tet:Box/tet:A | ../following-sibling::tet:Box/tet:A)
                                [@type = $anchor-type
                                        and (@id = ancestor::tet:Page[1]/tet:Annotations/tet:Annotation[tet:Action[@type = 'URI']]/@anchor
                                                or @id = /tet:TET/tet:Document/tet:Destinations/tet:Destination[key('bookmark-by-destination', @id)]/@anchor)][1]" />
    </xsl:template>
    
    <xsl:template match="tet:Word">

        <xsl:if test="$debug > 1">
            <hr />
            <i>
                <xsl:text>Word: </xsl:text>
                <xsl:value-of select="tet:Text" />
            </i>
            <hr />
        </xsl:if>

        <xsl:choose>

            <!-- If we have a word sequence before a 'start' anchor, process the Words and recurse with the anchor. -->
            <xsl:when
                test="(following-sibling::tet:A | following-sibling::tet:Box/tet:A | ../following-sibling::tet:Box/tet:A)
                                        [@id = ancestor::tet:Page[1]/tet:Annotations/tet:Annotation[tet:Action[@type = 'URI']]/@anchor
                                                or @id = /tet:TET/tet:Document/tet:Destinations/tet:Destination[key('bookmark-by-destination', @id)]/@anchor][1]/@type = 'start'"
            >
                <xsl:call-template name="process-words-and-anchor">
                    <xsl:with-param name="anchor-type" select="'start'" />
                </xsl:call-template>
            </xsl:when>

            <!-- If we have a word sequence before a 'rect' anchor, process the Words and recurse with the anchor. -->
            <xsl:when
                test="(following-sibling::tet:A | following-sibling::tet:Box/tet:A | ../following-sibling::tet:Box/tet:A)
                                        [@id = ancestor::tet:Page[1]/tet:Annotations/tet:Annotation[tet:Action[@type = 'URI']]/@anchor
                                                or @id = /tet:TET/tet:Document/tet:Destinations/tet:Destination[key('bookmark-by-destination', @id)]/@anchor][1]/@type = 'rect'"
            >
                <xsl:call-template name="process-words-and-anchor">
                    <xsl:with-param name="anchor-type" select="'rect'" />
                </xsl:call-template>
            </xsl:when>
            
            <!-- Otherwise there's a trailing sequence of Words that terminates the paragraph. -->
            <xsl:otherwise>
                <xsl:apply-templates
                    select="(. | following-sibling::tet:Word | following-sibling::tet:Box/tet:Word | ../following-sibling::tet:Box/tet:Word)/tet:Text" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- To be called with the current element being an A element. This
         generates an HTML <a> element with either a href attribute for a
         URI link or with an "id" attribute if this is an anchor for a
         bookmark reference. -->
    <xsl:template name="link">
        <xsl:param name="anchor-id" />
        <xsl:param name="link-text" />

        <xsl:if test="$debug > 1">
            <hr />
            <i>
                <xsl:text>Link for A id: </xsl:text>
                <xsl:value-of select="$anchor-id" />
                <xsl:text> word count: </xsl:text>
                <xsl:value-of select="count($link-text)" />
            </i>
            <hr />
        </xsl:if>
                        
        <xsl:if test="count($link-text)">
            <xsl:text> </xsl:text>
            
            <!-- Check that anchor has at least one tet:Destination associated to which at least
                 one tet:Bookmark points -->
            <xsl:variable name="destinations" select="key('destination-by-anchor-id', $anchor-id)" />
            <xsl:variable name="destination-bookmarks" select="key('bookmark-by-destination', $destinations/@id)" />
            
            <xsl:choose>
            
                <xsl:when test="$destination-bookmarks">
                
                    <!-- Determine heading level through distance from Bookmark root. As there can be multiple bookmarks,
                         use the first selected one -->
                    <xsl:variable name="distance" select="count($destination-bookmarks[1]/ancestor-or-self::tet:Bookmark)" />
                    
                    <!-- Limit heading levels to 6 according HTML restrictions. -->
                    <xsl:variable name="heading-level">
                        <xsl:text>h</xsl:text>
                        <xsl:choose>
                            <xsl:when test="$distance > 6">
                                <xsl:text>6</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$distance" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
    
                    <!-- generate HTML anchor with id of the TETML anchor -->
                    <xsl:element name="{$heading-level}">
                        <xsl:element name="a">
                            <xsl:attribute name="id">
                                <xsl:value-of
                                    select="generate-id(.)" />
                            </xsl:attribute>
                            <xsl:apply-templates select="$link-text" />
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
            
                <xsl:when test="ancestor::tet:Page[1]/tet:Annotations/tet:Annotation[@anchor = $anchor-id]/tet:Action/@URI">
                    <xsl:element name="a">
                        <xsl:attribute name="href">
                            <xsl:value-of
                                select="ancestor::tet:Page[1]/tet:Annotations/tet:Annotation[@anchor = $anchor-id]/tet:Action/@URI" />
                        </xsl:attribute>
                        <xsl:apply-templates select="$link-text" />
                    </xsl:element>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:apply-templates select="$link-text" />
                </xsl:otherwise>
                
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tet:Table">
        <table>
            <tbody>
                <xsl:apply-templates select="tet:Row" />
            </tbody>
        </table>
        
        <xsl:call-template name="process-content-child-siblings" />
    </xsl:template>

    <xsl:template match="tet:Row">
        <tr>
            <xsl:apply-templates select="tet:Cell" />
        </tr>
    </xsl:template>

    <!-- Process tables also recursively -->
    <xsl:template match="tet:Cell">
        <td>
            <xsl:if test="@colSpan">
                <xsl:attribute name="colspan">
                    <xsl:value-of select="@colSpan" />
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates
                select="(tet:Para | tet:Table)[1]" />
        </td>
    </xsl:template>

    <!-- Print information about a placed image on the page, together with a link 
        to the actual image. As the images created by TET are mostly not conforming to HTML, 
        we do not put the images inline on the HTML page. -->
    <xsl:template mode="body" match="tet:PlacedImage">
        <xsl:variable name="image-id" select="@image" />
        <xsl:variable name="image-resource"
            select="$resources/tet:Images/tet:Image[@id = $image-id]" />
        <xsl:variable name="image-name"
            select="concat($pdf-basename, '_', $image-id, $image-resource/@extractedAs)" />
        <xsl:variable name="colorspace"
            select="$resources/tet:ColorSpaces/tet:ColorSpace[@id = $image-resource/@colorspace]" />
        <li>
            <a>
                <xsl:attribute name="href">
                        <xsl:value-of select="$image-name" />
                </xsl:attribute>
                <xsl:value-of select="$image-id" />
            </a>

            <xsl:text>: Dimensions </xsl:text>
            <xsl:value-of select="$image-resource/@width" />
            <xsl:text>x</xsl:text>
            <xsl:value-of select="$image-resource/@height" />

            <xsl:text>, </xsl:text>
            <xsl:value-of select="$image-resource/@bitsPerComponent" />
            <xsl:text> bits per component, colorspace '</xsl:text>
            <xsl:value-of select="$colorspace/@name" />
            <xsl:text>' with </xsl:text>
            <xsl:value-of select="$colorspace/@components" />
            <xsl:text> component(s)</xsl:text>
        </li>
    </xsl:template>

    <xsl:template match="tet:Text">
        <xsl:text> </xsl:text>
        
        <!-- Detect and output some text formatting options.
        
             The first character of a word is output with a dropcap style if
             the first character has the "dropcap"  attribute set to true.
             
             A whole word is output with a shadowed style if any character has
             the "shadow" attribute set to true. And finally a word can be
             output as superscript or subscript if any character has the
             corresponding "sup" or "sub" attribute set to true. As not both
             superscript and subscript can be active at the same time,
             superscript is arbitrarily choosen as having precedence.
        -->
        <xsl:variable name="dropcapped">
            <xsl:choose>
                <xsl:when
                    test="following-sibling::tet:Box/tet:Glyph[1][@dropcap = 'true']"
                >
                    <span class="dropcap">
                        <xsl:value-of select="substring(., 1, 1)" />
                    </span>
                    <xsl:value-of select="substring(., 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="." />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="shadowed">
            <xsl:choose>
                <xsl:when
                    test="following-sibling::tet:Box/tet:Glyph[@shadow = 'true']"
                >
                    <span class="shadowed">
                        <xsl:copy-of select="$dropcapped" />
                    </span>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$dropcapped" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="following-sibling::tet:Box/tet:Glyph[@sup = 'true']">
                <sup>
                    <xsl:copy-of select="$shadowed" />
                </sup>
            </xsl:when>
            <xsl:when test="following-sibling::tet:Box/tet:Glyph[@sub = 'true']">
                <sub>
                    <xsl:copy-of select="$shadowed" />
                </sub>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$shadowed" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Retrieve the basename of the PDF document. The assumption is that it has 
        a four-character ".pdf" suffix that is stripped off. Then the string behind the last 
        "/" or "\" is taken -->
    <xsl:template name="pdf-basename">
        <xsl:param name="full-pdf-name" />
        <xsl:variable name="slash-normalized" select="translate($full-pdf-name, '\\', '/')" />
        <xsl:variable name="suffix-stripped"
            select="substring($slash-normalized, 0, string-length($slash-normalized) - 3)" />
        <xsl:call-template name="strip-dirs">
            <xsl:with-param name="path" select="$suffix-stripped" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="strip-dirs">
        <xsl:param name="path" />
        <xsl:variable name="rest" select="substring-after($path, '/')" />
        <xsl:choose>
            <xsl:when test="string-length($rest) = 0">
                <xsl:value-of select="$path" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="strip-dirs">
                    <xsl:with-param name="path" select="$rest" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
