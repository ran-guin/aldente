-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GrpDBTable`
--

DROP TABLE IF EXISTS `GrpDBTable`;
CREATE TABLE `GrpDBTable` (
  `GrpDBTable_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_DBTable__ID` int(11) NOT NULL default '0',
  `Permissions` set('R','W','U','D','O') NOT NULL default 'R',
  PRIMARY KEY  (`GrpDBTable_ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_DBTable__ID` (`FK_DBTable__ID`)
) TYPE=InnoDB;

