-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Chemistry_Code`
--

DROP TABLE IF EXISTS `Chemistry_Code`;
CREATE TABLE `Chemistry_Code` (
  `Chemistry_Code_Name` varchar(5) NOT NULL default '',
  `Chemistry_Description` text NOT NULL,
  `FK_Primer__Name` varchar(40) default NULL,
  `Terminator` enum('None','ET','Big Dye') default NULL,
  `Dye` enum('N/A','term') default NULL,
  PRIMARY KEY  (`Chemistry_Code_Name`),
  UNIQUE KEY `code` (`FK_Primer__Name`,`Terminator`)
) TYPE=InnoDB;

