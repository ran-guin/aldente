-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Tray`
--

DROP TABLE IF EXISTS `Tray`;
CREATE TABLE `Tray` (
  `Tray_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Tray_ID`)
) TYPE=InnoDB COMMENT='For multiple objects on a tray';

