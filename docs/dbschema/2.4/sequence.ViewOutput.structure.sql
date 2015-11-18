-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `ViewOutput`
--

DROP TABLE IF EXISTS `ViewOutput`;
CREATE TABLE `ViewOutput` (
  `ViewOutput_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_View__ID` int(11) NOT NULL default '0',
  `Output_Field` varchar(80) default '',
  PRIMARY KEY  (`ViewOutput_ID`),
  KEY `FK_View__ID` (`FK_View__ID`)
) TYPE=InnoDB;

