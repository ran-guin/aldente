-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Genomic_Library`
--

DROP TABLE IF EXISTS `Genomic_Library`;
CREATE TABLE `Genomic_Library` (
  `Genomic_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `Vector_Type` enum('Unspecified','Plasmid','Fosmid','Cosmid','BAC') NOT NULL default 'Plasmid',
  `Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `DNA_Shearing_Method` enum('Unspecified','Mechanical','Enzyme') NOT NULL default 'Unspecified',
  `DNA_Shearing_Enzyme` varchar(40) default NULL,
  `384_Well_Plates_To_Pick` int(11) NOT NULL default '0',
  `Genomic_Library_Type` enum('Shotgun','BAC','Fosmid') default NULL,
  PRIMARY KEY  (`Genomic_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`)
) TYPE=InnoDB;

