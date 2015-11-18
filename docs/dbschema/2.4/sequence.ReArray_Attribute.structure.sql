-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `ReArray_Attribute`
--

DROP TABLE IF EXISTS `ReArray_Attribute`;
CREATE TABLE `ReArray_Attribute` (
  `ReArray_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `FK_ReArray__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text,
  PRIMARY KEY  (`ReArray_Attribute_ID`),
  UNIQUE KEY `Attribute_ReArray` (`FK_Attribute__ID`,`FK_ReArray__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`),
  KEY `FK_ReArray__ID` (`FK_ReArray__ID`)
) TYPE=InnoDB;

