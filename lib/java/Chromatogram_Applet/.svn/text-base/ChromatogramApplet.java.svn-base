package Chromatogram_Applet;

import java.applet.*;
import java.awt.*;
import java.io.*;
import java.net.*;
import Chromatogram_Applet.ABIChromatogram;
import Chromatogram_Applet.SCFChromatogram;
import Chromatogram_Applet.ChromatogramViewer;

public class ChromatogramApplet extends Applet {
	
    public void init() {
	super.init();
	String fileName = this.getParameter("file");
	if (fileName == "") {
	    System.out.println("Error: File name not suplied");
	}
	else {
	    try {
		URL fileURL = new URL(fileName);
		InputStream regIN = fileURL.openStream();
		BufferedInputStream fileIN = new BufferedInputStream(regIN);
		
		//File f = new File(fileName);
		//BufferedInputStream fileIN = new BufferedInputStream(new FileInputStream(f));
		
		int available = fileIN.available();
		byte[] magicNumArray = new byte[4];
		fileIN.read(magicNumArray);
		ByteArrayInputStream magicIN = new ByteArrayInputStream(magicNumArray);
		DataInputStream magicDIN = new DataInputStream(magicIN);
		int magicNum = magicDIN.readInt();
		magicIN.reset();
		SequenceInputStream seqIN = new SequenceInputStream(magicIN,fileIN);
		ChromatogramViewer myView;
		if (magicNum == ABIChromatogram.MagicNum) {
		    ABIChromatogram chromData = new ABIChromatogram(seqIN,available);
		    myView = new ChromatogramViewer(chromData);
		}
		else if (magicNum == SCFChromatogram.MagicNum) {
		    SCFChromatogram chromData = new SCFChromatogram(seqIN);
		    myView = new ChromatogramViewer(chromData);
		}
		else
		    throw new IOException("Unknown file type");
		this.setLayout(new BorderLayout());
		this.add("Center",myView);
		}
		catch (MalformedURLException ex) {
		    System.out.println("Malformed URL");
		    System.out.println(ex.getMessage());
		}
		catch (IOException ex) {
		    String exMessage = ex.getMessage();
		    String exName = ex.getClass().getName();
		    System.out.println("IO ERROR: " + exName + " : " + exMessage);
		}
	    }
	}
    }
