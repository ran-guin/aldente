-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Box`
--

DROP TABLE IF EXISTS `Box`;
CREATE TABLE `Box` (
  `Box_ID` int(11) NOT NULL auto_increment,
  `Box_Opened` date default NULL,
  `FK_Rack__ID` int(11) default NULL,
  `Box_Number` int(11) default NULL,
  `Box_Number_in_Batch` int(11) default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `FKParent_Box__ID` int(11) default NULL,
  `Box_Serial_Number` text,
  `Box_Type` enum('Box','Kit','Supplies') NOT NULL default 'Box',
  `Box_Expiry` date default NULL,
  PRIMARY KEY  (`Box_ID`),
  KEY `stock` (`FK_Stock__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKParent_Box__ID` (`FKParent_Box__ID`)
) TYPE=InnoDB;

