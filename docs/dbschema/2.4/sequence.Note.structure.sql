-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Note`
--

DROP TABLE IF EXISTS `Note`;
CREATE TABLE `Note` (
  `Note_ID` int(11) NOT NULL auto_increment,
  `Note_Text` varchar(40) default NULL,
  `Note_Type` varchar(40) default NULL,
  `Note_Description` text,
  PRIMARY KEY  (`Note_ID`)
) TYPE=InnoDB;

