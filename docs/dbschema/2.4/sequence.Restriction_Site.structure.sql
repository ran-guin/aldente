-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Restriction_Site`
--

DROP TABLE IF EXISTS `Restriction_Site`;
CREATE TABLE `Restriction_Site` (
  `Restriction_Site_Name` varchar(20) NOT NULL default '',
  `Recognition_Sequence` text,
  `Restriction_Site_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Restriction_Site_ID`),
  UNIQUE KEY `Restriction_Site_Name` (`Restriction_Site_Name`)
) TYPE=InnoDB;

