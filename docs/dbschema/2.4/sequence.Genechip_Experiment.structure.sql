-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Genechip_Experiment`
--

DROP TABLE IF EXISTS `Genechip_Experiment`;
CREATE TABLE `Genechip_Experiment` (
  `Genechip_Experiment_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `Chip_Type` enum('HG-U133A','HG-U133') default NULL,
  `Experiment_Count` int(11) NOT NULL default '0',
  `Data_Subdirectory` varchar(80) NOT NULL default '',
  `Comments` text,
  `FK_Equipment__ID` int(11) NOT NULL default '0',
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Experiment_DateTime` date default NULL,
  `Experiment_Name` varchar(80) NOT NULL default '',
  `Genechip_Barcode` varchar(80) NOT NULL default '',
  PRIMARY KEY  (`Genechip_Experiment_ID`)
) TYPE=InnoDB;

