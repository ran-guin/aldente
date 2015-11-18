-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Sample_Alias`
--

DROP TABLE IF EXISTS `Sample_Alias`;
CREATE TABLE `Sample_Alias` (
  `Sample_Alias_ID` int(11) NOT NULL auto_increment,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FKSource_Organization__ID` int(11) NOT NULL default '0',
  `Alias` varchar(40) default NULL,
  `Alias_Type` varchar(40) default NULL,
  PRIMARY KEY  (`Sample_Alias_ID`),
  UNIQUE KEY `spec` (`FK_Sample__ID`,`Alias_Type`,`Alias`),
  KEY `sample` (`FK_Sample__ID`),
  KEY `alias` (`Alias`),
  KEY `type` (`Alias_Type`),
  KEY `FKSource_Organization__ID` (`FKSource_Organization__ID`)
) TYPE=InnoDB;

