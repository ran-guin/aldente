/*
 * Created on Mar 13, 2006
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package GCOScontrol;

import affymetrix.limssdk.*;

/**
 * @author jsantos
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public class ReportExporter {
	// GCOS connection
	private GcdoConnection conn;
	
	static {
		System.load("c:\\GCOSJava\\GcdoAffyJava.dll");
		System.load("c:\\GCOSJava\\GcdoReportController.dll");
	}
	/** Constructor that initializes the ReportExporter
	 * @param host the hostname of the GCOS server
	 * @param username
	 * @param password
	 */
	public ReportExporter (String host, String username, String password) {
		// connect to GCOS server
		conn = new GcdoConnection();
		conn.m_strServer = host;
		conn.m_strPassword = password;
		conn.m_strDBUser = username;
	}
	
	/**
	 * Function to log into the GCOS server
	 * @return true if the log in is successful, false otherwise
	 */
	public boolean login() {
		boolean loggedin = conn.Login();
		// parse provided xml file
		return loggedin;
	}
	
	/**
	 * Function to generate a report file for a specified experiment name
	 * @return true if successful, false otherwise
	 * @author jsantos
	 */
	public boolean generateReport (String experiment) {
	    GcdoManager manager = new GcdoManager();
		manager.m_strExpName = experiment;
		GcdoExperiment [] expList = manager.LoadExperiments(conn);
		// there should only be one experiment. If there are multiples, return false
		if (expList.length != 1) {
			System.out.println("Cannot find EXPERIMENT " + experiment);
			return false;
		}
		// get the assay type
		GcdoAssay assay = expList[0].GetAssay(conn);
		assay.Read(conn);
		ASSAY_TYPE type = assay.getType();
		String assay_type = null;
		
		if (type.equals(ASSAY_TYPE.EXPRESSION_ASSAY)) {
			assay_type = "Expression";
		}
		else if (type.equals(ASSAY_TYPE.MAPPING_ASSAY)) {
			assay_type = "Mapping";
		}
		else {
			// cannot find assay type, return false
			System.out.println("Cannot find ASSAY type " + type );
			return false;
		}
		
		GcdoFileType [] files = expList[0].LoadFiles(conn);
		String chipFileName = null;
		
		// find the CHP file
		// for processing
		for (int k = 0; k < files.length; k++) { 
			files[k].Read(conn); 
			if (files[k].m_strName.endsWith("CHP")) {
				chipFileName = files[k].m_strName;
			}
		}
		
		// generate a report file and copy to /home/sequence/alDente/affy_reports
		if (chipFileName == null) {
			System.out.println("Cannot find CHIP filename");
			return false;
		}
		System.out.println("Using filename " + chipFileName);
		GcdoReportController rpt = new GcdoReportController();
		rpt.setServer(conn.m_strServer);
		if (type.equals(ASSAY_TYPE.EXPRESSION_ASSAY)) {
			System.out.println("Generating EXPRESSION report...");
			boolean val = rpt.RunReport(
					assay_type,
					chipFileName,
					"templims.RPT",
					"\\\\GCOS01\\GCLims\\Data",
					"\\\\GCOS01\\GCLims\\Library", 
					""
				);
			if (val) {
				System.out.println("Success!");
			}
			else {
				System.out.println("Failed.");		
			}
				  
		}
		else {			
			System.out.println("Generating MAPPING report...");
			// mapping analysis
			String [] filenames = new String[1];
			filenames[0] = chipFileName;
			rpt.RunReportEx(
					assay_type,
					filenames,
					"temp_lims.RPT",
					"\\\\GCOS01\\GCLims\\Data",
					"\\\\GCOS01\\GCLims\\Library", 
					""
				);
		}
			
		
		
		return true;
	}

}
