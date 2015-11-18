-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Maintenance`
--

DROP TABLE IF EXISTS `Maintenance`;
CREATE TABLE `Maintenance` (
  `Maintenance_ID` int(11) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `Maintenance_Process` text,
  `Maintenance_Description` text NOT NULL,
  `Maintenance_DateTime` datetime default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `FK_Contact__ID` int(11) default NULL,
  `FK_Solution__ID` int(11) default NULL,
  `Maintenance_Cost` float default NULL,
  `Maintenance_Finished` datetime default NULL,
  `FKMaintenance_Status__ID` int(11) default '0',
  PRIMARY KEY  (`Maintenance_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`)
) TYPE=InnoDB;

