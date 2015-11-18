-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Sample`
--

DROP TABLE IF EXISTS `Sample`;
CREATE TABLE `Sample` (
  `Sample_ID` int(11) NOT NULL auto_increment,
  `Sample_Name` varchar(40) default NULL,
  `Sample_Type` enum('Clone','Extraction') default NULL,
  `Sample_Comments` text,
  `FKParent_Sample__ID` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Sample_ID`),
  KEY `name` (`Sample_Name`),
  KEY `FKParent_Sample__ID` (`FKParent_Sample__ID`),
  KEY `Sample_Type` (`Sample_Type`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) TYPE=InnoDB;

