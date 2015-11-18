-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `EST_Library`
--

DROP TABLE IF EXISTS `EST_Library`;
CREATE TABLE `EST_Library` (
  `EST_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `5Prime_Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `3Prime_Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `Blue_White_Selection` enum('Yes','No') NOT NULL default 'Yes',
  `Enriched_For_Full_Length` enum('Yes','No') NOT NULL default 'Yes',
  `Construction_Correction` enum('','Normalized','Subtracted') NOT NULL default '',
  `FK3PrimeInsert_Restriction_Site__ID` int(11) default NULL,
  `FK5PrimeInsert_Restriction_Site__ID` int(11) default NULL,
  PRIMARY KEY  (`EST_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`),
  KEY `FK3PrimeInsert_Restriction_Site__ID` (`FK3PrimeInsert_Restriction_Site__ID`),
  KEY `FK5PrimeInsert_Restriction_Site__ID` (`FK5PrimeInsert_Restriction_Site__ID`)
) TYPE=InnoDB;

