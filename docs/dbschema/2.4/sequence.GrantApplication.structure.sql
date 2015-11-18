-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GrantApplication`
--

DROP TABLE IF EXISTS `GrantApplication`;
CREATE TABLE `GrantApplication` (
  `GrantApplication_ID` int(11) NOT NULL auto_increment,
  `Title` char(80) default NULL,
  `FKContact_Employee__ID` int(11) default NULL,
  `AppliedFor` float default NULL,
  `Duration` int(11) default NULL,
  `Duration_Units` enum('days','months','years') default NULL,
  `Grant_Type` char(40) default NULL,
  `ApplicationStatus` enum('Awarded','Declined','Applied') default NULL,
  `Award` float default NULL,
  `Currency` enum('US','Canadian') default NULL,
  `Application_Date` date default NULL,
  `Application_Number` int(11) default NULL,
  `Funding_Frequency` char(40) default NULL,
  PRIMARY KEY  (`GrantApplication_ID`),
  KEY `FKContact_Employee__ID` (`FKContact_Employee__ID`)
) TYPE=InnoDB;

