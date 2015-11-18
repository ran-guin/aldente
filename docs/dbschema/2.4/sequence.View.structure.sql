-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `View`
--

DROP TABLE IF EXISTS `View`;
CREATE TABLE `View` (
  `View_ID` int(10) unsigned NOT NULL auto_increment,
  `View_Name` varchar(40) default NULL,
  `View_Description` text,
  `View_Tables` text,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`View_ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) TYPE=InnoDB;

