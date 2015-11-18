-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Clone_Source`
--

DROP TABLE IF EXISTS `Clone_Source`;
CREATE TABLE `Clone_Source` (
  `Clone_Source_ID` int(11) NOT NULL auto_increment,
  `Source_Description` varchar(40) default NULL,
  `FK_Clone_Sample__ID` int(11) NOT NULL default '0',
  `FK_Plate__ID` int(11) default NULL,
  `Clone_Quadrant` enum('a','b','c','d') default NULL,
  `Clone_Well` char(3) default NULL,
  `Well_384` char(3) default NULL,
  `FKSource_Organization__ID` int(11) default NULL,
  `Source_Name` varchar(40) default NULL,
  `Source_Comments` text,
  `Source_Library_ID` varchar(40) default NULL,
  `Source_Collection` varchar(40) default NULL,
  `Source_Library_Name` varchar(40) default NULL,
  `Source_Row` varchar(4) NOT NULL default '',
  `Source_Col` varchar(4) NOT NULL default '',
  `Source_5Prime_Site` text,
  `Source_Plate` int(11) default NULL,
  `Source_3Prime_Site` text,
  `Source_Vector` varchar(40) default NULL,
  `Source_Score` int(11) default NULL,
  `3prime_tag` varchar(40) default NULL,
  `5prime_tag` varchar(40) default NULL,
  `Source_Clone_Name` varchar(40) default NULL,
  `Source_Clone_Name_Type` varchar(40) default NULL,
  PRIMARY KEY  (`Clone_Source_ID`),
  KEY `clonesource_plate` (`FK_Plate__ID`),
  KEY `clonesource_clone` (`FK_Clone_Sample__ID`),
  KEY `clone` (`FK_Clone_Sample__ID`),
  KEY `name` (`Source_Name`),
  KEY `library` (`Source_Library_Name`),
  KEY `plate` (`Source_Plate`),
  KEY `well` (`Source_Collection`,`Source_Plate`,`Source_Row`,`Source_Col`),
  KEY `source_org_id` (`FKSource_Organization__ID`)
) TYPE=InnoDB;

