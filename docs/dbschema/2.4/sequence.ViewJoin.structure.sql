-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `ViewJoin`
--

DROP TABLE IF EXISTS `ViewJoin`;
CREATE TABLE `ViewJoin` (
  `ViewJoin_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_View__ID` int(11) NOT NULL default '0',
  `Join_Condition` text,
  `Join_Type` enum('LEFT','INNER') default 'INNER',
  PRIMARY KEY  (`ViewJoin_ID`),
  KEY `FK_View__ID` (`FK_View__ID`)
) TYPE=InnoDB;

