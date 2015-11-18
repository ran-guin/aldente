-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Plate_PrimerPlateWell`
--

DROP TABLE IF EXISTS `Plate_PrimerPlateWell`;
CREATE TABLE `Plate_PrimerPlateWell` (
  `Plate_PrimerPlateWell_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `FK_Primer_Plate_Well__ID` int(11) NOT NULL default '0',
  `Plate_Well` char(3) default NULL,
  PRIMARY KEY  (`Plate_PrimerPlateWell_ID`),
  KEY `plate` (`FK_Plate__ID`),
  KEY `primer` (`FK_Primer_Plate_Well__ID`),
  KEY `well` (`Plate_Well`)
) TYPE=MyISAM;

