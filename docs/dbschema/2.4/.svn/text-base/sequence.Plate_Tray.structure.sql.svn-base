-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Plate_Tray`
--

DROP TABLE IF EXISTS `Plate_Tray`;
CREATE TABLE `Plate_Tray` (
  `Plate_Tray_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `FK_Tray__ID` int(11) NOT NULL default '0',
  `Plate_Position` enum('a','b','c','d','N/A') NOT NULL default 'N/A',
  PRIMARY KEY  (`Plate_Tray_ID`),
  UNIQUE KEY `FK_Plate__ID` (`FK_Plate__ID`),
  UNIQUE KEY `Plate_Position` (`FK_Tray__ID`,`Plate_Position`)
) TYPE=InnoDB COMMENT='For multiple plates on a tray';

