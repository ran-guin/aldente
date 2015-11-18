-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Submission_Info`
--

DROP TABLE IF EXISTS `Submission_Info`;
CREATE TABLE `Submission_Info` (
  `Submission_Info_ID` int(11) NOT NULL auto_increment,
  `FK_Submission__ID` int(11) NOT NULL default '0',
  `Submission_Comments` text,
  `FK_Grp__ID` int(11) default NULL,
  PRIMARY KEY  (`Submission_Info_ID`),
  KEY `FK_Submission__ID` (`FK_Submission__ID`)
) TYPE=InnoDB;

