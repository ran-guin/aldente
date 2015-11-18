-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Sequencing_Library`
--

DROP TABLE IF EXISTS `Sequencing_Library`;
CREATE TABLE `Sequencing_Library` (
  `Sequencing_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) NOT NULL default '',
  `Sequencing_Library_Type` enum('SAGE','cDNA','Genomic','EST','Transposon','PCR','Test') default NULL,
  `FK_Vector__Name` varchar(40) default NULL,
  `Host` text NOT NULL,
  `Organism` varchar(40) default NULL,
  `Sex` varchar(20) default NULL,
  `Tissue` varchar(40) default NULL,
  `Strain` varchar(40) default NULL,
  `FK_Vector__ID` int(11) default NULL,
  `Colonies_Screened` int(11) default NULL,
  `Clones_NoInsert_Percent` int(11) default NULL,
  `AvgInsertSize` int(11) default NULL,
  `InsertSizeMin` int(11) default NULL,
  `InsertSizeMax` int(11) default NULL,
  `Source_RNA` text,
  `BlueWhiteSelection` enum('Yes','No') default NULL,
  `Sequencing_Library_Format` set('Ligation','Transformed Cells','Microtiter Plates','ReArrayed') default NULL,
  `FKVector_Organization__ID` int(11) default NULL,
  `Vector_Type` enum('Plasmid','Fosmid','Cosmid','BAC') default NULL,
  `Vector_Catalog_Number` text,
  `Antibiotic_Concentration` float default NULL,
  `FK3Prime_Restriction_Site__ID` int(11) default NULL,
  `FK5Prime_Restriction_Site__ID` int(11) default NULL,
  PRIMARY KEY  (`Sequencing_Library_ID`),
  UNIQUE KEY `FK_Library__Name` (`FK_Library__Name`),
  KEY `FKVector_Organization__ID` (`FKVector_Organization__ID`),
  KEY `FK3Prime_Restriction_Site__ID` (`FK3Prime_Restriction_Site__ID`),
  KEY `FK_Vector__Name` (`FK_Vector__Name`),
  KEY `FK_Vector__ID` (`FK_Vector__ID`),
  KEY `FK5Prime_Restriction_Site__ID` (`FK5Prime_Restriction_Site__ID`)
) TYPE=InnoDB;

