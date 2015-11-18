-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Agilent_Assay`
--

DROP TABLE IF EXISTS `Agilent_Assay`;
CREATE TABLE `Agilent_Assay` (
  `Agilent_Assay_ID` int(11) NOT NULL auto_increment,
  `Agilent_Assay_Name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`Agilent_Assay_ID`),
  KEY `name` (`Agilent_Assay_Name`)
) TYPE=InnoDB;

