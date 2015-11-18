-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `WorkPackage`
--

DROP TABLE IF EXISTS `WorkPackage`;
CREATE TABLE `WorkPackage` (
  `WorkPackage_ID` int(11) NOT NULL auto_increment,
  `FK_Issue__ID` int(11) default NULL,
  `WorkPackage_File` text,
  `WP_Name` varchar(60) default NULL,
  `WP_Comments` text,
  `WP_Obstacles` text,
  `WP_Priority_Details` text,
  `WP_Description` text,
  PRIMARY KEY  (`WorkPackage_ID`),
  UNIQUE KEY `Name` (`WP_Name`)
) TYPE=MyISAM;

