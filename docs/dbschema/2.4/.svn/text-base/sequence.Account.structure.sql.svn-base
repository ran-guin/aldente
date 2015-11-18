-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Account`
--

DROP TABLE IF EXISTS `Account`;
CREATE TABLE `Account` (
  `Account_ID` int(11) NOT NULL default '0',
  `Account_Description` text,
  `Account_Type` text,
  `Account_Name` text,
  `Account_Dept` enum('Orders','Admin') default NULL,
  PRIMARY KEY  (`Account_ID`)
) TYPE=InnoDB;

