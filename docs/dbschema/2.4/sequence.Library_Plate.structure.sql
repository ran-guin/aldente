-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Library_Plate`
--

DROP TABLE IF EXISTS `Library_Plate`;
CREATE TABLE `Library_Plate` (
  `Library_Plate_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `Plate_Class` enum('Standard','ReArray','Oligo') default 'Standard',
  `No_Grows` text,
  `Slow_Grows` text,
  `Unused_Wells` text,
  `Sub_Quadrants` set('','a','b','c','d','none') default NULL,
  `Slice` varchar(8) default NULL,
  `Plate_Position` enum('','a','b','c','d') default '',
  `Problematic_Wells` text,
  `Empty_Wells` text,
  PRIMARY KEY  (`Library_Plate_ID`),
  KEY `plate_id` (`FK_Plate__ID`)
) TYPE=InnoDB;

