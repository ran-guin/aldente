-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `UseCase_Step`
--

DROP TABLE IF EXISTS `UseCase_Step`;
CREATE TABLE `UseCase_Step` (
  `UseCase_Step_ID` int(11) NOT NULL auto_increment,
  `UseCase_Step_Title` text,
  `UseCase_Step_Description` text,
  `UseCase_Step_Comments` text,
  `FK_UseCase__ID` int(11) default NULL,
  `FKParent_UseCase_Step__ID` int(11) default NULL,
  `UseCase_Step_Branch` enum('0','1') default '0',
  PRIMARY KEY  (`UseCase_Step_ID`),
  KEY `usecase_id` (`FK_UseCase__ID`)
) TYPE=InnoDB;

