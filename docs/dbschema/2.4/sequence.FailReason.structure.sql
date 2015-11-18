-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `FailReason`
--

DROP TABLE IF EXISTS `FailReason`;
CREATE TABLE `FailReason` (
  `FailReason_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FailReason_Name` varchar(40) default NULL,
  `FailReason_Description` text,
  `FK_Object_Class__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`FailReason_ID`),
  UNIQUE KEY `Unique_type_name` (`FailReason_Name`,`FK_Object_Class__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Object_Class__ID` (`FK_Object_Class__ID`)
) TYPE=InnoDB;

