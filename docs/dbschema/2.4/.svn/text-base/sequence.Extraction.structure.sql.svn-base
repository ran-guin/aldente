-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Extraction`
--

DROP TABLE IF EXISTS `Extraction`;
CREATE TABLE `Extraction` (
  `Extraction_ID` int(11) NOT NULL auto_increment,
  `FKSource_Plate__ID` int(11) NOT NULL default '0',
  `FKTarget_Plate__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Extraction_ID`),
  KEY `source_plate` (`FKSource_Plate__ID`),
  KEY `target_plate` (`FKTarget_Plate__ID`)
) TYPE=InnoDB;

