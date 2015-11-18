-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `ReArray_Plate`
--

DROP TABLE IF EXISTS `ReArray_Plate`;
CREATE TABLE `ReArray_Plate` (
  `ReArray_Plate_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`ReArray_Plate_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) TYPE=InnoDB;

