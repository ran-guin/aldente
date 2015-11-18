-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Contaminant`
--

DROP TABLE IF EXISTS `Contaminant`;
CREATE TABLE `Contaminant` (
  `Contaminant_ID` int(11) NOT NULL auto_increment,
  `Well` char(3) default NULL,
  `FK_Run__ID` int(11) default NULL,
  `Detection_Date` date default NULL,
  `E_value` float unsigned default NULL,
  `Score` int(11) default NULL,
  `FK_Contamination__ID` int(11) default NULL,
  PRIMARY KEY  (`Contaminant_ID`),
  KEY `run` (`FK_Run__ID`),
  KEY `FK_Contamination__ID` (`FK_Contamination__ID`)
) TYPE=MyISAM;

