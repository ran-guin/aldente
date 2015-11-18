-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Study`
--

DROP TABLE IF EXISTS `Study`;
CREATE TABLE `Study` (
  `Study_ID` int(11) NOT NULL auto_increment,
  `Study_Name` varchar(40) NOT NULL default '',
  `Study_Description` text,
  `Study_Initiated` date default NULL,
  PRIMARY KEY  (`Study_ID`),
  UNIQUE KEY `study_name` (`Study_Name`)
) TYPE=InnoDB;

