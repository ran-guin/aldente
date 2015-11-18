-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Library`
--

DROP TABLE IF EXISTS `Library`;
CREATE TABLE `Library` (
  `Library_Source_Name` text,
  `Library_Type` enum('Sequencing','RNA','Mapping') NOT NULL default 'Sequencing',
  `Library_Obtained_Date` date NOT NULL default '0000-00-00',
  `Library_Source` text,
  `Library_Name` varchar(40) NOT NULL default '',
  `External_Library_Name` text NOT NULL,
  `Library_Description` text,
  `FK_Project__ID` int(11) default NULL,
  `Library_Notes` text,
  `Library_FullName` varchar(80) default NULL,
  `FKParent_Library__Name` varchar(40) default NULL,
  `Library_Goals` text,
  `Library_Status` enum('Submitted','On Hold','In Production','Complete','Cancelled','Contaminated') default 'Submitted',
  `FK_Contact__ID` int(11) default NULL,
  `FKCreated_Employee__ID` int(11) default NULL,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Original_Source__ID` int(11) NOT NULL default '0',
  `Library_URL` text,
  `Starting_Plate_Number` smallint(6) NOT NULL default '1',
  `Source_In_House` enum('Yes','No') NOT NULL default 'Yes',
  `Requested_Completion_Date` date default NULL,
  `FKConstructed_Contact__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Library_Name`),
  KEY `proj` (`FK_Project__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKParent_Library__Name` (`FKParent_Library__Name`),
  KEY `FKCreated_Employee__ID` (`FKCreated_Employee__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Original_Source__ID` (`FK_Original_Source__ID`)
) TYPE=InnoDB;

