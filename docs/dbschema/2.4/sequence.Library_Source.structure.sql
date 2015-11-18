-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Library_Source`
--

DROP TABLE IF EXISTS `Library_Source`;
CREATE TABLE `Library_Source` (
  `Library_Source_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `FK_Library__Name` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`Library_Source_ID`),
  KEY `FK_Library__Name` (`FK_Library__Name`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) TYPE=InnoDB;

