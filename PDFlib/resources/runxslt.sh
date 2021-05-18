#!/bin/sh
#
# Shell script for applying XSLT stylesheets to TETML output
# via the xsltproc command-line program.

XSLTPROC=xsltproc
TETEXE=../../bin/tet
PDFFILE=../data/TET-datasheet.pdf
PBTETML=TET-datasheet.pb.tetml
NOPBTETML=TET-datasheet.nopb.tetml

if [ ! -f "$PBTETML" -o "$PBTETML" -ot "$PDFFILE" ]
then
        "$TETEXE" --tetml wordplus --image -o "$PBTETML" "$PDFFILE"
fi

if [ ! -f "$NOPBTETML" -o "$NOPBTETML" -ot "$PDFFILE" ]
then
        "$TETEXE" --tetml wordplus --image \
                --pageopt 'contentanalysis={punctuationbreaks=false}' \
                -o "$NOPBTETML" "$PDFFILE"
fi

$XSLTPROC --output TET-datasheet.concordance.txt concordance.xsl "$PBTETML"
$XSLTPROC --output TET-datasheet.index.txt index.xsl "$PBTETML"
$XSLTPROC --output TET-datasheet.table.csv table.xsl "$PBTETML"
$XSLTPROC --output TET-datasheet.textonly.txt textonly.xsl "$NOPBTETML"
$XSLTPROC --output TET-datasheet.metadata.txt metadata.xsl "$PBTETML"
$XSLTPROC --output TET-datasheet.fontfilter.txt fontfilter.xsl "$PBTETML"
$XSLTPROC --output TET-datasheet.fontstat.txt fontstat.xsl "$PBTETML"
$XSLTPROC --output TET-datasheet.fontfinder.txt fontfinder.xsl "$PBTETML"
$XSLTPROC --output TET-datasheet.tetml2html.html tetml2html.xsl "$NOPBTETML"
