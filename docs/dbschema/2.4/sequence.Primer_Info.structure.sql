-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Primer_Info`
--

DROP TABLE IF EXISTS `Primer_Info`;
CREATE TABLE `Primer_Info` (
  `Primer_Info_ID` int(11) NOT NULL auto_increment,
  `FK_Solution__ID` int(11) default NULL,
  `nMoles` float default NULL,
  `micrograms` float default NULL,
  `ODs` float default NULL,
  PRIMARY KEY  (`Primer_Info_ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`)
) TYPE=InnoDB;

