-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Clone_Sample`
--

DROP TABLE IF EXISTS `Clone_Sample`;
CREATE TABLE `Clone_Sample` (
  `Clone_Sample_ID` int(11) NOT NULL auto_increment,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FK_Library__Name` char(5) default NULL,
  `Library_Plate_Number` int(11) default NULL,
  `Original_Quadrant` char(2) default NULL,
  `Original_Well` char(3) default NULL,
  `FKOriginal_Plate__ID` int(11) default NULL,
  PRIMARY KEY  (`Clone_Sample_ID`),
  KEY `sample` (`FK_Sample__ID`),
  KEY `plate` (`FKOriginal_Plate__ID`,`Original_Well`),
  KEY `lib` (`FK_Library__Name`,`Library_Plate_Number`,`Original_Quadrant`)
) TYPE=InnoDB;

