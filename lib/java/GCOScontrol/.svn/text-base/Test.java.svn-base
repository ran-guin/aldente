/*
 * Created on Jul 27, 2004
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package GCOScontrol;


import affymetrix.limssdk.*;
import java.io.*;

/**
 * @author jsantos
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */


public class Test {
	static {
		System.load("c:\\GCOSJava\\GcdoAffyJava.dll");
		System.load("c:\\GCOSJava\\GcdoReportController.dll");
	}
	
	private static String genLine(int numTabs,String tag, String value) {
		String retVal = "";
		while (numTabs > 0) {
			retVal += "\t";
			numTabs--;
		}
		retVal += "<" + tag + ">" + value + "</" + tag + ">\n";
		return retVal;
	}
	
	public static void main(String[] args) {
		BufferedWriter out = null;
	    try {
	        out = new BufferedWriter(new FileWriter("c:\\outfile.xml"));
	        out.write("<INPUT>\n");
	    } catch (IOException e) {
	    	e.printStackTrace();
	    }

		GcdoConnection oConn =  null;
		try
		{

		    // Declare variables
		    oConn = new GcdoConnection();
		    String strServer;
		    boolean bRes=false;

		    // Set GCOS server name
		    strServer = "GCOS01";

		    // Log into GCOS
		    oConn.m_strServer = strServer;
		    bRes = oConn.Login();
		    if (bRes == true)
		    { 
		    	System.out.println("Connected to GCOS");
		    }
		    else
		    {
	           System.out.println("Failed connect to GCOS");
		    }
		    GcdoManager manager = new GcdoManager();
		    GcdoSample [] sampleSet = manager.LoadSamples(oConn);
		    for (int sampleNum = 0; sampleNum < sampleSet.length; sampleNum++) {
		    	GcdoSample s = sampleSet[sampleNum];
		    	if (s.m_strName.startsWith("MR")) {
		    		// start a set
		    		out.write("<SET>\n");
		    		out.write("\t<SAMPLE>\n");		    
					s.Read(oConn);
					GcdoAttribute[] attr = s.LoadAttributes(oConn);
					String name = s.m_strName;
					String project = s.m_strProject;
					String entryDate = s.m_strDate;
					String comment = s.m_strComment;
					String stage = s.m_strStage;
					String template = s.m_strTemplateName;
					String type = s.m_strType;
					String user = s.m_strUser;
					
					String sampleName = "";
					
					out.write(genLine(2,"GCOS_Project",project));
					out.write(genLine(2,"GCOS_Entry_Date",entryDate));
					out.write(genLine(2,"Sample_Comments",comment));
					out.write(genLine(2,"GCOS_Sample_Type",type));
					out.write(genLine(2,"GCOS_Stage",stage));
					out.write(genLine(2,"GCOS_Template",template));
					out.write(genLine(2,"GCOS_User",user));
					out.write(genLine(2,"Sample_Type","Extraction"));
					
					if (attr != null) {
						for (int j = 0; j < attr.length; j++) {
							String sAttribName = attr[j].m_strName;
							String sAttribValue = attr[j].m_strValue;
							sAttribName = sAttribName.replace(' ','_');
							if (sAttribName.equalsIgnoreCase("Sample_ID")) {
								sampleName = sAttribValue;
							}
							out.write(genLine(2,"GCOS_" + sAttribName,sAttribValue));
						}
					}
					out.write("\t</SAMPLE>\n");
					// experiment and chip section
					GcdoExperiment [] experiments = s.LoadExperiments(oConn);
					for (int expNum = 0; expNum < experiments.length; expNum++) {
						GcdoExperiment exp = experiments[expNum];
						exp.Read(oConn);
						String expDate = exp.m_strDate;
						out.write("\t<EXPERIMENT>\n");
						out.write(genLine(2,"Experiment_DateTime",exp.m_strDate));
						out.write(genLine(2,"Experiment_Comments",exp.m_strComment));
						out.write("\t</EXPERIMENT>\n");
						out.write("\t<GENECHIP_EXPERIMENT>\n");
						out.write(genLine(2,"Experiment_User",exp.m_strUser));
						out.write(genLine(2,"GCOS_Experiment_Name",exp.m_strName));
						out.write(genLine(2,"Type","Mapping"));
						GcdoAttribute[] expAttr = exp.m_aoAttributes;
						if (attr != null) {
							for (int j = 0; j < attr.length; j++) {
								String sAttribName = attr[j].m_strName;
								String sAttribValue = attr[j].m_strValue;
								sAttribName = sAttribName.replace(' ','_');
								out.write(genLine(2,"GCOS_" + sAttribName,sAttribValue));
							}
						}
						String [] chpFileName = new String[1];
						chpFileName[0] = null;
						GcdoFileType [] files = exp.LoadFiles(oConn);
						for (int k = 0; k < files.length; k++) { 
							files[k].Read(oConn); 
							if (files[k].m_strName.endsWith("DAT")) {
								out.write(genLine(2,"GCOS_DAT_File",files[k].m_strName));
							}
							else if (files[k].m_strName.endsWith("CEL")) {
								out.write(genLine(2,"GCOS_CEL_File",files[k].m_strName));
							}
							else if (files[k].m_strName.endsWith("CHP")) {
								out.write(genLine(2,"GCOS_CHP_File",files[k].m_strName));
								chpFileName[0] = files[k].m_strName;
							}
						}
						
						if (chpFileName[0] != null) {
							GcdoReportController rpt = new GcdoReportController();
							rpt.setServer("GCOS01");
							
							System.out.println("reading " + chpFileName[0]);

							boolean rptOk = rpt.RunReportEx("Mapping", chpFileName,
									"temp_lims.RPT",
									"\\\\GCOS01\\GCLims\\Data",
									"\\\\GCOS01\\GCLims\\Library", 
									""
									);
							
							File src = new File(
									"\\\\GCOS01\\GCLims\\Data\\temp_lims.RPT");
							//FileInputStream in = new FileInputStream(src);
							
							BufferedReader in = new BufferedReader(
									new FileReader(src));

							// scan for "SNP Performance"
							String line = in.readLine();
							while ((line != null)
									&& !line
											.equalsIgnoreCase("SNP Performance")) {
								line = in.readLine();
							}
							// read headers and store into array
							String[] headersSNPperf = in.readLine().split("\t");
							// read values and store into array
							String[] valuesSNPperf = in.readLine().split("\t");
							
							// scan for "QC Performance"
							while ((line != null)
									&& !line
											.equalsIgnoreCase("QC Performance")) {
								line = in.readLine();
							}
							// read headers and store into array
							String[] headersQC = in.readLine().split("\t");
							// read values and store into array
							String[] valuesQC = in.readLine().split("\t");

							// scan to Shared SNP Patterns
							while ((line != null)
									&& !line
											.equalsIgnoreCase("Shared SNP Patterns")) {
								line = in.readLine();
							}
							// read headers and store into array
							String[] headersSNPpattern = in.readLine().split(
									"\t");
							// read values and store into array
							String[] valuesSNPpattern = in.readLine().split(
									"\t");

							in.close();

							// write to file
							for (int k = 1; k < headersSNPperf.length; k++) {
								out.write(genLine(2, "GCOS_" + headersSNPperf[k].replace(
										' ', '_'), valuesSNPperf[k]));
							}
							// write to file
							for (int k = 1; k < headersQC.length; k++) {
								out.write(genLine(2, "GCOS_" + headersQC[k].replace(
										' ', '_'), valuesQC[k]));
							}
							for (int k = 1; k < headersSNPpattern.length; k++) {
								out
										.write(genLine(2, "GCOS_" + headersSNPpattern[k]
												.replace(' ', '_'),
												valuesSNPpattern[k]));
							}
							src.delete();
							
						}
						
						out.write("\t</GENECHIP_EXPERIMENT>\n");

						
						
						GcdoChip chip = exp.GetChip(oConn);
						if (chip != null) {
							chip.Read(oConn);
							out.write("\t<CHIP>\n");
							out.write(genLine(2,"Genechip_Type",chip.m_strChipType));
							out.write(genLine(2,"External_Barcode",chip.m_strBarcode));
							out.write(genLine(2,"Expiry_Date",chip.m_strExpirationDate));
							out.write(genLine(2,"Lot_Number",chip.m_strLotNumber));
							out.write(genLine(2,"Library_Name",sampleName));
							out.write(genLine(2,"Plate_Number","1"));
							out.write(genLine(2,"Plate_Content_Type","Mixed"));
							out.write(genLine(2,"Plate_Application","Gene Expression"));
							out.write(genLine(2,"Plate_Type","Genechip"));
							out.write(genLine(2,"Plate_Format","19"));
							out.write(genLine(2,"Rack","1"));
							out.write(genLine(2,"Plate_Size","1-well"));
							out.write(genLine(2,"Plate_Status","Active"));
							out.write(genLine(2,"Plate_Created",expDate));
							out.write("\t</CHIP>\n");
						}
					}
					
					
					out.write("</SET>\n");
				}
		    }
	    	


		    out.write("</INPUT>\n");
			out.close();
		 }
		catch (Exception e)
		{
		    System.out.println("Exception thrown: " + e.toString());
		    e.printStackTrace();
		}

		
	}
}
