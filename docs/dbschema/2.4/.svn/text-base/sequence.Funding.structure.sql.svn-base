-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Funding`
--

DROP TABLE IF EXISTS `Funding`;
CREATE TABLE `Funding` (
  `Funding_ID` int(11) NOT NULL auto_increment,
  `Funding_Status` enum('Applied for','Pending','Received','Terminated') default NULL,
  `Funding_Name` varchar(80) NOT NULL default '',
  `Funding_Conditions` text NOT NULL,
  `Funding_Code` varchar(20) default NULL,
  `Funding_Description` text NOT NULL,
  `Funding_Source` enum('Internal','External') NOT NULL default 'Internal',
  `ApplicationDate` date default NULL,
  `FKContact_Employee__ID` int(11) default NULL,
  `FKSource_Organization__ID` int(11) default NULL,
  `Source_ID` text,
  `AppliedFor` int(11) default NULL,
  `Duration` text,
  `Funding_Type` enum('New','Renewal') default NULL,
  `Currency` enum('US','Canadian') default NULL,
  `ExchangeRate` float default NULL,
  PRIMARY KEY  (`Funding_ID`),
  UNIQUE KEY `name` (`Funding_Name`),
  UNIQUE KEY `code` (`Funding_Code`),
  KEY `FKSource_Organization__ID` (`FKSource_Organization__ID`),
  KEY `FKContact_Employee__ID` (`FKContact_Employee__ID`)
) TYPE=InnoDB;

