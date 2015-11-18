-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Goal`
--

DROP TABLE IF EXISTS `Goal`;
CREATE TABLE `Goal` (
  `Goal_ID` int(11) NOT NULL auto_increment,
  `Goal_Name` varchar(255) default NULL,
  `Goal_Description` text,
  `Goal_Query` text,
  `Goal_Tables` varchar(255) default NULL,
  `Goal_Count` varchar(255) default NULL,
  `Goal_Condition` varchar(255) default NULL,
  PRIMARY KEY  (`Goal_ID`)
) TYPE=MyISAM;

