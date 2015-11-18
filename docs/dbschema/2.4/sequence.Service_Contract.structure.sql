-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Service_Contract`
--

DROP TABLE IF EXISTS `Service_Contract`;
CREATE TABLE `Service_Contract` (
  `Service_Contract_BeginDate` date default NULL,
  `Service_Contract_ExpiryDate` date default NULL,
  `FK_Organization__ID` int(11) default NULL,
  `FK_Equipment__ID` int(11) default NULL,
  `FK_Orders__ID` int(11) default NULL,
  `Service_Contract_Number` int(11) default NULL,
  `Service_Contract_Number_in_Batch` int(11) default NULL,
  `Service_Contract_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Service_Contract_ID`),
  KEY `FK_Orders__ID` (`FK_Orders__ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`)
) TYPE=InnoDB;

