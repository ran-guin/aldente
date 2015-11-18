-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Funding_Applicant`
--

DROP TABLE IF EXISTS `Funding_Applicant`;
CREATE TABLE `Funding_Applicant` (
  `Funding_Applicant_ID` int(11) NOT NULL auto_increment,
  `FK_Funding__ID` int(11) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `FK_Contact__ID` int(11) default NULL,
  `Applicant_Type` enum('Primary','Collaborator') default NULL,
  PRIMARY KEY  (`Funding_Applicant_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FK_Funding__ID` (`FK_Funding__ID`)
) TYPE=InnoDB;

