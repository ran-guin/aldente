-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Project`
--

DROP TABLE IF EXISTS `Project`;
CREATE TABLE `Project` (
  `Project_Name` varchar(40) NOT NULL default '',
  `Project_Description` text,
  `Project_Initiated` date NOT NULL default '0000-00-00',
  `Project_Completed` date default NULL,
  `Project_Type` enum('EST','EST+','SAGE','cDNA','PCR','PCR Product','Genomic Clone','Other','Test') default NULL,
  `Project_Path` varchar(80) default NULL,
  `Project_ID` int(11) NOT NULL auto_increment,
  `Project_Status` enum('Active','Inactive','Completed') default NULL,
  `FK_Funding__ID` int(11) default NULL,
  PRIMARY KEY  (`Project_ID`),
  UNIQUE KEY `path` (`Project_Path`),
  KEY `FK_Funding__ID` (`FK_Funding__ID`)
) TYPE=InnoDB;

