-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Funding_Distribution`
--

DROP TABLE IF EXISTS `Funding_Distribution`;
CREATE TABLE `Funding_Distribution` (
  `Funding_Distribution_ID` int(11) NOT NULL auto_increment,
  `FK_Funding_Segment__ID` int(11) default NULL,
  `Funding_Start` date default NULL,
  `Funding_End` date default NULL,
  PRIMARY KEY  (`Funding_Distribution_ID`),
  KEY `FK_Funding_Segment__ID` (`FK_Funding_Segment__ID`)
) TYPE=InnoDB;

