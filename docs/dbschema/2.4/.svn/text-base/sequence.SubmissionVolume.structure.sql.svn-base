-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `SubmissionVolume`
--

DROP TABLE IF EXISTS `SubmissionVolume`;
CREATE TABLE `SubmissionVolume` (
  `SubmissionVolume_ID` int(11) NOT NULL auto_increment,
  `Volume_Name` varchar(40) default NULL,
  `FKContact_Employee__ID` int(11) NOT NULL default '0',
  `Submission_Status` enum('Sent','In Process','Pending','Accepted','Rejected') default NULL,
  `Submission_DateTime` date default NULL,
  `Volume_Description` text,
  PRIMARY KEY  (`SubmissionVolume_ID`),
  KEY `FKContact_Employee__ID` (`FKContact_Employee__ID`)
) TYPE=MyISAM;

