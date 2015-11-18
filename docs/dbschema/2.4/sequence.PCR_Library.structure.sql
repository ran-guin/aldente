-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `PCR_Library`
--

DROP TABLE IF EXISTS `PCR_Library`;
CREATE TABLE `PCR_Library` (
  `PCR_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `Species` varchar(40) NOT NULL default '',
  `Cleanup_Procedure` text NOT NULL,
  `PCR_Product_Size` int(11) NOT NULL default '0',
  `Concentration_Per_Well` float(10,3) NOT NULL default '0.000',
  PRIMARY KEY  (`PCR_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`)
) TYPE=InnoDB;

