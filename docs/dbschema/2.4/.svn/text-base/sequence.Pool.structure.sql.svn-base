-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Pool`
--

DROP TABLE IF EXISTS `Pool`;
CREATE TABLE `Pool` (
  `Pool_ID` int(11) NOT NULL auto_increment,
  `Pool_Description` text NOT NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Pool_Date` date NOT NULL default '0000-00-00',
  `Pool_Comments` text,
  `Pool_Type` enum('Library','Sample','Transposon') default NULL,
  PRIMARY KEY  (`Pool_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

