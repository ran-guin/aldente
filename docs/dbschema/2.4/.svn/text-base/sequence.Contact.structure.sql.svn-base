-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Contact`
--

DROP TABLE IF EXISTS `Contact`;
CREATE TABLE `Contact` (
  `Contact_ID` int(11) NOT NULL auto_increment,
  `Contact_Name` text,
  `Position` text,
  `FK_Organization__ID` int(11) default NULL,
  `Contact_Phone` text,
  `Contact_Email` text,
  `Contact_Type` enum('Collaborator','Maintenance','Technical Support','Sales','Academic') default NULL,
  `Contact_Status` enum('Current','Old','Basic') default NULL,
  `Contact_Notes` text,
  `Contact_Fax` text,
  `First_Name` text,
  `Middle_Name` text,
  `Last_Name` text,
  `Category` enum('Collaborator','Maintenance','Technical Support','Sales','Academic') default NULL,
  `Home_Phone` text,
  `Work_Phone` text,
  `Pager` text,
  `Fax` text,
  `Mobile` text,
  `Other_Phone` text,
  `Primary_Location` enum('home','work') default NULL,
  `Home_Address` text,
  `Home_City` text,
  `Home_County` text,
  `Home_Postcode` text,
  `Home_Country` text,
  `Work_Address` text,
  `Work_City` text,
  `Work_County` text,
  `Work_Postcode` text,
  `Work_Country` text,
  `Email` text,
  `Personal_Website` text,
  `Business_Website` text,
  `Alternate_Email_1` text,
  `Alternate_Email_2` text,
  `Birthday` date default NULL,
  `Anniversary` date default NULL,
  `Comments` text,
  `Canonical_Name` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`Contact_ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`)
) TYPE=InnoDB;

