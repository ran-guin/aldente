-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Primer`
--

DROP TABLE IF EXISTS `Primer`;
CREATE TABLE `Primer` (
  `Primer_Name` varchar(40) NOT NULL default '',
  `Primer_Sequence` text NOT NULL,
  `Primer_ID` int(2) NOT NULL auto_increment,
  `Purity` text,
  `Tm1` int(2) default NULL,
  `Tm50` int(2) default NULL,
  `GC_Percent` int(2) default NULL,
  `Coupling_Eff` float(10,2) default NULL,
  `Primer_Type` enum('Standard','Custom','Oligo','Amplicon','Adapter') default NULL,
  `Primer_OrderDateTime` datetime default NULL,
  `Primer_External_Order_Number` varchar(80) default NULL,
  `Primer_Status` enum('','Ordered','Received','Inactive') default '',
  PRIMARY KEY  (`Primer_ID`),
  UNIQUE KEY `primer` (`Primer_Name`)
) TYPE=InnoDB;

