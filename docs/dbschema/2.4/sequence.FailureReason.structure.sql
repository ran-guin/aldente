-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `FailureReason`
--

DROP TABLE IF EXISTS `FailureReason`;
CREATE TABLE `FailureReason` (
  `FailureReason_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FailureReason_Name` varchar(40) default NULL,
  `Failure_Description` text,
  PRIMARY KEY  (`FailureReason_ID`),
  UNIQUE KEY `failurereason_name_nique` (`FailureReason_Name`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) TYPE=InnoDB;

