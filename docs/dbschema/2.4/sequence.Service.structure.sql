-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Service`
--

DROP TABLE IF EXISTS `Service`;
CREATE TABLE `Service` (
  `FK_Equipment__ID` int(11) default NULL,
  `FK_Equipment__Type` varchar(40) default NULL,
  `Service_Interval` tinyint(4) default NULL,
  `Interval_Frequency` enum('Year','Month','Week','Day') default NULL,
  `Service_Name` text,
  `Service_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Service_ID`),
  UNIQUE KEY `service` (`FK_Equipment__ID`,`FK_Equipment__Type`),
  KEY `FK_Equipment__Type` (`FK_Equipment__Type`)
) TYPE=InnoDB;

