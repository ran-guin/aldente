-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `SS_Option`
--

DROP TABLE IF EXISTS `SS_Option`;
CREATE TABLE `SS_Option` (
  `SS_Option_ID` int(11) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `SS_Option_Alias` char(80) default NULL,
  `SS_Option_Value` char(80) default NULL,
  `FK_SS_Config__ID` int(11) default NULL,
  `SS_Option_Order` tinyint(4) default NULL,
  `SS_Option_Status` enum('Active','Inactive','Default','AutoSet') NOT NULL default 'Active',
  `FKReference_SS_Option__ID` int(11) default NULL,
  PRIMARY KEY  (`SS_Option_ID`),
  KEY `FKReference_SS_Option__ID` (`FKReference_SS_Option__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_SS_Config__ID` (`FK_SS_Config__ID`)
) TYPE=InnoDB;

