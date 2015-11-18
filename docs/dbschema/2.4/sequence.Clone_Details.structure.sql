-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Clone_Details`
--

DROP TABLE IF EXISTS `Clone_Details`;
CREATE TABLE `Clone_Details` (
  `Clone_Details_ID` int(11) NOT NULL auto_increment,
  `FK_Clone_Sample__ID` int(11) NOT NULL default '0',
  `Clone_Comments` text,
  `PolyA_Tail` int(11) default NULL,
  `Chimerism_check_with_ESTs` enum('no','yes','warning','single EST match') default NULL,
  `Score` int(11) default NULL,
  `5Prime_found` tinyint(4) default NULL,
  `Genes_Protein` text,
  `Incyte_Match` int(11) default NULL,
  `PolyA_Signal` int(11) default NULL,
  `Clone_Vector` text,
  `Genbank_ID` text,
  `Lukas_Passed` int(11) default NULL,
  `Size_Estimate` int(11) default NULL,
  `Size_StdDev` int(11) default NULL,
  PRIMARY KEY  (`Clone_Details_ID`),
  UNIQUE KEY `clone` (`FK_Clone_Sample__ID`)
) TYPE=InnoDB;

