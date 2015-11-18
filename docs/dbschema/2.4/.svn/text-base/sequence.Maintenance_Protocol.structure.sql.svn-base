-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Maintenance_Protocol`
--

DROP TABLE IF EXISTS `Maintenance_Protocol`;
CREATE TABLE `Maintenance_Protocol` (
  `Maintenance_Protocol_ID` int(11) NOT NULL auto_increment,
  `FK_Service__Name` varchar(40) default NULL,
  `Step` int(11) default NULL,
  `Maintenance_Step_Name` varchar(40) default NULL,
  `Maintenance_Instructions` text,
  `FK_Employee__ID` int(11) default NULL,
  `Protocol_Date` date default '0000-00-00',
  `Maintenance_Protocol_Name` text,
  `FK_Contact__ID` int(11) default NULL,
  PRIMARY KEY  (`Maintenance_Protocol_ID`),
  UNIQUE KEY `step` (`FK_Service__Name`,`Step`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`)
) TYPE=InnoDB;

