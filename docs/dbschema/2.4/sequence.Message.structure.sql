-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Message`
--

DROP TABLE IF EXISTS `Message`;
CREATE TABLE `Message` (
  `Message_ID` int(11) NOT NULL auto_increment,
  `Message_Text` text,
  `Message_Date` datetime default NULL,
  `Message_Link` text,
  `Message_Status` enum('Urgent','Active','Old') default 'Active',
  `FK_Employee__ID` int(11) default NULL,
  `Message_Type` enum('Public','Private','Admin','Group') default NULL,
  `FK_Grp__ID` int(11) default NULL,
  PRIMARY KEY  (`Message_ID`),
  KEY `fk_grp` (`FK_Grp__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

