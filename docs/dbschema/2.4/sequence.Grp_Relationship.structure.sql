-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Grp_Relationship`
--

DROP TABLE IF EXISTS `Grp_Relationship`;
CREATE TABLE `Grp_Relationship` (
  `Grp_Relationship_ID` int(11) NOT NULL auto_increment,
  `FKBase_Grp__ID` int(11) NOT NULL default '0',
  `FKDerived_Grp__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Grp_Relationship_ID`),
  KEY `FKDerived_Grp__ID` (`FKDerived_Grp__ID`),
  KEY `FKBase_Grp__ID` (`FKBase_Grp__ID`)
) TYPE=InnoDB;

