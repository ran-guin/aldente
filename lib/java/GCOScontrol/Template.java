/*
 * Created on Jan 4, 2005
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package GCOScontrol;

import java.util.Vector;

import affymetrix.limssdk.GcdoConnection;

/**
 * @author jsantos
 *
 */
public class Template {
	static {
		System.load("c:\\GCOSJava\\GcdoAffyJava.dll");
	}
	// private variables
	// connection
	private GcdoConnection conn;
	// attribute array
	private Vector attributes;
	
	/** constructor
	 *  requires an active (logged in) connection
	 *  @author jsantos
	 */
	public Template(GcdoConnection conn) {
		this.conn =  conn;
		attributes = new Vector();
	}
		
	/**
	 * adds an attribute to the template
	 * @author jsantos
	 *
	 */
	
}
