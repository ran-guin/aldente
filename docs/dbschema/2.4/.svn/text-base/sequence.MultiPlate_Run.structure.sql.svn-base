-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `MultiPlate_Run`
--

DROP TABLE IF EXISTS `MultiPlate_Run`;
CREATE TABLE `MultiPlate_Run` (
  `MultiPlate_Run_ID` int(11) NOT NULL auto_increment,
  `FKMaster_Run__ID` int(11) default NULL,
  `FK_Run__ID` int(11) default NULL,
  `MultiPlate_Run_Quadrant` char(1) default NULL,
  PRIMARY KEY  (`MultiPlate_Run_ID`),
  KEY `FK_Sequence__ID` (`FK_Run__ID`),
  KEY `FKMaster_Sequence__ID` (`FKMaster_Run__ID`)
) TYPE=InnoDB;

