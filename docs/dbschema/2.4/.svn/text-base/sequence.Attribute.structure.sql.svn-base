-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Attribute`
--

DROP TABLE IF EXISTS `Attribute`;
CREATE TABLE `Attribute` (
  `Attribute_ID` int(11) NOT NULL auto_increment,
  `Attribute_Name` varchar(40) default NULL,
  `Attribute_Format` varchar(40) default NULL,
  `Attribute_Type` varchar(40) default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `Inherited` enum('Yes','No') NOT NULL default 'No',
  `Attribute_Class` varchar(40) default NULL,
  PRIMARY KEY  (`Attribute_ID`),
  UNIQUE KEY `Attribute_Key` (`Attribute_Name`,`Attribute_Class`),
  KEY `grp` (`FK_Grp__ID`)
) TYPE=InnoDB;

