-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Organization`
--

DROP TABLE IF EXISTS `Organization`;
CREATE TABLE `Organization` (
  `Organization_Name` varchar(80) default NULL,
  `Address` text,
  `City` text,
  `State` text,
  `Zip` text,
  `Phone` text,
  `Fax` text,
  `Email` text,
  `Country` text,
  `Notes` text,
  `Organization_ID` int(11) NOT NULL auto_increment,
  `Organization_Type` set('Manufacturer','Collaborator') default NULL,
  `Website` text,
  `Organization_FullName` text,
  PRIMARY KEY  (`Organization_ID`),
  UNIQUE KEY `name` (`Organization_Name`)
) TYPE=InnoDB;

