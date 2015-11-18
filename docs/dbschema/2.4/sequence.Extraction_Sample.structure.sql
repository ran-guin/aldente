-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Extraction_Sample`
--

DROP TABLE IF EXISTS `Extraction_Sample`;
CREATE TABLE `Extraction_Sample` (
  `Extraction_Sample_ID` int(11) NOT NULL auto_increment,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FK_Library__Name` char(6) default NULL,
  `Plate_Number` int(11) default NULL,
  `Volume` int(11) default NULL,
  `FKOriginal_Plate__ID` int(11) default NULL,
  `Extraction_Sample_Type` enum('DNA','RNA','Protein','Mixed','Amplicon') NOT NULL default 'Mixed',
  `Original_Well` char(3) default NULL,
  PRIMARY KEY  (`Extraction_Sample_ID`),
  KEY `sample` (`FK_Sample__ID`),
  KEY `plate` (`FKOriginal_Plate__ID`),
  KEY `library_name` (`FK_Library__Name`)
) TYPE=InnoDB;

