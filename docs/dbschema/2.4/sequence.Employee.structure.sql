-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Employee`
--

DROP TABLE IF EXISTS `Employee`;
CREATE TABLE `Employee` (
  `Employee_ID` int(4) NOT NULL auto_increment,
  `Employee_Name` varchar(80) default NULL,
  `Employee_Start_Date` date default NULL,
  `Initials` varchar(4) default NULL,
  `Email_Address` text,
  `Employee_FullName` text,
  `Position` text,
  `Employee_Status` enum('Active','Inactive','Old') default NULL,
  `Permissions` set('R','W','U','D','S','P','A') default NULL,
  `IP_Address` text,
  `Password` varchar(80) default '78a302dd267f6044',
  `Machine_Name` varchar(20) default NULL,
  `Department` enum('Receiving','Administration','Sequencing','Mapping','BioInformatics','Gene Expression','None') default NULL,
  `FK_Department__ID` int(11) default NULL,
  PRIMARY KEY  (`Employee_ID`),
  UNIQUE KEY `initials` (`Initials`),
  UNIQUE KEY `name` (`Employee_Name`),
  KEY `FK_Department__ID` (`FK_Department__ID`)
) TYPE=InnoDB;

