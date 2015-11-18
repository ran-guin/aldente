-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Trigger`
--

DROP TABLE IF EXISTS `Trigger`;
CREATE TABLE `Trigger` (
  `Trigger_ID` int(11) NOT NULL auto_increment,
  `Table_Name` varchar(40) NOT NULL default '',
  `Trigger_Type` enum('SQL','Perl','Form') default NULL,
  `Value` text,
  `Trigger_On` enum('update','insert','delete') default NULL,
  `Status` enum('Active','Inactive') NOT NULL default 'Active',
  `Trigger_Description` text,
  PRIMARY KEY  (`Trigger_ID`)
) TYPE=InnoDB;

