-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Plate_Set`
--

DROP TABLE IF EXISTS `Plate_Set`;
CREATE TABLE `Plate_Set` (
  `Plate_Set_ID` int(4) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `Plate_Set_Number` int(11) default NULL,
  `FKParent_Plate_Set__Number` int(11) default NULL,
  PRIMARY KEY  (`Plate_Set_ID`),
  KEY `num` (`Plate_Set_Number`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`),
  KEY `parent_set` (`FKParent_Plate_Set__Number`)
) TYPE=InnoDB;

