-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Prep_Attribute_Option`
--

DROP TABLE IF EXISTS `Prep_Attribute_Option`;
CREATE TABLE `Prep_Attribute_Option` (
  `Prep_Attribute_Option_ID` int(11) NOT NULL auto_increment,
  `FK_Protocol_Step__ID` int(11) NOT NULL default '0',
  `Option_Description` text,
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Prep_Attribute_Option_ID`),
  KEY `FK_Protocol_Step__ID` (`FK_Protocol_Step__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) TYPE=InnoDB;

