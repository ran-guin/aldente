-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Issue_Detail`
--

DROP TABLE IF EXISTS `Issue_Detail`;
CREATE TABLE `Issue_Detail` (
  `Issue_Detail_ID` int(11) NOT NULL auto_increment,
  `FK_Issue__ID` int(11) NOT NULL default '0',
  `FKSubmitted_Employee__ID` int(11) NOT NULL default '0',
  `Submitted_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Message` text,
  PRIMARY KEY  (`Issue_Detail_ID`),
  KEY `FKSubmitted_Employee__ID` (`FKSubmitted_Employee__ID`),
  KEY `FK_Issue__ID` (`FK_Issue__ID`)
) TYPE=InnoDB;

