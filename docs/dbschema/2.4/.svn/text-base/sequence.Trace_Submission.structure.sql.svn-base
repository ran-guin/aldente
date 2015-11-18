-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Trace_Submission`
--

DROP TABLE IF EXISTS `Trace_Submission`;
CREATE TABLE `Trace_Submission` (
  `Trace_Submission_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) default NULL,
  `Well` char(4) NOT NULL default '',
  `Submission_Status` enum('Bundled','In Process','Accepted','Rejected') default NULL,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Submitted_Length` int(11) NOT NULL default '0',
  `FK_Submission_Volume__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Trace_Submission_ID`),
  UNIQUE KEY `sequence_read` (`FK_Run__ID`,`Well`,`FK_Submission_Volume__ID`),
  KEY `length` (`Submitted_Length`),
  KEY `FK_Sample__ID` (`FK_Sample__ID`),
  KEY `FK_Submission_Volume__ID` (`FK_Submission_Volume__ID`)
) TYPE=MyISAM;

