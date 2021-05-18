# PowerShell script to run TET XSLT samples with the .NET XSLT engine
#
# usage: powershell runxslt.ps1 [ <input file> <stylesheet> <output file> [ { <param name> <param value> } ... ] ]
#
# If the script is invoked without arguments, it will run all the samples.
# If the script is invoked with the arguments <input file>, <stylesheet> and
# <output file>, the script will run the given stylesheet for the input file
# and write the results to the output file. Stylesheet parameters can be
# provided as pairwise arguments at the end of the command line.

# Array of arrays to describe the default execution without stylesheet parameters 
$script:runs =
    ("TET-datasheet.pb.tetml", "concordance.xsl", "TET-datasheet.concordance.txt"),
    ("TET-datasheet.pb.tetml", "index.xsl", "TET-datasheet.index.txt"),
    ("TET-datasheet.pb.tetml", "table.xsl", "TET-datasheet.table.csv"),
    ("TET-datasheet.nopb.tetml", "textonly.xsl", "TET-datasheet.textonly.txt"),
    ("TET-datasheet.pb.tetml", "metadata.xsl", "TET-datasheet.metadata.txt"),
    ("TET-datasheet.pb.tetml", "fontfilter.xsl", "TET-datasheet.fontfilter.txt"),
    ("TET-datasheet.pb.tetml", "fontstat.xsl", "TET-datasheet.fontstat.txt"),
    ("TET-datasheet.pb.tetml", "fontfinder.xsl", "TET-datasheet.fontfinder.txt"),
    ("TET-datasheet.nopb.tetml", "tetml2html.xsl", "TET-datasheet.tetml2html.html")

$script:xslt = new-object System.Xml.Xsl.XslTransform

function runXslt($inputXml, $xsl, $outputFile, $params)
{
    Write-Output ("Transforming input file `"" + $inputXml +  "`" with stylesheet `"" +
                $xsl + "`" to output file `"" + $outputFile + "`"")
                
    $inputXml = Resolve-Path $inputXml
    $xsl = Resolve-Path $xsl
    $outputFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($pwd.ToString(), $outputFile))
              
    # prepare stylesheet parameters
    $private:argList = New-Object System.Xml.Xsl.XsltArgumentList
    
    $private:i
    for ($i = 0; $i -lt $params.length; $i += 2)
    {
        $argList.AddParam($params[$i], "", $params[$i + 1])
    }
    
    $private:inputXmlDocument = New-Object System.Xml.XmlDocument
    $inputXmlDocument.Load($inputXml)
    $xslt.Load($xsl)

    $private:xmlOutputStream = new-object System.IO.StreamWriter($outputFile)
    $xslt.Transform($inputXmlDocument, $argList, $xmlOutputStream)
    $xmlOutputStream.close()
}

function usage
{
    Write-Error "usage: runxslt.ps1 [ <input file> <stylesheet> <output file> [ { <param name> <param value> } ... ] ]"
    exit 1
}

function makeTetml($tet, $tetArgs, $outFileName)
{
    Write-Output ("Generating file '" + $outFileName + "'...")
    & $tet $tetArgs
}

if ($args.length -ge 3) {
    # parameters must appear pairwise on the command line
    $private:paramCount = $args.length - 3
    if ($paramCount % 2 -ne 0)
    {
        Write-Error "Arguments for stylesheet parameters must occur pairwise"
        usage
    }

    $private:params = @()
    if ($args.length -gt 3)
    {
        $params = $args[3 .. ($args.length - 1)]
    }
    
    runXslt $args[0] $args[1] $args[2] $params
}
elseif ($args.Count -eq 0)
{
    $private:tetExe = "..\..\bin\tet"
    $private:pdfFile = "..\data\TET-datasheet.pdf"
    $private:pbTetml = "TET-datasheet.pb.tetml"
    $private:nopbTetml = "TET-datasheet.nopb.tetml"
    
    if (! $(Test-Path $pbTetml))
    {
        $private:tetargs = "--tetml", "wordplus", "--image",
                        "-o", $pbTetml, $pdfFile
        makeTetml $tetExe $tetargs $pbTetml
    }
    
    if (! $(Test-Path $nopbTetml))
    {
        $private:tetargs = "--tetml", "wordplus", "--image",
                    "--pageopt", "contentanalysis={punctuationbreaks=false}",
                    "-o", $nopbTetml, $pdfFile
        makeTetml $tetExe $tetargs $nopbTetml
    }
    
    foreach ($run in $runs) {
        runXslt $run[0] $run[1] $run[2] @()
    }
}
else
{
    usage
}

exit 0
