-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Rack`
--

DROP TABLE IF EXISTS `Rack`;
CREATE TABLE `Rack` (
  `Rack_ID` int(4) NOT NULL auto_increment,
  `FK_Equipment__ID` int(11) default NULL,
  `Rack_Conditions` enum('Temporary','Room Temperature','+4 degrees','-20 degrees','-40 degrees','-80 degrees','Garbage','Exported') default NULL,
  `Rack_Type` enum('Shelf','Rack','Box','Slot') NOT NULL default 'Shelf',
  `Rack_Name` varchar(80) default NULL,
  `Movable` enum('Y','N') NOT NULL default 'Y',
  `Rack_Alias` varchar(80) default NULL,
  `FKParent_Rack__ID` int(11) default NULL,
  PRIMARY KEY  (`Rack_ID`),
  UNIQUE KEY `alias` (`Rack_Alias`),
  KEY `Equipment_FK` (`FK_Equipment__ID`),
  KEY `type` (`Rack_Type`),
  KEY `name` (`Rack_Name`),
  KEY `parent_rack_id` (`FKParent_Rack__ID`)
) TYPE=InnoDB;

