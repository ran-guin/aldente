-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Transposon_Pool`
--

DROP TABLE IF EXISTS `Transposon_Pool`;
CREATE TABLE `Transposon_Pool` (
  `Transposon_Pool_ID` int(11) NOT NULL auto_increment,
  `FK_Transposon__ID` int(11) NOT NULL default '0',
  `FK_Optical_Density__ID` int(11) default NULL,
  `FK_GelRun__ID` int(11) default NULL,
  `Reads_Required` int(11) default NULL,
  `Pipeline` enum('Standard','Gateway','PCR/Gateway (pGATE)') default NULL,
  `Test_Status` enum('Test','Production') NOT NULL default 'Production',
  `Status` enum('Data Pending','Dilutions','Ready For Pooling','In Progress','Complete','Failed-Redo') default NULL,
  `FK_Source__ID` int(11) default NULL,
  `FK_Pool__ID` int(11) default NULL,
  PRIMARY KEY  (`Transposon_Pool_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FK_Pool__ID` (`FK_Pool__ID`),
  KEY `FK_Gel__ID` (`FK_GelRun__ID`),
  KEY `FK_Optical_Density__ID` (`FK_Optical_Density__ID`),
  KEY `FK_Transposon__ID` (`FK_Transposon__ID`)
) TYPE=InnoDB;

