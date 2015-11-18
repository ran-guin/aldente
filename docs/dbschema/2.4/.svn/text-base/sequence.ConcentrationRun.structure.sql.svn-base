-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `ConcentrationRun`
--

DROP TABLE IF EXISTS `ConcentrationRun`;
CREATE TABLE `ConcentrationRun` (
  `ConcentrationRun_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Plate__ID` int(10) unsigned NOT NULL default '0',
  `FK_Equipment__ID` int(10) unsigned NOT NULL default '0',
  `DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `CalibrationFunction` text NOT NULL,
  PRIMARY KEY  (`ConcentrationRun_ID`),
  KEY `plate` (`FK_Plate__ID`),
  KEY `equipment_id` (`FK_Equipment__ID`)
) TYPE=InnoDB;

