-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Submission_Volume`
--

DROP TABLE IF EXISTS `Submission_Volume`;
CREATE TABLE `Submission_Volume` (
  `Submission_Volume_ID` int(11) NOT NULL auto_increment,
  `Submission_Target` text,
  `Volume_Name` varchar(40) NOT NULL default '',
  `Submission_Date` date default NULL,
  `FKSubmitter_Employee__ID` int(11) default NULL,
  `Volume_Status` enum('In Process','Bundled','Submitted','Accepted','Rejected') default NULL,
  `Volume_Comments` text,
  `Records` int(11) NOT NULL default '0',
  `Approved_Date` date default NULL,
  PRIMARY KEY  (`Submission_Volume_ID`),
  UNIQUE KEY `name` (`Volume_Name`),
  KEY `FKSubmitter_Employee__ID` (`FKSubmitter_Employee__ID`)
) TYPE=MyISAM;

