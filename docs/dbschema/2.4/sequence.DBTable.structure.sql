-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `DBTable`
--

DROP TABLE IF EXISTS `DBTable`;
CREATE TABLE `DBTable` (
  `DBTable_ID` int(11) NOT NULL auto_increment,
  `DBTable_Name` varchar(80) NOT NULL default '',
  `DBTable_Description` text,
  `DBTable_Status` text,
  `Status_Last_Updated` datetime NOT NULL default '0000-00-00 00:00:00',
  `DBTable_Type` enum('General','Lab Object','Lab Process','Object Detail','Settings','Dynamic','DB Management','Application Specific','Lookup') default NULL,
  `DBTable_Title` varchar(80) NOT NULL default '',
  PRIMARY KEY  (`DBTable_ID`),
  UNIQUE KEY `DBTable_Name` (`DBTable_Name`),
  UNIQUE KEY `name` (`DBTable_Name`)
) TYPE=InnoDB;

