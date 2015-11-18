-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `LibraryPrimer`
--

DROP TABLE IF EXISTS `LibraryPrimer`;
CREATE TABLE `LibraryPrimer` (
  `LibraryPrimer_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) default NULL,
  `FK_Primer__Name` varchar(40) default NULL,
  `Clones_Estimate` int(11) NOT NULL default '0',
  `TagsRequested` int(11) NOT NULL default '0',
  `Direction` enum('3prime','5prime','N/A','Unknown') default NULL,
  PRIMARY KEY  (`LibraryPrimer_ID`),
  UNIQUE KEY `combo` (`FK_Library__Name`,`FK_Primer__Name`),
  KEY `FK_Primer__Name` (`FK_Primer__Name`)
) TYPE=InnoDB;

