-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Vector_TypeAntibiotic`
--

DROP TABLE IF EXISTS `Vector_TypeAntibiotic`;
CREATE TABLE `Vector_TypeAntibiotic` (
  `Vector_TypeAntibiotic_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Vector_Type__ID` int(11) NOT NULL default '0',
  `FK_Antibiotic__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Vector_TypeAntibiotic_ID`),
  UNIQUE KEY `combo` (`FK_Vector_Type__ID`,`FK_Antibiotic__ID`),
  KEY `FK_Vector_Type__ID` (`FK_Vector_Type__ID`),
  KEY `FK_Antibiotic__ID` (`FK_Antibiotic__ID`)
) TYPE=InnoDB;

