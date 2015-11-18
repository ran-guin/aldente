-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Communication`
--

DROP TABLE IF EXISTS `Communication`;
CREATE TABLE `Communication` (
  `Communication_ID` int(11) NOT NULL auto_increment,
  `FK_Contact__ID` int(11) default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `Communication_Description` text,
  `Communication_Date` date default NULL,
  `FK_Employee__ID` int(11) default NULL,
  PRIMARY KEY  (`Communication_ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

