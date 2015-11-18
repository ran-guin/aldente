/*
 * Created on Jan 5, 2005
 */
package GCOScontrol;

import java.io.IOException;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.FactoryConfigurationError;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import affymetrix.limssdk.ASSAY_TYPE;
import affymetrix.limssdk.GcdoAssay;
import affymetrix.limssdk.GcdoAttribute;
import affymetrix.limssdk.GcdoChip;
import affymetrix.limssdk.GcdoConnection;
import affymetrix.limssdk.GcdoExperiment;
import affymetrix.limssdk.GcdoSample;
import affymetrix.limssdk.GcdoTemplate;
import affymetrix.limssdk.GcdoVessel;
import affymetrix.limssdk.GcdoWorkflow;
import affymetrix.limssdk.TEMPLATE_TYPE;

/**
 * Class for parsing a GCOS XML Samplesheet
 * @author jsantos
 */
/** TODO add error checking (template does not exist or sample name does not exist (for experiments)
 * 
 */
public class SampleSheet_Parser {

	
	public Document xmlDocument;
	public Vector experiments;
	public Vector samples;
	public GcdoConnection conn;
	
	public SampleSheet_Parser(String file, GcdoConnection conn) {
		experiments = new Vector();
		samples = new Vector();
		this.conn = conn;
		try {
		    DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		    DocumentBuilder builder = factory.newDocumentBuilder();
		    xmlDocument = builder.parse(file);   
		}
		catch (FactoryConfigurationError e) {
		    // unable to get a document builder factory
		} 
		catch (ParserConfigurationException e) {
		    // parser was unable to be configured
		}
		catch (SAXException e) {
		    // parsing error
		} 
		catch (IOException e) {
		    // i/o error
		}	
	}
	
	
	public void parse() {
		// get all parent nodes
		// parent node names will define what type it is 
		// (Experiment, Sample)
		Node rootNode = xmlDocument.getDocumentElement();
		NodeList parentNodes = rootNode.getChildNodes();
		for (int i = 0; i < parentNodes.getLength(); i++) {
			Node parentNode = parentNodes.item(i);
			// if not an ELEMENT node, ignore
			if (parentNode.getNodeType() != Node.ELEMENT_NODE) {
				continue;
			}
			// get template name
			String templateName = "";
			NamedNodeMap parentAttr = parentNode.getAttributes();
			for (int k = 0; k < parentAttr.getLength(); k++) {
				Node subValue = parentAttr.item(k);
				if (subValue.getNodeName().equalsIgnoreCase("template")) {
					templateName = subValue.getNodeValue();
					System.out.println("\ttemplate:"+subValue.getNodeValue());
				}
			}
			
			String parentName = parentNode.getNodeName();
			System.out.println(parentName);
			// loop through all attributes
			NodeList childNodes = parentNode.getChildNodes();
			Hashtable attributes = new Hashtable();		
			for (int j = 0; j < childNodes.getLength(); j++) {
				Node attribute = childNodes.item(j);
				// if not an ELEMENT node, ignore
				if (attribute.getNodeType() != Node.ELEMENT_NODE) {
					continue;
				}		
				NamedNodeMap map = attribute.getAttributes();
				String name = "";
				String value = "";
				for (int k = 0; k < map.getLength(); k++) {
					Node subValue = map.item(k);
					if (subValue.getNodeName().equalsIgnoreCase("name")) {
						name = subValue.getNodeValue();
						System.out.println("\tname:"+subValue.getNodeValue());
					}
					else if (subValue.getNodeName().equalsIgnoreCase("value")) {
						value = subValue.getNodeValue();
						System.out.println("\tvalue:"+subValue.getNodeValue());
					}
				}
				attributes.put(name,value);
			}
			// insert into the proper list (Sample and/or Experiment)
			if (parentName.equalsIgnoreCase("Sample")) {
				// if the key is sample name, sample type, project, or user
				// these are required fields and are inserted specially
				// all required fields have to have a value
				GcdoSample sample = new GcdoSample();
				Enumeration keys = attributes.keys();
				Vector normalAttrib = new Vector();
				
				
				// define extra objects to be created to insert
			    GcdoWorkflow workflow = new GcdoWorkflow();
			    GcdoAssay assay = new GcdoAssay();
			    GcdoVessel vessel = new GcdoVessel();
			    
			    // Read in the template attributes
			    GcdoTemplate template = new GcdoTemplate();
				sample.m_strTemplateName = templateName;
			    template.m_strName = sample.m_strTemplateName;
			    template.m_nType = TEMPLATE_TYPE.SAMPLE_TEMPLATE;
			    
			    // Load template attributes
			    GcdoAttribute[] template_attributes = template.LoadAttributes(conn);
			    
				// grab all required fields
				while (keys.hasMoreElements()) {
					String key = (String)keys.nextElement();
					String value = (String)attributes.get(key);
					if ( key.equalsIgnoreCase("Sample Name") ) {
						sample.m_strName = value;
					}
					else if (key.equalsIgnoreCase("Sample Type")) {
						sample.m_strType = value;
					}
					else if (key.equalsIgnoreCase("Project")) {
						sample.m_strProject = value;
					}
					else if (key.equalsIgnoreCase("User")) {
						sample.m_strUser = value;
					}
					else if (key.equalsIgnoreCase("Date")) {
						sample.m_strDate = value;
					}
					else if (key.equalsIgnoreCase("Assay Type")) {
						if (value.equalsIgnoreCase("Expression")) {
							assay.m_nType = ASSAY_TYPE.EXPRESSION_ASSAY;
						}
						else {	
							assay.m_nType = ASSAY_TYPE.MAPPING_ASSAY;
						}
					}
					else {
					    // do a linear search across template attributes
					    for (int j=0; j<template_attributes.length; j++)
					    {
					        // Get attribute named the same as the current key
					        GcdoAttribute attribute = template_attributes[j];
					        if (attribute.m_strName.equalsIgnoreCase(key)) {
					        	// Only assign attributes that are active
					        	if (attribute.m_bActive == true)
					        	{
					        		System.out.println("Assigning " + key + ":"+ value);
					        		attribute.m_strValue = value;
					        		continue;
					        	}	
					        }
					    }
					}
				}
				// assign template attributes to the sample
				sample.m_aoAttributes = template_attributes;

				// assign barcode name to sample name
			    vessel.m_strBarcode = sample.m_strName;
				Hashtable sampleHash = new Hashtable();
				sampleHash.put("workflow",workflow);
				sampleHash.put("assay",assay);
				sampleHash.put("vessel",vessel);
				sampleHash.put("sample",sample);
				samples.add(sampleHash);
			}
			else if (parentName.equalsIgnoreCase("Experiment")) {
				// if the key is experiment name, probe array type, or user
				// these are required fields and are inserted specially
				// all required fields have to have a value
				GcdoExperiment exp = new GcdoExperiment();	
				exp.m_strTemplateName = templateName;
			    GcdoWorkflow workflow = new GcdoWorkflow();
			    GcdoSample sample = new GcdoSample();
			    GcdoChip chip = new GcdoChip();
			    
			    // Read in the template attributes
			    GcdoTemplate template = new GcdoTemplate();
				sample.m_strTemplateName = templateName;
			    template.m_strName = sample.m_strTemplateName;
			    template.m_nType = TEMPLATE_TYPE.EXPERIMENT_TEMPLATE;
			    
			    // Load template attributes
			    GcdoAttribute[] template_attributes = template.LoadAttributes(conn);
			    
				Enumeration keys = attributes.keys();
				Vector normalAttrib = new Vector();
				// grab all required fields
				while (keys.hasMoreElements()) {
					String key = (String)keys.nextElement();
					String value = (String)attributes.get(key);
					if ( key.equalsIgnoreCase("Experiment Name") ) {
						exp.m_strName = value;
					}
					else if (key.equalsIgnoreCase("Probe Array Type")) {
						exp.m_strType = value;
						chip.m_strChipType = value;
					}
					else if (key.equalsIgnoreCase("User")) {
						exp.m_strUser = value;
					}
					else if (key.equalsIgnoreCase("Date")) {
						exp.m_strDate = value;
					}
					else if (key.equalsIgnoreCase("Sample Name")) {
						sample.m_strName = value;
					}
					else if (key.equalsIgnoreCase("Chip Barcode")) {
					    chip.m_strBarcode = value;
					}
					else {
					    // do a linear search across template attributes
					    for (int j=0; j<template_attributes.length; j++)
					    {
					        // Get attribute named the same as the current key
					        GcdoAttribute attribute = template_attributes[j];
					        if (attribute.m_strName.equalsIgnoreCase(key)) {
					        	// Only assign attributes that are active
					        	if (attribute.m_bActive == true)
					        	{
					        		attribute.m_strValue = value;
					        		continue;
					        	}	
					        }
					    }
					}
				}
				exp.m_aoAttributes = template_attributes;
				exp.m_oChip = chip;
				
				
				Hashtable expHash = new Hashtable();
				expHash.put("workflow",workflow);
				expHash.put("sample",sample);
				expHash.put("experiment",exp);
				
				experiments.add(expHash);	
			}
			else {
				// continue to next one, invalid type
				continue;
			}
		}
	}
}
