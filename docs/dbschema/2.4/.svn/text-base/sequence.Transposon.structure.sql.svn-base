-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Transposon`
--

DROP TABLE IF EXISTS `Transposon`;
CREATE TABLE `Transposon` (
  `Transposon_Name` varchar(80) NOT NULL default '',
  `FK_Organization__ID` int(11) default NULL,
  `Transposon_Description` text,
  `Transposon_Sequence` text,
  `Transposon_Source_ID` text,
  `Antibiotic_Marker` enum('Kanamycin','Chloramphenicol','Tetracycline') default NULL,
  `Transposon_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Transposon_ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`)
) TYPE=InnoDB;

