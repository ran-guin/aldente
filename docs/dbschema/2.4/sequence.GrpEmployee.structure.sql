-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GrpEmployee`
--

DROP TABLE IF EXISTS `GrpEmployee`;
CREATE TABLE `GrpEmployee` (
  `GrpEmployee_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Employee__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`GrpEmployee_ID`),
  UNIQUE KEY `UniqueKey` (`FK_Grp__ID`,`FK_Employee__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

