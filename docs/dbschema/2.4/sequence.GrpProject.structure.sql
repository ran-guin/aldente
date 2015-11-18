-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GrpProject`
--

DROP TABLE IF EXISTS `GrpProject`;
CREATE TABLE `GrpProject` (
  `GrpProject_ID` int(11) NOT NULL auto_increment,
  `FK_Project__ID` int(11) NOT NULL default '0',
  `FK_Grp__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`GrpProject_ID`),
  KEY `FK_Project__ID` (`FK_Project__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) TYPE=InnoDB;

