-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Gel`
--

DROP TABLE IF EXISTS `Gel`;
CREATE TABLE `Gel` (
  `Gel_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `Gel_Date` datetime NOT NULL default '0000-00-00 00:00:00',
  `FK_Employee__ID` int(4) default NULL,
  `Gel_Directory` varchar(80) NOT NULL default '',
  `Status` enum('Active','Failed','On_hold','lane tracking','run bandleader','bandleader completed','bandleader failure','finished','sizes imported','size importing failure') default 'Active',
  `Gel_Comments` text,
  `Bandleader_Version` varchar(40) default '2.3.5',
  `Agarose_Percent` float(10,2) default '1.20',
  `File_Extension_Type` enum('sizes','none') default 'none',
  PRIMARY KEY  (`Gel_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`)
) TYPE=InnoDB;

