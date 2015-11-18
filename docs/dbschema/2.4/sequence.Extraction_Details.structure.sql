-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Extraction_Details`
--

DROP TABLE IF EXISTS `Extraction_Details`;
CREATE TABLE `Extraction_Details` (
  `Extraction_Details_ID` int(11) NOT NULL auto_increment,
  `FK_Extraction_Sample__ID` int(11) NOT NULL default '0',
  `RNA_Isolated_Date` date default NULL,
  `FKIsolated_Employee__ID` int(11) default NULL,
  `Disruption_Method` enum('Homogenized','Sheared') default NULL,
  `Isolation_Method` enum('Trizol','Qiagen Kit') default NULL,
  `Resuspension_Volume` int(11) default NULL,
  `Resuspension_Volume_Units` enum('ul') default NULL,
  `Amount_RNA_Source_Used` int(11) default NULL,
  `Amount_RNA_Source_Used_Units` enum('Cells','Gram of Tissue','Embryos','Litters','Organs','ug/ng') default NULL,
  `FK_Agilent_Assay__ID` int(11) NOT NULL default '0',
  `Assay_Quality` enum('Degraded','Partially Degraded','Good') default NULL,
  `Assay_Quantity` int(11) default NULL,
  `Assay_Quantity_Units` enum('ug/ul','ng/ul','pg/ul') default NULL,
  `Total_Yield` int(11) default NULL,
  `Total_Yield_Units` enum('ug','ng','pg') default NULL,
  `Extraction_Size_Estimate` int(11) default NULL,
  `FK_Band__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Extraction_Details_ID`),
  KEY `extraction_sample__id` (`FK_Extraction_Sample__ID`),
  KEY `isolated_employee_id` (`FKIsolated_Employee__ID`),
  KEY `agilent_assay_id` (`FK_Agilent_Assay__ID`),
  KEY `band_id` (`FK_Band__ID`)
) TYPE=InnoDB;

