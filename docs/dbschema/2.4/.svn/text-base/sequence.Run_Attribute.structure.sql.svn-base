-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Run_Attribute`
--

DROP TABLE IF EXISTS `Run_Attribute`;
CREATE TABLE `Run_Attribute` (
  `Run_Attribute_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Attribute_Value` text NOT NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Set_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`Run_Attribute_ID`),
  UNIQUE KEY `run_attribute` (`FK_Attribute__ID`,`FK_Run__ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) TYPE=InnoDB;

