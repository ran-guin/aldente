-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Prep_Details`
--

DROP TABLE IF EXISTS `Prep_Details`;
CREATE TABLE `Prep_Details` (
  `Prep_Details_ID` int(11) NOT NULL auto_increment,
  `FK_Prep__ID` int(11) NOT NULL default '0',
  `FK_Attribute__ID` int(11) NOT NULL default '0',
  `Prep_Details_Value` text,
  PRIMARY KEY  (`Prep_Details_ID`),
  KEY `prep_id` (`FK_Prep__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
) TYPE=InnoDB;

