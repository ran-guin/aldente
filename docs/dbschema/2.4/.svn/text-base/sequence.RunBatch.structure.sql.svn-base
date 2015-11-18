-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `RunBatch`
--

DROP TABLE IF EXISTS `RunBatch`;
CREATE TABLE `RunBatch` (
  `RunBatch_ID` int(11) NOT NULL auto_increment,
  `RunBatch_RequestDateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `FK_Employee__ID` int(11) default NULL,
  `FK_Equipment__ID` int(11) default NULL,
  `RunBatch_Comments` text,
  PRIMARY KEY  (`RunBatch_ID`)
) TYPE=InnoDB;

