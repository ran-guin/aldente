/*
 * Created on Jul 25, 2006
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package Chromatogram_Applet;

import java.awt.BorderLayout;
import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.SequenceInputStream;
import java.net.MalformedURLException;

import javax.swing.JFrame;

/**
 * @author jsantos
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public class Main {
	
	public static void main (String args[]){
	//String fileName = "C:\\testchromat.ab1";
	//String fileName = "T:\\Projects\\Rob_Research\\RHSP1\\AnalyzedData\\RHSP140.CB\\chromat_dir\\RHSP140.CB_K01.abi";
	String fileName = "C:\\RHSP142.CB_-_A03_02.ab1";
	//String fileName = "C:\\fake_read.ab1";
	ChromatogramViewer myView = null;
	if (fileName == "") {
	    System.out.println("Error: File name not suplied");
	}
	else {
	    try {
//		URL fileURL = new URL(fileName);
		File f = new File(fileName);
		
//		InputStream regIN = new InputStream(f);
		BufferedInputStream fileIN = new BufferedInputStream(new FileInputStream(f));
		int available = fileIN.available();
		byte[] magicNumArray = new byte[4];
		fileIN.read(magicNumArray);
		ByteArrayInputStream magicIN = new ByteArrayInputStream(magicNumArray);
		DataInputStream magicDIN = new DataInputStream(magicIN);
		int magicNum = magicDIN.readInt();
		magicIN.reset();
		SequenceInputStream seqIN = new SequenceInputStream(magicIN,fileIN);
		if (magicNum == ABIChromatogram.MagicNum) {	
		    ABIChromatogram chromData = new ABIChromatogram(seqIN, available);
		    myView = new ChromatogramViewer(chromData);
		}
		else if (magicNum == SCFChromatogram.MagicNum) {
		    SCFChromatogram chromData = new SCFChromatogram(seqIN);
		    myView = new ChromatogramViewer(chromData);
		}
		else
		    throw new IOException("Unknown file type");
		}
		catch (MalformedURLException ex) {
		    System.out.println("Malformed URL");
		}
		catch (IOException ex) {
		    String exMessage = ex.getMessage();
		    String exName = ex.getClass().getName();
		    ex.printStackTrace();
		    System.out.println("IO ERROR: " + exName + " : " + exMessage);
		}
		
	    //1. Optional: Specify who draws the window decorations. 
	    JFrame.setDefaultLookAndFeelDecorated(true);

	    //2. Create the frame.
	    JFrame frame = new JFrame("ChromatViewer");

	    //3. Optional: What happens when the frame closes?
	    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

	    //4. Create components and put them in the frame.
	    //...create emptyLabel...
	    frame.getContentPane().add(myView, BorderLayout.CENTER);

	    //5. Size the frame.
	    frame.pack();

	    //6. Show it.
	    frame.setVisible(true);

	    }	
	}

}
