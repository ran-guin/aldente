-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Tube`
--

DROP TABLE IF EXISTS `Tube`;
CREATE TABLE `Tube` (
  `Tube_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `Tube_Quantity` float default NULL,
  `Tube_Quantity_Units` enum('ml','ul','mg','ug','ng','pg') default NULL,
  `Quantity_Used` float default NULL,
  `Quantity_Used_Units` enum('ml','ul','mg','ug','ng','pg') default NULL,
  `Concentration` float default NULL,
  `Concentration_Units` enum('cfu','ng/ul','ug/ul') default NULL,
  PRIMARY KEY  (`Tube_ID`),
  KEY `plate_id` (`FK_Plate__ID`)
) TYPE=InnoDB;

