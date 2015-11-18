-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Grp`
--

DROP TABLE IF EXISTS `Grp`;
CREATE TABLE `Grp` (
  `Grp_ID` int(11) NOT NULL auto_increment,
  `Grp_Name` varchar(80) NOT NULL default '',
  `FK_Department__ID` int(11) NOT NULL default '0',
  `Access` enum('Lab','Admin','Guest','Report','Bioinformatics') NOT NULL default 'Guest',
  PRIMARY KEY  (`Grp_ID`),
  KEY `dept_id` (`FK_Department__ID`)
) TYPE=InnoDB;

