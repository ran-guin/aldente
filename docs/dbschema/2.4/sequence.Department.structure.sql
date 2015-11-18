-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Department`
--

DROP TABLE IF EXISTS `Department`;
CREATE TABLE `Department` (
  `Department_ID` int(11) NOT NULL auto_increment,
  `Department_Name` char(40) default NULL,
  `Department_Status` enum('Active','Inactive') default NULL,
  PRIMARY KEY  (`Department_ID`)
) TYPE=InnoDB;

