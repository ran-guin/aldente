-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Warranty`
--

DROP TABLE IF EXISTS `Warranty`;
CREATE TABLE `Warranty` (
  `Warranty_BeginDate` date default NULL,
  `Warranty_ExpiryDate` date default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `FK_Equipment__ID` int(11) default NULL,
  `Warranty_Conditions` text,
  `Warranty_ID` int(11) NOT NULL auto_increment,
  `time` datetime default NULL,
  PRIMARY KEY  (`Warranty_ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`)
) TYPE=InnoDB;

