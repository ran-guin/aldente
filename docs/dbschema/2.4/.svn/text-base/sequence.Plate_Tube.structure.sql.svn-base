-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Plate_Tube`
--

DROP TABLE IF EXISTS `Plate_Tube`;
CREATE TABLE `Plate_Tube` (
  `Plate_Tube_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `FK_Tube__ID` int(11) default NULL,
  PRIMARY KEY  (`Plate_Tube_ID`),
  KEY `FK_Tube__ID` (`FK_Tube__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`)
) TYPE=InnoDB;

