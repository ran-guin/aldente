-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Cross_Match`
--

DROP TABLE IF EXISTS `Cross_Match`;
CREATE TABLE `Cross_Match` (
  `FK_Run__ID` int(11) default NULL,
  `Well` char(3) default NULL,
  `Match_Name` char(80) default NULL,
  `Match_Start` int(11) default NULL,
  `Match_Stop` int(11) default NULL,
  `Cross_Match_Date` date default NULL,
  `Cross_Match_ID` int(11) NOT NULL auto_increment,
  `Match_Direction` enum('','C') default NULL,
  PRIMARY KEY  (`Cross_Match_ID`),
  KEY `well` (`FK_Run__ID`,`Well`)
) TYPE=MyISAM;

