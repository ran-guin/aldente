-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Transposon_Library`
--

DROP TABLE IF EXISTS `Transposon_Library`;
CREATE TABLE `Transposon_Library` (
  `Transposon_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `FK_Transposon__ID` int(11) NOT NULL default '0',
  `FK_Pool__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Transposon_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`),
  KEY `transposon_id` (`FK_Transposon__ID`),
  KEY `pool_id` (`FK_Pool__ID`)
) TYPE=InnoDB;

