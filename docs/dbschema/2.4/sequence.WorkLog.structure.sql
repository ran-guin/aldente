-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `WorkLog`
--

DROP TABLE IF EXISTS `WorkLog`;
CREATE TABLE `WorkLog` (
  `WorkLog_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Work_Date` date default NULL,
  `Hours_Spent` decimal(6,2) default NULL,
  `FK_Issue__ID` int(11) default NULL,
  `Log_Date` date default NULL,
  `Log_Notes` text,
  `Revised_ETA` decimal(10,0) default NULL,
  `FK_Grp__ID` int(11) default '0',
  PRIMARY KEY  (`WorkLog_ID`)
) TYPE=MyISAM;

