-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Optical_Density`
--

DROP TABLE IF EXISTS `Optical_Density`;
CREATE TABLE `Optical_Density` (
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `260nm_Corrected` float default NULL,
  `280nm_Corrected` float default NULL,
  `Density` float default NULL,
  `Optical_Density_DateTime` datetime default NULL,
  `Concentration` float default NULL,
  `Optical_Density_ID` int(11) NOT NULL default '0',
  `Well` char(3) NOT NULL default '',
  `FK_Sample__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Well`,`Optical_Density_ID`),
  KEY `plate_id` (`FK_Plate__ID`),
  KEY `sample_id` (`FK_Sample__ID`),
  KEY `Optical_Density_ID` (`Optical_Density_ID`)
) TYPE=InnoDB;

