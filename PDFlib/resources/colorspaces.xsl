<?xml version="1.0" encoding="UTF-8"?>
<!--
           Copyright (c) 2008-2015 PDFlib GmbH. All rights reserved.
    This software may not be copied or distributed except as expressly
    authorized by PDFlib GmbH's general license agreement or a custom
    license agreement signed by PDFlib GmbH.
    For more information about licensing please refer to www.pdflib.com.

    Purpose: Create a listing of all colorspaces used in the document.
    
    Expected input: TETML in "glyph", "word" or "wordplus" mode.
    
    Stylesheet parameters: none
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tet="http://www.pdflib.com/XML/TET5/TET-5.0"
>
    <xsl:output method="text"/>

    <xsl:template match="/">

        <xsl:text>List of colorspaces in the document:&#xa;&#xa;</xsl:text>

        <xsl:value-of
            select="count(tet:TET/tet:Document/tet:Pages/tet:Resources/tet:ColorSpaces/tet:ColorSpace)"/>
        <xsl:text> colorspaces:&#xa;</xsl:text>
        
        <!-- Dump all colorspaces -->
        <xsl:apply-templates select="tet:TET/tet:Document/tet:Pages/tet:Resources/tet:ColorSpaces/tet:ColorSpace">
            <xsl:with-param name="indentation" select="2" />
        </xsl:apply-templates>

    </xsl:template>

    <xsl:template match="tet:ColorSpace">
        <xsl:param name="indentation" />
        
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="$indentation" />
        </xsl:call-template>
        
        <!-- Type of colorspace -->
        <xsl:value-of select="@name"/>
        <xsl:text>&#xa;</xsl:text>

        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="$indentation + 2" />
        </xsl:call-template>
        
        <!-- Number of components -->
        <xsl:choose>
            <xsl:when test="@components = 1">
                <xsl:text>1 component&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@components" />
                <xsl:text> components&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>

        <!-- Colorspace-specific information -->
        <xsl:choose>
            <xsl:when test="@name = 'Lab' or @name = 'CalGray' or @name = 'CalRGB'">
                <xsl:call-template name="blanks">
                    <xsl:with-param name="count" select="$indentation + 2" />
                </xsl:call-template>
                
                <xsl:text>white point x=</xsl:text>
                <xsl:value-of select="tet:WhitePoint/@x" />
                
                <xsl:text> y=</xsl:text>
                <xsl:value-of select="tet:WhitePoint/@y" />
                
                <xsl:text> z=</xsl:text>
                <xsl:value-of select="tet:WhitePoint/@z" />
                <xsl:text>&#xa;</xsl:text>
            </xsl:when>
            
            <xsl:when test="@name = 'Separation'">
                <xsl:call-template name="blanks">
                    <xsl:with-param name="count" select="$indentation + 2" />
                </xsl:call-template>
                
                <xsl:text>colorant "</xsl:text>
                <xsl:value-of select="tet:Colorant/@name" />
                <xsl:text>"&#xa;</xsl:text>
                
                <xsl:call-template name="blanks">
                    <xsl:with-param name="count" select="$indentation + 2" />
                </xsl:call-template>
                
                <xsl:text>alternate color space:&#xa;</xsl:text>
                <xsl:apply-templates select="../tet:ColorSpace[@id = current()/@alternate]">
                    <xsl:with-param name="indentation" select="$indentation + 4" />
                </xsl:apply-templates>
            </xsl:when>
            
            <xsl:when test="@name = 'DeviceN'">
                <xsl:call-template name="blanks">
                    <xsl:with-param name="count" select="$indentation + 2" />
                </xsl:call-template>
                
                <xsl:text>colorants:&#xa;</xsl:text>
                <xsl:for-each select="tet:Colorant">
                    <xsl:call-template name="blanks">
                        <xsl:with-param name="count" select="$indentation + 4" />
                    </xsl:call-template>
                    
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="@name" />
                    <xsl:text>"&#xa;</xsl:text>
                </xsl:for-each>
                
                <xsl:call-template name="blanks">
                    <xsl:with-param name="count" select="$indentation + 2" />
                </xsl:call-template>
                
                <xsl:text>alternate color space:&#xa;</xsl:text>
                <xsl:apply-templates select="../tet:ColorSpace[@id = current()/@alternate]">
                    <xsl:with-param name="indentation" select="$indentation + 4" />
                </xsl:apply-templates>
            </xsl:when>
            
            <xsl:when test="@name = 'Indexed'">
                <xsl:call-template name="blanks">
                    <xsl:with-param name="count" select="$indentation + 2" />
                </xsl:call-template>
                
                <xsl:text>base color space:&#xa;</xsl:text>
                
                <xsl:apply-templates select="../tet:ColorSpace[@id = current()/@base]">
                    <xsl:with-param name="indentation" select="$indentation + 4" />
                </xsl:apply-templates>
            </xsl:when>
            
            <xsl:when test="@name = 'ICCBased'">
                <xsl:call-template name="blanks">
                    <xsl:with-param name="count" select="$indentation + 2" />
                </xsl:call-template>
                
                <xsl:text>ICC profile information:&#xa;</xsl:text>
                
                <xsl:apply-templates select="../../../tet:Graphics/tet:ICCProfiles/tet:ICCProfile[@id = current()/@iccprofile]">
                    <xsl:with-param name="indentation" select="$indentation + 4" />
                </xsl:apply-templates>
            </xsl:when>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- Dump ICC profile information -->
    <xsl:template match="tet:ICCProfile">
        <xsl:param name="indentation" />
        
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="$indentation" />
        </xsl:call-template>
        
        <xsl:text>profile name "</xsl:text>
            <xsl:value-of select="@profilename" />
        <xsl:text>"&#xa;</xsl:text>
        
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="$indentation" />
        </xsl:call-template>
        
        <xsl:text>device class "</xsl:text>
            <xsl:value-of select="@deviceclass" />
        <xsl:text>"&#xa;</xsl:text>
        
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="$indentation" />
        </xsl:call-template>
        
        <xsl:text>version "</xsl:text>
            <xsl:value-of select="@iccversion" />
        <xsl:text>"&#xa;</xsl:text>
        
        <xsl:call-template name="blanks">
            <xsl:with-param name="count" select="$indentation" />
        </xsl:call-template>
        
        <xsl:text>profile colorspace "</xsl:text>
            <xsl:value-of select="@profilecs" />
        <xsl:text>"&#xa;</xsl:text>
        
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
