-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GelRun`
--

DROP TABLE IF EXISTS `GelRun`;
CREATE TABLE `GelRun` (
  `GelRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) default NULL,
  `FKPoured_Employee__ID` int(11) default NULL,
  `FKComb_Equipment__ID` int(11) default NULL,
  `FKScanner_Equipment__ID` int(11) default NULL,
  `FKAgarose_Solution__ID` int(11) default NULL,
  `Agarose_Percentage` varchar(5) default NULL,
  `File_Extension_Type` enum('sizes','none') default NULL,
  PRIMARY KEY  (`GelRun_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FKPoured_Employee__ID` (`FKPoured_Employee__ID`),
  KEY `FKScanner_Equipment__ID` (`FKScanner_Equipment__ID`),
  KEY `FKComb_Equipment__ID` (`FKComb_Equipment__ID`)
) TYPE=InnoDB;

