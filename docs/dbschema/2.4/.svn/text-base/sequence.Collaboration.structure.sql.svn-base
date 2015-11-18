-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Collaboration`
--

DROP TABLE IF EXISTS `Collaboration`;
CREATE TABLE `Collaboration` (
  `FK_Project__ID` int(11) default NULL,
  `Collaboration_ID` int(11) NOT NULL auto_increment,
  `FK_Contact__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Collaboration_ID`),
  KEY `FK_Project__ID` (`FK_Project__ID`)
) TYPE=InnoDB;

