using System;
using System.IO;
using System.Xml;
using System.Xml.Xsl;
using System.Xml.XPath;
using System.Diagnostics;

/**
 * Simple .NET Core program to run TET XSLT samples.
 *
 * usage: dotnet run
 *
 * it will run all the samples.
 *
 * author rjs
 */
namespace RunXslt
{
    class Program
    {
	private static string PB_TETML = "TET-datasheet.pb.tetml";
	private static string NOPB_TETML = "TET-datasheet.nopb.tetml";
	private static string PDF_FILE = "../data/TET-datasheet.pdf";

	static void Main(string[] args)
	{
	    try
            {
		// Create inputfiles with TET if needed
		RunTet tet = new RunTet();
		if (!File.Exists(PB_TETML)) {
		    tet.run("--tetml wordplus --image -o " + PB_TETML + " " + PDF_FILE);
		}

		if (!File.Exists(NOPB_TETML)) {
		    tet.run("--tetml wordplus --image " +
			    "--pageopt contentanalysis={punctuationbreaks=false} " +
			    "-o " + NOPB_TETML + " " + PDF_FILE);
		}

		// Run the transformations
		Xslt runner = new Xslt();
		runner.run(PB_TETML,   "concordance.xsl", "TET-datasheet.concordance.txt");
		runner.run(PB_TETML,   "index.xsl", "TET-datasheet.index.txt");
		runner.run(PB_TETML,   "table.xsl", "TET-datasheet.table.csv");
		runner.run(NOPB_TETML, "textonly.xsl", "TET-datasheet.textonly.txt");
		runner.run(PB_TETML,   "metadata.xsl", "TET-datasheet.metadata.txt");
		runner.run(PB_TETML,   "fontfilter.xsl", "TET-datasheet.fontfilter.txt");
		runner.run(PB_TETML,   "fontstat.xsl", "TET-datasheet.fontstat.txt");
		runner.run(PB_TETML,   "concordance.xsl", "TET-datasheet.concordance.txt");
		runner.run(NOPB_TETML, "tetml2html.xsl", "TET-datasheet.tetml2html.html");
	    }
	    catch (Exception e)
	    {
		Console.WriteLine(e.ToString());
	    }
	}
    }

    class Xslt
    {
	public void run(string inputfile, string stylesheet, string outputfile)
	{
	    var transformer = new XslCompiledTransform();
	    transformer.Load(stylesheet);
	    transformer.Transform(inputfile, outputfile);
	}
    }

    class RunTet
    {
	//private static string TET_EXE = "../../bin/tet";
	private static string TET_EXE = "../../../progs/tet/tet";

        public void run(string args)
        {
	    Console.WriteLine("running: " + TET_EXE + " " + args);

	    var process = new Process()
	    {
		StartInfo = new ProcessStartInfo
		{
		    FileName = TET_EXE,
		    Arguments = args,
		    RedirectStandardOutput = false,
		    UseShellExecute = false,
		    CreateNoWindow = true,
		}
	    };
	    process.Start();
	    process.WaitForExit();
        }
    }
}
