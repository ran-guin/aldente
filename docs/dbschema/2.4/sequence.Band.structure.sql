-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Band`
--

DROP TABLE IF EXISTS `Band`;
CREATE TABLE `Band` (
  `Band_ID` int(11) unsigned NOT NULL auto_increment,
  `Band_Size` int(10) unsigned default NULL,
  `Band_Number` int(4) unsigned default NULL,
  `FKParent_Band__ID` int(11) default NULL,
  `FK_Lane__ID` int(11) unsigned default NULL,
  `Band_Intensity` enum('Weak','Medium','Strong') default NULL,
  `Band_Type` enum('Insert','Vector') default NULL,
  PRIMARY KEY  (`Band_ID`),
  KEY `FKParent_Band__ID` (`FKParent_Band__ID`),
  KEY `lane` (`FK_Lane__ID`)
) TYPE=InnoDB;

