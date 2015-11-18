-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Version`
--

DROP TABLE IF EXISTS `Version`;
CREATE TABLE `Version` (
  `Version_ID` int(11) NOT NULL auto_increment,
  `Version_Name` varchar(8) default NULL,
  `Version_Description` text,
  `Release_Date` date default NULL,
  `Last_Modified_Date` date default NULL,
  PRIMARY KEY  (`Version_ID`)
) TYPE=InnoDB;

