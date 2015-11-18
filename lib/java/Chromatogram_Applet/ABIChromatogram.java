package Chromatogram_Applet;

import java.io.*;
import Chromatogram_Applet.Chromatogram;
import Chromatogram_Applet.TaggedRecord;

	
	public ABIChromatogram(InputStream IN, int available) throws IOException {
		read(IN, available);
	}
		int itemBytes = headerIN.readInt();
		// read from file to fill fileBytes
		// starts from recordOffset: directory
		//System.out.println("Base sequence: " + baseSequence);
		
		
	
	
	public void read(InputStream IN, int available)  throws IOException{
		DataInputStream dataIN = new DataInputStream(IN);
		byte[] fileHeader = new byte[30];
		dataIN.readFully(fileHeader);
		ByteArrayInputStream hIN = new ByteArrayInputStream(fileHeader);
		DataInputStream headerIN = new DataInputStream(hIN);
		headerIN.skip(18);
		int recordNum = headerIN.readInt();
		//headerIN.skip(4);
		int itemBytes = headerIN.readInt();
		int recordOffset = headerIN.readInt();
		headerIN.reset();
		byte[] fileBytes = new byte[available];
		// read from file to fill fileBytes
		headerIN.readFully(fileBytes,0,30);
		dataIN.readFully(fileBytes,30,fileBytes.length - 30);
		ByteArrayInputStream plainbyteIN = new ByteArrayInputStream(fileBytes);
		DataInputStream byteIN = new DataInputStream(plainbyteIN);
		byteIN.skip(recordOffset);
		// starts from recordOffset: directory
		// read tagged records into hash table
		TaggedRecord[] records = new TaggedRecord[recordNum];
		Hashtable rHash = new Hashtable(recordNum);
		int i;
		for (i=0;i<recordNum;i++) {
			records[i] = new TaggedRecord(byteIN);
			rHash.put(records[i].getTagName() + records[i].getTagNum(),records[i]);
			}
		// get base calls
		TaggedRecord PBAS1 = (TaggedRecord) (rHash.get("PBAS1"));
		int Offset = PBAS1.getDataRecord();
		int elementNum = PBAS1.getElementNumber();
		byteIN.reset();
		byteIN.skip(Offset);
		base = new char[elementNum];
		for (i=0;i<elementNum;i++) {
			base[i] = (char) byteIN.readUnsignedByte();
		}
		baseSequence = new String(base);
		// get base locations
		TaggedRecord PLOC1 = (TaggedRecord) (rHash.get("PLOC1"));
		Offset = PLOC1.getDataRecord();
		elementNum = PLOC1.getElementNumber();
		byteIN.reset();
		byteIN.skip(Offset);
		basePosition = new int[elementNum];
		for (i=0;i<elementNum;i++) {
			basePosition[i] = (char) byteIN.readUnsignedShort();
		}
		// get FWO (tells which trace is which)
		TaggedRecord FWO1 = (TaggedRecord) (rHash.get("FWO_1"));
		int packedChar = FWO1.getDataRecord();
		char[] baseOrder = new char[4];
		baseOrder[0] = (char) ((byte)(packedChar >> 24));
		baseOrder[1] = (char) ((byte)(packedChar >> 16));
		baseOrder[2] = (char) ((byte)(packedChar >> 8));
		baseOrder[3] = (char) ((byte)(packedChar));		
		// get data records for traces
		TaggedRecord[] Trace = new TaggedRecord[4];
		traceLength = 1000000;
		int dataNum;
		for (i=0;i<4;i++) {
			dataNum = 9 + i;
			Trace[i] = (TaggedRecord) (rHash.get("DATA" + dataNum));
			if (Trace[i].getElementNumber() < traceLength)
				traceLength = Trace[i].getElementNumber();
		}
		// using FWO record data as guide, input Trace data
		A = new int[traceLength];
		C = new int[traceLength];
		G = new int[traceLength];
		T = new int[traceLength];		
		for (i=0;i<4;i++) {
			byteIN.reset();			
			byteIN.skip(Trace[i].getDataRecord());						
			switch (baseOrder[i]) {
				case 'A':
				readUSArray(A,byteIN);
				break;
				case 'C':
				readUSArray(C,byteIN);
				break;
				case 'G':
				readUSArray(G,byteIN);
				break;
				case 'T':
				readUSArray(T,byteIN);
				break;
			}
		}
		
	}
	
	
	
	