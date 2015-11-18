-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Protocol_Tracking`
--

DROP TABLE IF EXISTS `Protocol_Tracking`;
CREATE TABLE `Protocol_Tracking` (
  `Protocol_Tracking_ID` int(11) NOT NULL auto_increment,
  `Protocol_Tracking_Title` char(20) default NULL,
  `Protocol_Tracking_Step_Name` char(40) default NULL,
  `Protocol_Tracking_Order` int(11) default NULL,
  `Protocol_Tracking_Type` enum('Step','Plasticware') default NULL,
  `Protocol_Tracking_Status` enum('Active','InActive') default NULL,
  `FK_Grp__ID` int(11) default NULL,
  PRIMARY KEY  (`Protocol_Tracking_ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`)
) TYPE=InnoDB;

