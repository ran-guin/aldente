-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Original_Source_Attribute`
--

DROP TABLE IF EXISTS `Original_Source_Attribute`;
CREATE TABLE `Original_Source_Attribute` (
  `FK_Original_Source__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `Original_Source_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Original_Source_Attribute_ID`),
  UNIQUE KEY `original_source_attribute` (`FK_Original_Source__ID`,`FK_Attribute__ID`),
  KEY `FK_Original_Source__ID` (`FK_Original_Source__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) TYPE=InnoDB;

