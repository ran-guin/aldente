package Chromatogram_Applet;

import java.awt.*;

import javax.swing.JLabel;
import javax.swing.JPanel;


import Chromatogram_Applet.Chromatogram;
class ChromatogramViewer extends JPanel {		Scrollbar hbar;
	Scrollbar scaleBar;	ChromatogramCanvas ChromArea;	Chromatogram chromData;
	Checkbox reversed;
		int offset = 0;
	// for scaling, SCALE_INCREMENT is the minimum scale factor.
	// scaling will be normalized with SCALE_INCREMENT as 1
	// so, a scale value of 400 with an increment of 100 is 4x magnification
	private static int MAX_SCALE = 4000;
	private static int SCALE_INCREMENT = 100;		public ChromatogramViewer(Chromatogram myChrom) {		super(true);		chromData = myChrom;		ChromArea = new ChromatogramCanvas(this);		hbar = new Scrollbar(Scrollbar.HORIZONTAL);
		int maxScale = (MAX_SCALE+SCALE_INCREMENT);
		scaleBar = new Scrollbar(Scrollbar.VERTICAL,maxScale,SCALE_INCREMENT,SCALE_INCREMENT,maxScale);
		reversed = new Checkbox("Complemented Sequence");
		JPanel northPanel = new JPanel();
		JLabel statBar = new JLabel();
		statBar.setBackground(Color.WHITE);
		statBar.setText(
				"Max:" + ChromArea.getMaxValue() + " " + 
				"Average Signal A:" + ChromArea.getAverageValue('A') + "    " + 
				"C: " + ChromArea.getAverageValue('C') + " " +
				"T: " + ChromArea.getAverageValue('T') + " " +
				"G: " + ChromArea.getAverageValue('G')
				);
		northPanel.setLayout(new GridLayout(1,2));
		northPanel.add(reversed);
		northPanel.add(statBar);
		northPanel.setBackground(Color.WHITE);		this.setLayout(new BorderLayout(0,0));		this.add("Center",ChromArea);		this.add("South",hbar);
		this.add("North",northPanel);
		this.add("West",scaleBar);		setBackground(Color.white);
			}		public Dimension minimumSize() {		return new Dimension(100,100);	}		// Handle Scrolbar Events, taken almost verbatim from pg 119 of Java in a Nutshell		public boolean handleEvent(Event evt) {		if(evt.target == hbar) {			switch(evt.id) {				case Event.SCROLL_LINE_UP:				case Event.SCROLL_LINE_DOWN:				case Event.SCROLL_PAGE_UP:				case Event.SCROLL_PAGE_DOWN:				case Event.SCROLL_ABSOLUTE:				offset = ((Integer)evt.arg).intValue();
				hbar.setMaximum(ChromArea.getHSize());				ChromArea.repaint();				break;			}			return true;		}
		else if (evt.target == scaleBar) {
			ChromArea.setGraphScale((MAX_SCALE+SCALE_INCREMENT - scaleBar.getValue())/SCALE_INCREMENT);
		}
		else if (evt.target == reversed) {
			ChromArea.reversed = reversed.getState();
			ChromArea.repaint();
		}		return super.handleEvent(evt);	}		// Handle size change, again from Nutshell book		public synchronized void reshape(int x, int y, int width, int height) {		super.reshape(x,y,width,height);		hbar.setValues(offset,width,0,chromData.getTraceLength() - width -1);		hbar.setPageIncrement(width);		hbar.setLineIncrement(width/10);		ChromArea.repaint();		ChromArea.setBackground(Color.white);	}}class ChromatogramCanvas extends Canvas {	ChromatogramViewer pv;	Chromatogram chromData; 	int[] A,C,G,T;
	int [] basePosition;
	char [] baseCall;
	// store reversed heightvalues
	int[] rA, rC, rG, rT;
	int[] rBasePosition;
	char [] rBaseCall;
		int maxValue;
	int maxA;
	int maxT;
	int maxC;
	int maxG;
	float avgA, avgG, avgC, avgT;
	float scaleGraph;
	boolean reversed;		public ChromatogramCanvas(ChromatogramViewer parentV) {		super();		pv = parentV;		chromData = parentV.chromData;		setBackground(Color.white);		A = chromData.getATrace();		C = chromData.getCTrace();		G = chromData.getGTrace();		T = chromData.getTTrace();
		basePosition = new int[chromData.getBaseNumber()];
		baseCall = new char[chromData.getBaseNumber()];
		
		for (int i=0;i < chromData.getBaseNumber();i++) {
			basePosition[i] = chromData.getBasePosition(i);
			baseCall[i] = chromData.getBase(i);
		}
		
		rA = reverseArray(A);
		rC = reverseArray(C);
		rG = reverseArray(G);
		rT = reverseArray(T);
		rBasePosition = reversePositionArray(basePosition);
		rBaseCall = reverseBaseArray(baseCall);
				int i;		maxValue = 0;
		maxA = 0;
		maxT = 0;
		maxC = 0;
		maxG = 0;
		int totalA = 0;
		int totalT = 0;
		int totalG = 0;
		int totalC = 0;		for (i=0;i<chromData.getTraceLength();i++) {
			// figure out maximum signal for all bases			if (A[i] > maxValue) maxValue = A[i];			if (C[i] > maxValue) maxValue = C[i];			if (G[i] > maxValue) maxValue = G[i];			if (T[i] > maxValue) maxValue = T[i];
			// figure out maximum signal for separate bases
			if (A[i] > maxA) maxA = A[i]; 
			if (C[i] > maxC) maxC = C[i]; 
			if (T[i] > maxT) maxT = T[i]; 
			if (G[i] > maxG) maxG = G[i]; 
			// add up all values of separate bases
			totalA += A[i];
			totalC += C[i];
			totalT += T[i];
			totalG += G[i];		}
		// get average for separate bases
		avgA = totalA / chromData.getTraceLength();
		avgT = totalT / chromData.getTraceLength();
		avgG = totalG / chromData.getTraceLength();
		avgC = totalC / chromData.getTraceLength();
		
		scaleGraph = 1;
		reversed = false;	}
	
	public int getMaxValue() {
		return maxValue;
	}
	
	public int getMaxValue(char base) {
		switch (base) {
		case 'A':
			return maxA;
		case 'C':
			return maxC;
		case 'G':
			return maxG;
		case 'T':
			return maxT;
		}
		// default fall-through, return 0
		return 0;
	}
	
	public float getAverageValue(char base) {
		switch (base) {
		case 'A':
			return avgA;
		case 'C':
			return avgC;
		case 'G':
			return avgG;
		case 'T':
			return avgT;
		}
		// default fall-through, return 0
		return 0;
	}
	
	// this function reverses the basecalls and 
	// changes the bases to their complement
	private char[] reverseBaseArray (char [] calls) {
		char [] reverseArray = reverseArray(calls);
		for (int i = 0; i < reverseArray.length; i++) {
			switch (reverseArray[i]) {
			case 'A':
				reverseArray[i] = 'T';
				continue;
			case 'C':
				reverseArray[i] = 'G';
				continue;
			case 'G':
				reverseArray[i] = 'C';
				continue;
			case 'T':
				reverseArray[i] = 'A';
				continue;
			}
		}
		return reverseArray;
	}
	
	private int[] reversePositionArray (int[] pos) {
		int[] reverseArray = reverseArray(pos);
		for (int i = 0; i < reverseArray.length; i++) {
			reverseArray[i] = chromData.getTraceLength() - reverseArray[i];
		}
		return reverseArray;
	}
	
	private int[] reverseArray(int[] a) {
		int [] reverseArray = new int[a.length];
		for (int i = a.length-1; i >= 0; i--) {
			reverseArray[ (a.length-1) - i] = a[i];
		}
		return reverseArray;
	}
	
	private char[] reverseArray(char[] a) {
		char [] reverseArray = new char[a.length];
		for (int i = a.length-1; i >= 0; i--) {
			reverseArray[ (a.length-1) - i] = a[i];
		}
		return reverseArray;
	}
	
	public int getHSize() {
		return chromData.getTraceLength();
	}
	
	public void setGraphScale(int scale) {
		this.scaleGraph = scale;
		this.repaint();
	}
			public void paint(Graphics grph) {			int cheight = size().height;		int cwidth = size().width;		float scale = (maxValue / cheight) / this.scaleGraph;		int offset = pv.offset;		int i;
		int [] A, C, T, G;
		
		if (reversed == true) {
			A = rA;
			C = rC;
			T = rT;
			G = rG;
		}
		else {
			A = this.A;
			C = this.C;
			T = this.T;
			G = this.G;
		}
		if (reversed == true) {			for (i=offset;i < offset+cwidth-2;i+=2) {				grph.setColor(Color.red);				grph.drawLine(i - offset,(new Float(cheight-A[i] / scale)).intValue(),i+2-offset,(new Float(cheight-A[i+2] / scale)).intValue());				grph.setColor(Color.black);				grph.drawLine(i-offset,(new Float(cheight-C[i] / scale)).intValue(),i+2-offset,(new Float(cheight-C[i+2] / scale)).intValue());				grph.setColor(Color.blue);				grph.drawLine(i-offset,(new Float(cheight-G[i] / scale)).intValue(),i+2-offset,(new Float(cheight-G[i+2] / scale)).intValue());				grph.setColor(Color.green);				grph.drawLine(i-offset,(new Float(cheight-T[i] / scale)).intValue(),i+2-offset,(new Float(cheight-T[i+2] / scale)).intValue());			}
		}
		else {
			for (i=offset;i < offset+cwidth-2;i+=2) {
				grph.setColor(Color.green);
				grph.drawLine(i - offset,(new Float(cheight-A[i] / scale)).intValue(),i+2-offset,(new Float(cheight-A[i+2] / scale)).intValue());
				grph.setColor(Color.blue);
				grph.drawLine(i-offset,(new Float(cheight-C[i] / scale)).intValue(),i+2-offset,(new Float(cheight-C[i+2] / scale)).intValue());
				grph.setColor(Color.black);
				grph.drawLine(i-offset,(new Float(cheight-G[i] / scale)).intValue(),i+2-offset,(new Float(cheight-G[i+2] / scale)).intValue());
				grph.setColor(Color.red);
				grph.drawLine(i-offset,(new Float(cheight-T[i] / scale)).intValue(),i+2-offset,(new Float(cheight-T[i+2] / scale)).intValue());
			}		
		}
		
		int [] basePosition;
		char [] bases;
		if (reversed == true) {
			basePosition = this.rBasePosition;
			bases = this.rBaseCall;
		}
		else {
			basePosition = this.basePosition;
			bases = this.baseCall;		
		}
		int nmid = getFontMetrics(grph.getFont()).stringWidth(String.valueOf(i+1)) / 2;		for (i=0;i < chromData.getBaseNumber(); i++) {			if ((basePosition[i] > offset) && (basePosition[i] < offset + cwidth)) {				switch (bases[i]) {				case 'A':					grph.setColor(Color.green);					break;				case 'C':					grph.setColor(Color.blue);					break;				case 'G':					grph.setColor(Color.black);					break;				case 'T':					grph.setColor(Color.red);					break;				default:					grph.setColor(Color.gray);				}				int cmid = getFontMetrics(grph.getFont()).charWidth(bases[i]) / 2;				grph.drawString(String.valueOf(bases[i]),basePosition[i] - offset - cmid, 15);
				int countIncrement;
				int position;
				if (reversed == true) {
					countIncrement = (chromData.getBaseNumber()-i) % 10;
					position = chromData.getBaseNumber()-i;
				}
				else {
					countIncrement = (i+1) % 10;		
					position = i + 1;
				}				if (countIncrement == 0) {					grph.setColor(Color.black);					grph.drawString(String.valueOf(position),basePosition[i] - offset - nmid,25);				}			}		}	}}
