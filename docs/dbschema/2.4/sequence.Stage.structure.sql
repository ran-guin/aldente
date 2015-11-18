-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Stage`
--

DROP TABLE IF EXISTS `Stage`;
CREATE TABLE `Stage` (
  `Stage_ID` int(11) NOT NULL auto_increment,
  `Stage_Name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`Stage_ID`)
) TYPE=InnoDB;

