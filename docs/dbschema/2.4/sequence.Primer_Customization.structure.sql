-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Primer_Customization`
--

DROP TABLE IF EXISTS `Primer_Customization`;
CREATE TABLE `Primer_Customization` (
  `Primer_Customization_ID` int(11) NOT NULL auto_increment,
  `FK_Primer__Name` varchar(40) NOT NULL default '',
  `Tm_Working` float(5,2) default NULL,
  `Direction` enum('Forward','Reverse','Unknown') default 'Unknown',
  `Amplicon_Length` int(11) default NULL,
  `Position` enum('Outer','Nested') default NULL,
  PRIMARY KEY  (`Primer_Customization_ID`),
  KEY `fk_primer` (`FK_Primer__Name`)
) TYPE=InnoDB;

