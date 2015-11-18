/*
 * Created on Jan 4, 2005
 */
package GCOScontrol;


/**
 * Test Driver
 * @author jsantos
 */
public class LoadGCOSXML {
	static {
		System.load("c:\\GCOSJava\\GcdoAffyJava.dll");
	}
	
	public static void main (String[] args) {
		// parse out host argument (arg 1)
		String host = args[0];
		// parse out filename argument (arg 2)
		String filename = args[1];
		// if there are additional arguments, arg 3 is user, arg 4 is password
		String user = "";
		String password = "";
		GCOSDriver driver = null;
		if (args.length > 2) {
			user = args[2];
			password = args[3];
			driver = new GCOSDriver(filename,host,user,password);
		}
		else {
			driver = new GCOSDriver(filename,host);
		}
		
		driver.login();
		driver.insertSamples();
		try {
			driver.insertExperiments();
		}
		catch (GCOSDriver.CannotReadSampleException e) {
			System.out.println(e.getMessage());
			e.printStackTrace();
		}
		catch (GCOSDriver.CannotRegisterExperimentException e) {
			System.out.println(e.getMessage());
			e.printStackTrace();
		}
		catch (GCOSDriver.ExperimentExistsException e) {
			System.out.println(e.getMessage());
			e.printStackTrace();
		}
	}	
}
