-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Lab_Protocol_Pipeline`
--

DROP TABLE IF EXISTS `Lab_Protocol_Pipeline`;
CREATE TABLE `Lab_Protocol_Pipeline` (
  `Lab_Protocol_Pipeline_ID` int(11) NOT NULL auto_increment,
  `FK_Pipeline__ID` int(11) NOT NULL default '0',
  `FK_Lab_Protocol__ID` int(11) NOT NULL default '0',
  `Protocol_Order` tinyint(4) NOT NULL default '0',
  `Mandatory_Protocol` enum('Yes','No') default 'No',
  PRIMARY KEY  (`Lab_Protocol_Pipeline_ID`),
  KEY `FK_Lab_Protocol__ID` (`FK_Lab_Protocol__ID`),
  KEY `FK_Pipeline__ID` (`FK_Pipeline__ID`)
) TYPE=MyISAM;

