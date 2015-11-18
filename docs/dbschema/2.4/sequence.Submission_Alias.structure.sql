-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Submission_Alias`
--

DROP TABLE IF EXISTS `Submission_Alias`;
CREATE TABLE `Submission_Alias` (
  `Submission_Alias_ID` int(11) NOT NULL auto_increment,
  `FK_Trace_Submission__ID` int(11) NOT NULL default '0',
  `Submission_Reference` char(40) default NULL,
  `Submission_Reference_Type` enum('Genbank_ID','Accession_ID') default NULL,
  PRIMARY KEY  (`Submission_Alias_ID`),
  UNIQUE KEY `ref` (`Submission_Reference_Type`,`Submission_Reference`),
  KEY `FK_Trace_Submission__ID` (`FK_Trace_Submission__ID`)
) TYPE=MyISAM;

