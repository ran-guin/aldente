-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Well_Lookup`
--

DROP TABLE IF EXISTS `Well_Lookup`;
CREATE TABLE `Well_Lookup` (
  `Plate_384` char(3) NOT NULL default '',
  `Plate_96` char(3) NOT NULL default '',
  `Quadrant` char(1) NOT NULL default '',
  UNIQUE KEY `P384` (`Plate_384`),
  UNIQUE KEY `P96W` (`Plate_96`,`Quadrant`)
) TYPE=InnoDB;

