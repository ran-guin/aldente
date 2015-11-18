-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Issue_Log`
--

DROP TABLE IF EXISTS `Issue_Log`;
CREATE TABLE `Issue_Log` (
  `Issue_Log_ID` int(11) NOT NULL auto_increment,
  `FK_Issue__ID` int(11) NOT NULL default '0',
  `FKSubmitted_Employee__ID` int(11) default NULL,
  `Submitted_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Log` text NOT NULL,
  PRIMARY KEY  (`Issue_Log_ID`),
  KEY `FKSubmitted_Employee__ID` (`FKSubmitted_Employee__ID`),
  KEY `FK_Issue__ID` (`FK_Issue__ID`)
) TYPE=InnoDB;

