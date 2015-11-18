-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `How_To_Topic`
--

DROP TABLE IF EXISTS `How_To_Topic`;
CREATE TABLE `How_To_Topic` (
  `How_To_Topic_ID` int(11) NOT NULL auto_increment,
  `Topic_Number` int(11) default NULL,
  `Topic_Name` varchar(80) NOT NULL default '',
  `Topic_Type` enum('','New','Update','Find','Edit') NOT NULL default '',
  `Topic_Description` text,
  `FK_How_To_Object__ID` int(11) default NULL,
  PRIMARY KEY  (`How_To_Topic_ID`),
  KEY `object` (`FK_How_To_Object__ID`)
) TYPE=InnoDB;

