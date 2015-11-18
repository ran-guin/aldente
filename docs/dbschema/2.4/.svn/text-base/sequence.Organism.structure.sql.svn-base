-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Organism`
--

DROP TABLE IF EXISTS `Organism`;
CREATE TABLE `Organism` (
  `Organism_ID` int(11) NOT NULL auto_increment,
  `Organism_Name` varchar(255) NOT NULL default '',
  `Species` varchar(255) default NULL,
  `Sub_species` varchar(255) default NULL,
  `Common_Name` varchar(255) default NULL,
  PRIMARY KEY  (`Organism_ID`),
  UNIQUE KEY `organism` (`Organism_Name`,`Species`)
) TYPE=InnoDB;

