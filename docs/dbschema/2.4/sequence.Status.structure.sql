-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Status`
--

DROP TABLE IF EXISTS `Status`;
CREATE TABLE `Status` (
  `Status_ID` int(11) NOT NULL auto_increment,
  `Status_Type` enum('ReArray_Request','Maintenance') default NULL,
  `Status_Name` char(40) default NULL,
  PRIMARY KEY  (`Status_ID`)
) TYPE=InnoDB;

