import java.io.File;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

/**
 * Simple Java wrapper to run TET XSLT samples.
 * <br><br>
 * usage: java runxslt [ &lt;input file&gt; &lt;stylesheet&gt; &lt;output file&gt; [ { &lt;param name&gt; &lt;param value&gt; } ... ] ]
 * <br><br>
 * If the program is invoked without arguments, it will run all the samples.
 * If the program is invoked with the arguments &lt;input file&gt;, &lt;stylesheet&gt; and
 * &lt;output file&gt;, the script will run the given stylesheet for the input file
 * and write the results to the output file. Stylesheet parameters can be
 * provided as pairwise arguments at the end of the command line.
 * <br>
 * @author stm
 */
public class runxslt
{
    private static final String TET_EXE = "../../bin/tet";
    
    private static final String PDF_FILE = "../data/TET-datasheet.pdf";
    
    private static final String NOPB_TETML = "TET-datasheet.nopb.tetml";

    private static final String PB_TETML = "TET-datasheet.pb.tetml";
    
    private static String[][] runs =
    {
        { PB_TETML, "concordance.xsl", "TET-datasheet.concordance.txt" },
        { PB_TETML, "index.xsl", "TET-datasheet.index.txt" },
        { PB_TETML, "table.xsl", "TET-datasheet.table.csv" },
        { NOPB_TETML, "textonly.xsl", "TET-datasheet.textonly.txt" },
        { PB_TETML, "metadata.xsl", "TET-datasheet.metadata.txt" },
        { PB_TETML, "fontfilter.xsl", "TET-datasheet.fontfilter.txt" },
        { PB_TETML, "fontstat.xsl", "TET-datasheet.fontstat.txt" },
        { PB_TETML, "fontfinder.xsl", "TET-datasheet.fontfinder.txt" },
        { NOPB_TETML, "tetml2html.xsl", "TET-datasheet.tetml2html.html" }
    };
    
    class StyleSheetParameter
    {
        public String name;
        public String value;
    }
    
    /**
     * @param args
     */
    public static void main(String[] args)
    {
        runxslt runner = new runxslt();
        
        if (args.length >= 3)
        {
            int paramCount = args.length - 3;
            
            // XSLT parameters must appear pairwise on the command line
            if (paramCount % 2 != 0)
            {
                System.err.println("Arguments for stylesheet parameters must occur pairwise");
                usage();
            }
            
            LinkedList<StyleSheetParameter> params = new LinkedList<StyleSheetParameter>();
            for (int i = 3; i < args.length; i += 2)
            {
                StyleSheetParameter p = runner.new StyleSheetParameter();
                p.name = args[i];
                p.value = args[i + 1];
                params.add(p);
            }
            
            runner.runXslt(args[0], args[1], args[2], params);
        }
        else if (args.length == 0)
        {
            // Run all scripts on TETML files generated from TET-datasheet.pdf
            File nopbTetml = new File(NOPB_TETML);
            if (!nopbTetml.exists())
            {
                String[] cmd =
                {
                    TET_EXE, "--tetml", "wordplus", "--image", 
                    "--pageopt", "contentanalysis={punctuationbreaks=false}",
                    "-o", NOPB_TETML, PDF_FILE
                };
                makeTetml(cmd, NOPB_TETML);
            }
            
            File pbTetml = new File(PB_TETML);
            if (!pbTetml.exists())
            {
                String[] cmd =
                {
                    TET_EXE, "--tetml", "wordplus", "--image", 
                    "-o", PB_TETML, PDF_FILE
                };
                makeTetml(cmd, PB_TETML);
            }
            
            for (int i = 0; i < runs.length; i += 1)
            {
                runner.runXslt(runs[i][0], runs[i][1], runs[i][2], null);
            }
        }
        else
        {
            usage();
        }
    }

    /**
     * Run the transformation, with optional stylesheet parameters.
     * 
     * @param inputFile The TETML input file
     * @param styleSheet The XSLT stylesheet
     * @param outputFile The output file
     * @param params A list of StyleSheetParameter instances
     */
    private void runXslt(String inputFile, String styleSheet, String outputFile,
            List params)
    {
        try
        {
            Source xmlInput = new StreamSource(inputFile);
            Source xsltSource = new StreamSource(styleSheet);
            Result result = new StreamResult(outputFile);
            
            TransformerFactory factory = TransformerFactory.newInstance();
            Transformer transformer = factory.newTransformer(xsltSource);
            
            if (params != null)
            {
                Iterator i = params.iterator();
                while (i.hasNext())
                {
                    StyleSheetParameter p = (StyleSheetParameter) i.next();
                    transformer.setParameter(p.name, p.value);
                }
            }
            
            System.out.println("Transforming input file \"" + inputFile
                    + "\" with stylesheet \"" + styleSheet
                    + "\" to output file \"" + outputFile + "\"");
            
            transformer.transform(xmlInput, result);
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
    }
    
    private static void makeTetml(String[] cmd, String outputFileName)
    {
        System.out.println("Generating file '" + outputFileName + "'...");
        
        try
        {
            Process p = Runtime.getRuntime().exec(cmd);
            BufferedReader input =
                    new BufferedReader(new InputStreamReader(p.getInputStream()));
            String line;
            while ((line = input.readLine()) != null) {
                System.out.println(line);
            }
            input.close();
            p.waitFor();
        }
        catch (IOException e)
        {
            e.printStackTrace();
            System.exit(1);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static void usage()
    {
        System.err.println("usage: runxslt [ <input file> <stylesheet> <output file> [ { <param name> <param value> } ... ] ]");
        System.exit(1);
    }
}
