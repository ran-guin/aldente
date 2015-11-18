-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Clone_Alias`
--

DROP TABLE IF EXISTS `Clone_Alias`;
CREATE TABLE `Clone_Alias` (
  `Clone_Alias_ID` int(11) NOT NULL auto_increment,
  `FK_Clone_Sample__ID` int(11) NOT NULL default '0',
  `FKSource_Organization__ID` int(11) default NULL,
  `Source` char(80) default NULL,
  `Alias` char(80) default NULL,
  `Alias_Type` enum('Primary','Secondary') default NULL,
  PRIMARY KEY  (`Clone_Alias_ID`),
  KEY `name` (`Alias`),
  KEY `source` (`Source`),
  KEY `organization` (`FKSource_Organization__ID`),
  KEY `clone` (`FK_Clone_Sample__ID`)
) TYPE=InnoDB;

