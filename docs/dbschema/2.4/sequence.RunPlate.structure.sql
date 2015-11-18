-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `RunPlate`
--

DROP TABLE IF EXISTS `RunPlate`;
CREATE TABLE `RunPlate` (
  `Sequence_ID` int(11) NOT NULL default '0',
  `Plate_Number` int(4) NOT NULL default '0',
  `Parent_Quadrant` char(1) default ''
) TYPE=InnoDB;

