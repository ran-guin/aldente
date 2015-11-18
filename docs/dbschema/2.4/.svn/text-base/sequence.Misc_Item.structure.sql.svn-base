-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Misc_Item`
--

DROP TABLE IF EXISTS `Misc_Item`;
CREATE TABLE `Misc_Item` (
  `Misc_Item_ID` int(11) NOT NULL auto_increment,
  `Misc_Item_Number` int(11) NOT NULL default '0',
  `Misc_Item_Number_in_Batch` int(11) default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `Misc_Item_Serial_Number` text,
  `FK_Rack__ID` int(11) default NULL,
  `Misc_Item_Type` text,
  PRIMARY KEY  (`Misc_Item_ID`),
  KEY `FK_Stock__ID` (`FK_Stock__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`)
) TYPE=InnoDB;

