-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Lane`
--

DROP TABLE IF EXISTS `Lane`;
CREATE TABLE `Lane` (
  `Lane_ID` int(11) NOT NULL auto_increment,
  `FK_GelRun__ID` int(11) default NULL,
  `FK_Sample__ID` int(11) default NULL,
  `Lane_Number` int(11) default NULL,
  `Lane_Status` enum('Passed','Failed') default NULL,
  `Band_Size_Estimate` int(11) default NULL,
  `Bands_Count` int(11) default NULL,
  `Well` char(3) NOT NULL default '',
  PRIMARY KEY  (`Lane_ID`),
  KEY `FK_GelRun__ID` (`FK_GelRun__ID`,`FK_Sample__ID`)
) TYPE=InnoDB;

