-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `VectorPrimer`
--

DROP TABLE IF EXISTS `VectorPrimer`;
CREATE TABLE `VectorPrimer` (
  `FK_Vector__Name` varchar(80) default NULL,
  `FK_Primer__Name` varchar(40) default NULL,
  `Direction` enum('3''','5''','N/A','3prime','5prime') default NULL,
  `VectorPrimer_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Vector__ID` int(11) NOT NULL default '0',
  `FK_Primer__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`VectorPrimer_ID`),
  UNIQUE KEY `combo` (`FK_Vector__Name`,`FK_Primer__Name`),
  KEY `direction` (`FK_Vector__Name`,`FK_Primer__Name`),
  KEY `FK_Primer__Name` (`FK_Primer__Name`)
) TYPE=InnoDB;

