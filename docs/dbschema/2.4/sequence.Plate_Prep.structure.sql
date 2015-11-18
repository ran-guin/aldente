-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Plate_Prep`
--

DROP TABLE IF EXISTS `Plate_Prep`;
CREATE TABLE `Plate_Prep` (
  `Plate_Prep_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `FK_Prep__ID` int(11) default NULL,
  `FK_Plate_Set__Number` int(11) default NULL,
  `FK_Equipment__ID` int(11) default NULL,
  `FK_Solution__ID` int(11) default NULL,
  `Solution_Quantity` float default NULL,
  `Transfer_Quantity` float default NULL,
  `Transfer_Quantity_Units` enum('pl','nl','ul','ml','l','g','mg','ug','ng','pg') default NULL,
  PRIMARY KEY  (`Plate_Prep_ID`),
  KEY `plate` (`FK_Plate__ID`),
  KEY `plate_set` (`FK_Plate_Set__Number`),
  KEY `prep` (`FK_Prep__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`)
) TYPE=InnoDB;

