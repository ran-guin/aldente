-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Mixture`
--

DROP TABLE IF EXISTS `Mixture`;
CREATE TABLE `Mixture` (
  `Mixture_ID` int(8) NOT NULL auto_increment,
  `FKMade_Solution__ID` int(11) default NULL,
  `FKUsed_Solution__ID` int(11) default NULL,
  `Quantity_Used` float default NULL,
  `Mixture_Comments` text,
  `Units_Used` varchar(10) default NULL,
  PRIMARY KEY  (`Mixture_ID`),
  KEY `made_solution` (`FKMade_Solution__ID`),
  KEY `used_solution` (`FKUsed_Solution__ID`)
) TYPE=InnoDB;

