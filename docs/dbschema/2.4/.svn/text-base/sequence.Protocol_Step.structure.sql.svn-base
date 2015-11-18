-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Protocol_Step`
--

DROP TABLE IF EXISTS `Protocol_Step`;
CREATE TABLE `Protocol_Step` (
  `Protocol_Step_Number` int(11) default NULL,
  `Protocol_Step_Name` varchar(80) NOT NULL default '',
  `Protocol_Step_Instructions` text,
  `Protocol_Step_ID` int(11) NOT NULL auto_increment,
  `Protocol_Step_Defaults` text,
  `Input` text,
  `Scanner` tinyint(3) unsigned default '1',
  `Protocol_Step_Message` varchar(40) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Protocol_Step_Changed` date default NULL,
  `Input_Format` text NOT NULL,
  `FK_Lab_Protocol__ID` int(11) default NULL,
  PRIMARY KEY  (`Protocol_Step_ID`),
  UNIQUE KEY `naming` (`Protocol_Step_Name`,`FK_Lab_Protocol__ID`),
  KEY `prot` (`FK_Lab_Protocol__ID`),
  KEY `employee_id` (`FK_Employee__ID`)
) TYPE=InnoDB;

