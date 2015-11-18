-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Funding_Segment`
--

DROP TABLE IF EXISTS `Funding_Segment`;
CREATE TABLE `Funding_Segment` (
  `Funding_Segment_ID` int(11) NOT NULL auto_increment,
  `FK_Funding__ID` int(11) default NULL,
  `Amount` int(11) default NULL,
  `Currency` enum('US','Canadian') default NULL,
  `Funding_Segment_Notes` text,
  PRIMARY KEY  (`Funding_Segment_ID`),
  KEY `FK_Funding__ID` (`FK_Funding__ID`)
) TYPE=InnoDB;

