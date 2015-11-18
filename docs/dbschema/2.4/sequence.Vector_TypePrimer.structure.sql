-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Vector_TypePrimer`
--

DROP TABLE IF EXISTS `Vector_TypePrimer`;
CREATE TABLE `Vector_TypePrimer` (
  `Vector_TypePrimer_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Vector_Type__ID` int(11) NOT NULL default '0',
  `FK_Primer__ID` int(11) NOT NULL default '0',
  `Direction` enum('N/A','3prime','5prime') default NULL,
  PRIMARY KEY  (`Vector_TypePrimer_ID`),
  UNIQUE KEY `combo` (`FK_Vector_Type__ID`,`FK_Primer__ID`),
  KEY `FK_Vector_Type__ID` (`FK_Vector_Type__ID`),
  KEY `FK_Primer__ID` (`FK_Primer__ID`)
) TYPE=InnoDB;

