-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Ligation`
--

DROP TABLE IF EXISTS `Ligation`;
CREATE TABLE `Ligation` (
  `Ligation_ID` int(11) NOT NULL auto_increment,
  `Ligation_Volume` int(11) default NULL,
  `cfu` int(11) default NULL,
  `Label` varchar(40) default NULL,
  `Sequencing_Type` enum('Primers','Transposon','Primers_and_transposon','Replicates','N/A') default NULL,
  `384_Well_Plates_To_Seq` int(11) default NULL,
  `FKExtraction_Plate__ID` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `384_Well_Plates_To_Pick` int(11) default '0',
  PRIMARY KEY  (`Ligation_ID`),
  KEY `FKExtraction_Plate__ID` (`FKExtraction_Plate__ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) TYPE=InnoDB;

