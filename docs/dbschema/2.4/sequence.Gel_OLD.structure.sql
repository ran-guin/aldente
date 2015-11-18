-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Gel_OLD`
--

DROP TABLE IF EXISTS `Gel_OLD`;
CREATE TABLE `Gel_OLD` (
  `Gel_ID` int(10) unsigned NOT NULL default '0',
  `FK_Plate__ID` int(11) default NULL,
  `Gel_Name` varchar(13) NOT NULL default '',
  `Gel_Comments` text,
  `Gel_Date` datetime default NULL,
  `FK_Employee__ID` int(11) default NULL,
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`)
) TYPE=InnoDB;

