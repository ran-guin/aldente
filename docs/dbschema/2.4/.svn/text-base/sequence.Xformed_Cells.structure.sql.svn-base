-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Xformed_Cells`
--

DROP TABLE IF EXISTS `Xformed_Cells`;
CREATE TABLE `Xformed_Cells` (
  `Xformed_Cells_ID` int(11) NOT NULL auto_increment,
  `VolumePerTube` int(11) default NULL,
  `Tubes` int(11) default NULL,
  `EstimatedClones` int(11) default NULL,
  `Cell_Catalog_Number` varchar(40) default NULL,
  `Label` varchar(40) default NULL,
  `Xform_Method` varchar(40) default NULL,
  `Cell_Type` varchar(40) default NULL,
  `FKSupplier_Organization__ID` int(11) default NULL,
  `Sequencing_Type` enum('Primers','Transposon','Primers_and_transposon','Replicates') default NULL,
  `384_Well_Plates_To_Seq` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `384_Well_Plates_To_Pick` int(11) default '0',
  PRIMARY KEY  (`Xformed_Cells_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FKSupplier_Organization__ID` (`FKSupplier_Organization__ID`)
) TYPE=InnoDB;

