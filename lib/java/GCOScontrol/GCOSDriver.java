/*
 * Created on Jan 11, 2005
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package GCOScontrol;

import java.util.Hashtable;

import affymetrix.limssdk.GcdoAssay;
import affymetrix.limssdk.GcdoConnection;
import affymetrix.limssdk.GcdoExperiment;
import affymetrix.limssdk.GcdoSample;
import affymetrix.limssdk.GcdoVessel;
import affymetrix.limssdk.GcdoWorkflow;

/**
 * @author jsantos
 * Driver class that encapsulates GCOS Samplesheet parsing
 */
public class GCOSDriver {
	// load Affymetrix native dll
	static {
		System.load("c:\\GCOSJava\\GcdoAffyJava.dll");
	}
	// the source xml file
	private String sourceFile;
	// parser object
	private SampleSheet_Parser parser;
	// GCOS connection
	private GcdoConnection conn;
	
	/**
	 * Constructor that takes an xml file path, and the server name
	 * @param xmlFile the full path and filename of the Samplesheet XML
	 * @param serverGCOS the name of the GCOS server
	 */
	public GCOSDriver(String xmlFile,String serverGCOS) {
		sourceFile = xmlFile;
		// connect to GCOS server
		conn = new GcdoConnection();
		conn.m_strServer = serverGCOS;
	}
	
	/**
	 * Constructor
	 * @param xmlFile the full path and filename of the Samplesheet XML
	 * @param serverGCOS the name of the GCOS server
	 * @param user the DB username of the user
	 * @param password the password of the user
	 */
	public GCOSDriver(String xmlFile,String serverGCOS,String user,String password) {
		sourceFile = xmlFile;
		// connect to GCOS server
		conn = new GcdoConnection();
		conn.m_strServer = serverGCOS;
		conn.m_strPassword = password;
		conn.m_strDBUser = user;
	}
	
	/**
	 * Function to log into the GCOS server
	 * @return true if the log in is successful, false otherwise
	 */
	public boolean login() {
		boolean loggedin = conn.Login();
		// parse provided xml file
		parser = new SampleSheet_Parser(sourceFile, conn);
		parser.parse();	
		return loggedin;
	}
	
	/**
	 * Function to insert all samples specified into the GCOS server
	 * @return true if all samples are inserted correctly, false otherwise
	 */
	public boolean insertSamples() {
		// go through all samples in the parser
		for (int i = 0; i < parser.samples.size();i++) {
			Hashtable sampleHash = (Hashtable)parser.samples.get(i);
		    GcdoWorkflow workflow = (GcdoWorkflow)sampleHash.get("workflow");
		    GcdoAssay assay = (GcdoAssay)sampleHash.get("assay");
		    GcdoSample sample = (GcdoSample)sampleHash.get("sample");
		    GcdoVessel vessel = (GcdoVessel)sampleHash.get("vessel");
		    // if the sample exists, do not try to insert
		    if (sample.Exists(conn) == true) {   	
		    	return false;
		    }
		    
		    if (workflow.RegisterSample(conn, assay, sample, vessel)) {
		    	// do nothing
		    }
		    else {
		    	// change to throw exception
		    	return false;
		    }
		}
	    // fall out
	    return true;
	}
	
	/**
	 * Function to insert all experiments specified into the GCOS server
	 * @return true if all experiments are inserted correctly, throws an exception otherwise
	 */
	public boolean insertExperiments() throws 
		ExperimentExistsException, CannotRegisterExperimentException,CannotReadSampleException {
		// go through all experiments in the parser
		for (int i = 0; i < parser.experiments.size();i++) {
			Hashtable expHash = (Hashtable)parser.experiments.get(i);
			GcdoWorkflow workflow = (GcdoWorkflow)expHash.get("workflow");
			GcdoSample sample= (GcdoSample)expHash.get("sample");
			GcdoExperiment exp = (GcdoExperiment)expHash.get("experiment");	    
	    
			if (sample.Read(conn)) {
				// do nothing
			}
			else {
				throw new CannotReadSampleException();
			}
			
		    if (exp.Exists(conn) == true) {   	
		    	return false;
		    }
		    
			if (workflow.CreateExperiment(conn, sample, exp)) {
				// do nothing
			}
			else {
				throw new CannotRegisterExperimentException();
			}
		}
		return true;
	}
	
	// define exceptions
	public class CannotRegisterExperimentException extends Exception {
		public CannotRegisterExperimentException() {
			super();
		}
		public CannotRegisterExperimentException(String message) {
			super(message);
		}
	}
	
	// define exceptions
	public class ExperimentExistsException extends Exception {
		public ExperimentExistsException() {
			super();
		}
		public ExperimentExistsException(String message) {
			super(message);
		}
	}
	
	public class CannotReadSampleException extends Exception {
		public CannotReadSampleException() {
			super();
		}
		public CannotReadSampleException(String message) {
			super(message);
		}
	}
}
