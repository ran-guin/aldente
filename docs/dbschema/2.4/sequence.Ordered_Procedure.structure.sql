-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Ordered_Procedure`
--

DROP TABLE IF EXISTS `Ordered_Procedure`;
CREATE TABLE `Ordered_Procedure` (
  `Ordered_Procedure_ID` int(11) NOT NULL auto_increment,
  `Object_Name` varchar(40) default NULL,
  `Object_ID` int(11) NOT NULL default '0',
  `Procedure_Order` tinyint(4) NOT NULL default '0',
  `FK_Pipeline__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Ordered_Procedure_ID`),
  KEY `Object_ID` (`Object_ID`),
  KEY `Object_Name` (`Object_Name`)
) TYPE=InnoDB;

