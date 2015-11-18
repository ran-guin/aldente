-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Enzyme`
--

DROP TABLE IF EXISTS `Enzyme`;
CREATE TABLE `Enzyme` (
  `Enzyme_ID` int(11) NOT NULL auto_increment,
  `Enzyme_Name` varchar(8) NOT NULL default '',
  `Enzyme_Seqeunce` text,
  PRIMARY KEY  (`Enzyme_ID`)
) TYPE=InnoDB;

