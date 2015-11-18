-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Microtiter`
--

DROP TABLE IF EXISTS `Microtiter`;
CREATE TABLE `Microtiter` (
  `Microtiter_ID` int(11) NOT NULL auto_increment,
  `Plates` int(11) default NULL,
  `Plate_Size` enum('96-well','384-well') default NULL,
  `Plate_Catalog_Number` varchar(40) default NULL,
  `VolumePerWell` int(11) default NULL,
  `Cell_Catalog_Number` varchar(40) default NULL,
  `Label` varchar(40) default NULL,
  `FKSupplier_Organization__ID` int(11) default NULL,
  `Cell_Type` varchar(40) default NULL,
  `Media_Type` varchar(40) default NULL,
  `Sequencing_Type` enum('Primers','Transposon','Primers_and_transposon','Replicates') default NULL,
  `384_Well_Plates_To_Seq` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Microtiter_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FKSupplier_Organization__ID` (`FKSupplier_Organization__ID`)
) TYPE=InnoDB;

