-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Solution_Info`
--

DROP TABLE IF EXISTS `Solution_Info`;
CREATE TABLE `Solution_Info` (
  `Solution_Info_ID` int(11) NOT NULL auto_increment,
  `nMoles` float default NULL,
  `ODs` float default NULL,
  `micrograms` float default NULL,
  PRIMARY KEY  (`Solution_Info_ID`)
) TYPE=InnoDB;

