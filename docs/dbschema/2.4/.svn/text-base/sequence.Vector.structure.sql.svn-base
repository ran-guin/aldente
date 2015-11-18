-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Vector`
--

DROP TABLE IF EXISTS `Vector`;
CREATE TABLE `Vector` (
  `Vector_Name` varchar(40) NOT NULL default '',
  `Vector_Manufacturer` text,
  `Vector_Catalog_Number` text,
  `Vector_Sequence_File` text NOT NULL,
  `Vector_Sequence_Source` text,
  `Antibiotic_Marker` enum('Ampicillin','Zeocin','Kanamycin','Chloramphenicol','Tetracycline','N/A') default NULL,
  `Vector_ID` int(11) NOT NULL auto_increment,
  `Inducer` varchar(40) default NULL,
  `Substrate` varchar(40) default NULL,
  `FKManufacturer_Organization__ID` int(11) default NULL,
  `FKSource_Organization__ID` int(11) default NULL,
  `Vector_Sequence` longtext,
  `FK_Vector_Type__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Vector_ID`),
  KEY `FKSource_Organization__ID` (`FKSource_Organization__ID`),
  KEY `FKManufacturer_Organization__ID` (`FKManufacturer_Organization__ID`)
) TYPE=InnoDB;

