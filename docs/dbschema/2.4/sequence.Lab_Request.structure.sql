-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Lab_Request`
--

DROP TABLE IF EXISTS `Lab_Request`;
CREATE TABLE `Lab_Request` (
  `Lab_Request_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Request_Date` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`Lab_Request_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

