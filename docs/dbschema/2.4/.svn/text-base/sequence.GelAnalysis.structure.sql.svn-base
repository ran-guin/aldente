-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GelAnalysis`
--

DROP TABLE IF EXISTS `GelAnalysis`;
CREATE TABLE `GelAnalysis` (
  `GelAnalysis_ID` int(11) NOT NULL auto_increment,
  `FK_GelRun__ID` int(11) default NULL,
  `GelAnalysis_DateTime` date NOT NULL default '0000-00-00',
  `Bandleader_Version` varchar(15) NOT NULL default '',
  PRIMARY KEY  (`GelAnalysis_ID`),
  KEY `FK_GelRun__ID` (`FK_GelRun__ID`)
) TYPE=InnoDB;

