-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Parameter`
--

DROP TABLE IF EXISTS `Parameter`;
CREATE TABLE `Parameter` (
  `FK_Standard_Solution__ID` int(11) default NULL,
  `Parameter_Name` varchar(40) default NULL,
  `Parameter_Description` text,
  `Parameter_Value` float default NULL,
  `Parameter_Type` enum('Static','Multiple','Variable','Hidden') default NULL,
  `Parameter_ID` int(11) NOT NULL auto_increment,
  `Parameter_Format` text,
  `Parameter_Units` enum('ml','ul','mg','ug','g','l') default NULL,
  `Parameter_SType` enum('Reagent','Solution','Primer','Buffer','Matrix') default NULL,
  `Parameter_Prompt` varchar(30) NOT NULL default '',
  PRIMARY KEY  (`Parameter_ID`),
  UNIQUE KEY `FK_Standard_Solution__ID` (`FK_Standard_Solution__ID`,`Parameter_Name`)
) TYPE=InnoDB;

