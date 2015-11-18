-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Change_History`
--

DROP TABLE IF EXISTS `Change_History`;
CREATE TABLE `Change_History` (
  `Change_History_ID` int(11) NOT NULL auto_increment,
  `FK_DBField__ID` int(11) NOT NULL default '0',
  `Old_Value` varchar(40) default NULL,
  `New_Value` varchar(40) default NULL,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `Modified_Date` datetime NOT NULL default '0000-00-00 00:00:00',
  `Record_ID` varchar(40) NOT NULL default '',
  `Comment` text,
  PRIMARY KEY  (`Change_History_ID`),
  KEY `FK_DBField__ID` (`FK_DBField__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

