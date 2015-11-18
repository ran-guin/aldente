-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Submission_Detail`
--

DROP TABLE IF EXISTS `Submission_Detail`;
CREATE TABLE `Submission_Detail` (
  `Submission_Detail_ID` int(11) NOT NULL auto_increment,
  `FK_Submission__ID` int(11) NOT NULL default '0',
  `FKSubmission_DBTable__ID` int(11) NOT NULL default '0',
  `Reference` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`Submission_Detail_ID`),
  KEY `FKSubmission_DBTable__ID` (`FKSubmission_DBTable__ID`),
  KEY `FK_Submission__ID` (`FK_Submission__ID`)
) TYPE=InnoDB;

