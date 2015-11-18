-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `GrantDistribution`
--

DROP TABLE IF EXISTS `GrantDistribution`;
CREATE TABLE `GrantDistribution` (
  `GrantDistribution_ID` int(11) NOT NULL auto_increment,
  `FK_GrantApplication__ID` int(11) default NULL,
  `StartDate` date default NULL,
  `EndDate` date default NULL,
  `Amount` float default NULL,
  `Currency` enum('Canadian','US') default NULL,
  `AwardStatus` enum('Spent','Received','Awarded','Declined','Pending','TBD') default NULL,
  `Spent` float default NULL,
  `SpentAsOf` date default NULL,
  PRIMARY KEY  (`GrantDistribution_ID`),
  KEY `FK_GrantApplication__ID` (`FK_GrantApplication__ID`)
) TYPE=InnoDB;

