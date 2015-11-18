-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Machine_Default`
--

DROP TABLE IF EXISTS `Machine_Default`;
CREATE TABLE `Machine_Default` (
  `Machine_Default_ID` int(11) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `Run_Module` text,
  `NT_Data_dir` text,
  `NT_Samplesheet_dir` text,
  `Local_Samplesheet_dir` text,
  `Host` text,
  `Local_Data_dir` text,
  `Sharename` text,
  `Agarose_Percentage` float default NULL,
  `Injection_Voltage` int(11) default NULL,
  `Injection_Time` int(11) default NULL,
  `Run_Voltage` int(11) default NULL,
  `Run_Time` int(11) default NULL,
  `Run_Temp` int(11) default NULL,
  `PMT1` int(11) default NULL,
  `PMT2` int(11) default NULL,
  `An_Module` text,
  `Foil_Piercing` tinyint(4) default NULL,
  `Chemistry_Version` tinyint(4) default NULL,
  `FK_Sequencer_Type__ID` tinyint(4) NOT NULL default '0',
  `Mount` varchar(80) default NULL,
  PRIMARY KEY  (`Machine_Default_ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_Sequencer_Type__ID` (`FK_Sequencer_Type__ID`)
) TYPE=InnoDB;

