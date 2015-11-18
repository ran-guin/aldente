-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Primer_Plate_Well`
--

DROP TABLE IF EXISTS `Primer_Plate_Well`;
CREATE TABLE `Primer_Plate_Well` (
  `Primer_Plate_Well_ID` int(11) NOT NULL auto_increment,
  `Well` char(3) default NULL,
  `FK_Primer__Name` varchar(80) default NULL,
  `FK_Primer_Plate__ID` int(11) default NULL,
  `FKParent_Primer_Plate_Well__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Primer_Plate_Well_ID`),
  KEY `primerplate_well` (`Well`),
  KEY `primerplatewell_name` (`FK_Primer__Name`),
  KEY `primerplatewell_fkplate` (`FK_Primer_Plate__ID`),
  KEY `parent` (`FKParent_Primer_Plate_Well__ID`)
) TYPE=InnoDB;

