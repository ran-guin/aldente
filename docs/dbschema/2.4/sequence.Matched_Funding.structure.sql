-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Matched_Funding`
--

DROP TABLE IF EXISTS `Matched_Funding`;
CREATE TABLE `Matched_Funding` (
  `Matched_Funding_ID` int(11) NOT NULL auto_increment,
  `Matched_Funding_Number` int(11) default NULL,
  `FK_Funding__ID` int(11) default NULL,
  PRIMARY KEY  (`Matched_Funding_ID`),
  KEY `FK_Funding__ID` (`FK_Funding__ID`)
) TYPE=InnoDB;

