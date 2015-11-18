-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GrpStandard_Solution`
--

DROP TABLE IF EXISTS `GrpStandard_Solution`;
CREATE TABLE `GrpStandard_Solution` (
  `GrpStandard_Solution_ID` int(11) NOT NULL auto_increment,
  `FK_Grp__ID` int(11) NOT NULL default '0',
  `FK_Standard_Solution__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`GrpStandard_Solution_ID`),
  UNIQUE KEY `UniqueKey` (`FK_Grp__ID`,`FK_Standard_Solution__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Standard_Solution__ID` (`FK_Standard_Solution__ID`)
) TYPE=InnoDB;

