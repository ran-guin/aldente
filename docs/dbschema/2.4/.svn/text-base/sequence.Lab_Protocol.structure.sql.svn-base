-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Lab_Protocol`
--

DROP TABLE IF EXISTS `Lab_Protocol`;
CREATE TABLE `Lab_Protocol` (
  `Lab_Protocol_Name` varchar(40) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Lab_Protocol_Status` enum('Active','Old','Inactive') default NULL,
  `Lab_Protocol_Description` text,
  `Lab_Protocol_ID` int(11) NOT NULL auto_increment,
  `Lab_Protocol_VersionDate` date default NULL,
  PRIMARY KEY  (`Lab_Protocol_ID`),
  UNIQUE KEY `name` (`Lab_Protocol_Name`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

