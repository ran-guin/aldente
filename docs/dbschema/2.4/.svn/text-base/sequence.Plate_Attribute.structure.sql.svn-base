-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Plate_Attribute`
--

DROP TABLE IF EXISTS `Plate_Attribute`;
CREATE TABLE `Plate_Attribute` (
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `Plate_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Plate_Attribute_ID`),
  UNIQUE KEY `FK_Attribute__ID_2` (`FK_Attribute__ID`,`FK_Plate__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) TYPE=InnoDB;

