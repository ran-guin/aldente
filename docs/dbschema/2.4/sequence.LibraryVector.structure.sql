-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `LibraryVector`
--

DROP TABLE IF EXISTS `LibraryVector`;
CREATE TABLE `LibraryVector` (
  `LibraryVector_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) default NULL,
  `FK_Vector__ID` int(11) NOT NULL default '0',
  `Vector_Type` enum('Plasmid','Fosmid','Cosmid','BAC') default NULL,
  PRIMARY KEY  (`LibraryVector_ID`),
  UNIQUE KEY `combo` (`FK_Library__Name`,`FK_Vector__ID`),
  KEY `FK_Vector__ID` (`FK_Vector__ID`)
) TYPE=InnoDB;

