-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Sample_Attribute`
--

DROP TABLE IF EXISTS `Sample_Attribute`;
CREATE TABLE `Sample_Attribute` (
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `Sample_Attribute_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Sample_Attribute_ID`),
  UNIQUE KEY `sample_attribute` (`FK_Sample__ID`,`FK_Attribute__ID`),
  KEY `FK_Sample__ID` (`FK_Sample__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) TYPE=InnoDB;

