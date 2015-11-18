-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GCOS_Config_Attribute`
--

DROP TABLE IF EXISTS `GCOS_Config_Attribute`;
CREATE TABLE `GCOS_Config_Attribute` (
  `GCOS_Config_Attribute_ID` int(11) NOT NULL auto_increment,
  `Attribute_Type` enum('Field','Prep') default NULL,
  `Attribute_Name` char(50) NOT NULL default '',
  `Attribute_Table` char(50) default '',
  `Attribute_Step` char(50) default '',
  `Attribute_Field` char(50) NOT NULL default '',
  `FK_GCOS_Config__ID` int(11) NOT NULL default '0',
  `Attribute_Default` char(50) default NULL,
  `Attribute_Usage` set('Sample','Experiment') default NULL,
  PRIMARY KEY  (`GCOS_Config_Attribute_ID`)
) TYPE=InnoDB;

