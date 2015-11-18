-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Original_Source`
--

DROP TABLE IF EXISTS `Original_Source`;
CREATE TABLE `Original_Source` (
  `Original_Source_ID` int(11) NOT NULL auto_increment,
  `Original_Source_Name` varchar(40) NOT NULL default '',
  `Organism` varchar(40) default NULL,
  `Sex` varchar(20) default NULL,
  `Tissue` varchar(40) default NULL,
  `Strain` varchar(40) default NULL,
  `Host` text NOT NULL,
  `Description` text,
  `FK_Contact__ID` int(11) default NULL,
  `FKCreated_Employee__ID` int(11) default NULL,
  `Defined_Date` date NOT NULL default '0000-00-00',
  `FK_Stage__ID` int(11) NOT NULL default '0',
  `FK_Tissue__ID` int(11) NOT NULL default '0',
  `FK_Organism__ID` int(11) NOT NULL default '0',
  `Subtissue_temp` varchar(40) default NULL,
  `Tissue_temp` varchar(40) NOT NULL default '',
  `Organism_temp` varchar(40) default NULL,
  `Stage_temp` varchar(40) default NULL,
  `Note_temp` varchar(40) NOT NULL default '',
  `Thelier_temp` varchar(40) default NULL,
  `Sample_Available` enum('Yes','No') NOT NULL default 'Yes',
  PRIMARY KEY  (`Original_Source_ID`),
  UNIQUE KEY `OS_Name` (`Original_Source_Name`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKCreated_Employee__ID` (`FKCreated_Employee__ID`)
) TYPE=InnoDB;

