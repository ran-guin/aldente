-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Event`
--

DROP TABLE IF EXISTS `Event`;
CREATE TABLE `Event` (
  `Event_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Event_Type` enum('Inventory') default NULL,
  `Event_Start` datetime NOT NULL default '0000-00-00 00:00:00',
  `Event_Finish` datetime NOT NULL default '0000-00-00 00:00:00',
  `FKEvent_Status__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Event_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FKEvent_Status__ID` (`FKEvent_Status__ID`)
) TYPE=InnoDB;

