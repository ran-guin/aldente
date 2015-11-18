-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `How_To_Object`
--

DROP TABLE IF EXISTS `How_To_Object`;
CREATE TABLE `How_To_Object` (
  `How_To_Object_ID` int(11) NOT NULL auto_increment,
  `How_To_Object_Name` varchar(80) NOT NULL default '',
  `How_To_Object_Description` text,
  PRIMARY KEY  (`How_To_Object_ID`),
  UNIQUE KEY `object_name` (`How_To_Object_Name`)
) TYPE=InnoDB;

