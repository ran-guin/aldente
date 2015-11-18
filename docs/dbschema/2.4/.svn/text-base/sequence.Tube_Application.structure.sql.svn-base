-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Tube_Application`
--

DROP TABLE IF EXISTS `Tube_Application`;
CREATE TABLE `Tube_Application` (
  `Tube_Application_ID` int(11) NOT NULL auto_increment,
  `FK_Solution__ID` int(11) default NULL,
  `FK_Tube__ID` int(11) default NULL,
  `Comments` text,
  PRIMARY KEY  (`Tube_Application_ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`),
  KEY `FK_Tube__ID` (`FK_Tube__ID`)
) TYPE=InnoDB;

