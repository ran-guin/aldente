-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `RNA_Collection`
--

DROP TABLE IF EXISTS `RNA_Collection`;
CREATE TABLE `RNA_Collection` (
  `RNA_Collection_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(6) NOT NULL default '',
  `RNA_Source_Format` enum('RNA_Tube') NOT NULL default 'RNA_Tube',
  `Collection_Type` enum('SAGE','LongSAGE','PCR-SAGE','PCR-LongSAGE','SAGELite-SAGE','SAGELite-LongSAGE') default NULL,
  PRIMARY KEY  (`RNA_Collection_ID`),
  UNIQUE KEY `FK_Library__Name` (`FK_Library__Name`)
) TYPE=InnoDB;

