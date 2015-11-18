-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Pipeline`
--

DROP TABLE IF EXISTS `Pipeline`;
CREATE TABLE `Pipeline` (
  `Pipeline_ID` int(11) NOT NULL auto_increment,
  `Pipeline_Name` varchar(40) default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `Pipeline_Description` text,
  PRIMARY KEY  (`Pipeline_ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) TYPE=InnoDB;

