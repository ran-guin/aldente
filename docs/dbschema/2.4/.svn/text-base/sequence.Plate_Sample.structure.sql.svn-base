-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Plate_Sample`
--

DROP TABLE IF EXISTS `Plate_Sample`;
CREATE TABLE `Plate_Sample` (
  `Plate_Sample_ID` int(11) NOT NULL auto_increment,
  `FKOriginal_Plate__ID` int(11) NOT NULL default '0',
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Well` char(3) default NULL,
  PRIMARY KEY  (`Plate_Sample_ID`),
  UNIQUE KEY `origplate` (`FKOriginal_Plate__ID`,`Well`),
  KEY `sampleid` (`FK_Sample__ID`)
) TYPE=InnoDB;

