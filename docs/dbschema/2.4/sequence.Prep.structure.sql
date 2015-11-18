-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Prep`
--

DROP TABLE IF EXISTS `Prep`;
CREATE TABLE `Prep` (
  `Prep_Name` varchar(80) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Prep_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Prep_Time` text,
  `Prep_Conditions` text,
  `Prep_Comments` text,
  `FK_Equipment__ID` int(11) default NULL,
  `FK_Solution__ID` int(11) default NULL,
  `Solution_Quantity` float default NULL,
  `Prep_Failure_Date` datetime NOT NULL default '0000-00-00 00:00:00',
  `Prep_Action` enum('Completed','Failed','Skipped') default NULL,
  `FK_Lab_Protocol__ID` int(11) default NULL,
  `Prep_ID` int(11) NOT NULL auto_increment,
  `Transfer_Quantity` float(10,3) default NULL,
  `Transfer_Quantity_Units` enum('ml','ul','mg','ug','ng','pg') default NULL,
  `FK_FailureReason__ID` int(11) default NULL,
  `Attr_temp` text,
  PRIMARY KEY  (`Prep_ID`),
  KEY `protocol` (`FK_Lab_Protocol__ID`,`Prep_Name`),
  KEY `timestamp` (`Prep_DateTime`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`),
  KEY `FK_FailureReason__ID` (`FK_FailureReason__ID`)
) TYPE=InnoDB;

