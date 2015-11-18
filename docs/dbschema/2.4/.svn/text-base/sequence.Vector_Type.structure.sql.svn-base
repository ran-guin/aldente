-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Vector_Type`
--

DROP TABLE IF EXISTS `Vector_Type`;
CREATE TABLE `Vector_Type` (
  `Vector_Type_ID` int(11) NOT NULL auto_increment,
  `Vector_Type_Name` varchar(40) NOT NULL default '',
  `Vector_Sequence_File` text NOT NULL,
  `Vector_Sequence` longtext,
  PRIMARY KEY  (`Vector_Type_ID`),
  UNIQUE KEY `Vector_Type_Name` (`Vector_Type_Name`)
) TYPE=InnoDB;

