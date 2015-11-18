-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GrpLab_Protocol`
--

DROP TABLE IF EXISTS `GrpLab_Protocol`;
CREATE TABLE `GrpLab_Protocol` (
  `GrpLab_Protocol_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Lab_Protocol__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`GrpLab_Protocol_ID`),
  UNIQUE KEY `UniqueKey` (`FK_Grp__ID`,`FK_Lab_Protocol__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Lab_Protocol__ID` (`FK_Lab_Protocol__ID`)
) TYPE=InnoDB;

