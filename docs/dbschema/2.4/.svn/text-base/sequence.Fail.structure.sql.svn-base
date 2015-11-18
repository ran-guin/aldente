-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Fail`
--

DROP TABLE IF EXISTS `Fail`;
CREATE TABLE `Fail` (
  `Fail_ID` int(11) NOT NULL auto_increment,
  `Object_ID` int(11) NOT NULL default '0',
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `FK_FailReason__ID` int(11) NOT NULL default '0',
  `DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Comments` text,
  PRIMARY KEY  (`Fail_ID`),
  KEY `Object_ID` (`Object_ID`,`FK_Employee__ID`,`FK_FailReason__ID`)
) TYPE=InnoDB;

