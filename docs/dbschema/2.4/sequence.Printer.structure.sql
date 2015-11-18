-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Printer`
--

DROP TABLE IF EXISTS `Printer`;
CREATE TABLE `Printer` (
  `Printer_ID` int(11) NOT NULL auto_increment,
  `Printer_Name` varchar(40) default '',
  `Printer_DPI` int(11) NOT NULL default '0',
  `Printer_Location` varchar(40) default NULL,
  `Printer_Type` varchar(40) NOT NULL default '',
  `Printer_Address` varchar(80) NOT NULL default '',
  `Printer_Output` enum('text','ZPL','latex') default 'ZPL',
  PRIMARY KEY  (`Printer_ID`),
  KEY `prnname` (`Printer_Name`)
) TYPE=MyISAM;

