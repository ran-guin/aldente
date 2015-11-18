-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Source_Attribute`
--

DROP TABLE IF EXISTS `Source_Attribute`;
CREATE TABLE `Source_Attribute` (
  `Source_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Source_Attribute_ID`),
  UNIQUE KEY `source_attribute` (`FK_Source__ID`,`FK_Attribute__ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) TYPE=InnoDB;

