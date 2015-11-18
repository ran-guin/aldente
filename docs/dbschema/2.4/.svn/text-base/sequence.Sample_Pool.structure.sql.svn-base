-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Sample_Pool`
--

DROP TABLE IF EXISTS `Sample_Pool`;
CREATE TABLE `Sample_Pool` (
  `Sample_Pool_ID` int(11) NOT NULL auto_increment,
  `FK_Pool__ID` int(11) NOT NULL default '0',
  `FKTarget_Plate__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Sample_Pool_ID`),
  UNIQUE KEY `pool_id` (`FK_Pool__ID`),
  UNIQUE KEY `target_plate` (`FKTarget_Plate__ID`)
) TYPE=InnoDB;

