-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `UseCase`
--

DROP TABLE IF EXISTS `UseCase`;
CREATE TABLE `UseCase` (
  `UseCase_ID` int(11) NOT NULL auto_increment,
  `UseCase_Name` varchar(80) NOT NULL default '',
  `FK_Employee__ID` int(11) default NULL,
  `UseCase_Description` text,
  `UseCase_Created` datetime default '0000-00-00 00:00:00',
  `UseCase_Modified` datetime default '0000-00-00 00:00:00',
  `FKParent_UseCase__ID` int(11) default NULL,
  `FK_UseCase_Step__ID` int(11) default NULL,
  PRIMARY KEY  (`UseCase_ID`),
  UNIQUE KEY `usecase_name` (`UseCase_Name`)
) TYPE=InnoDB;

