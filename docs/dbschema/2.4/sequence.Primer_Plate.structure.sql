-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Primer_Plate`
--

DROP TABLE IF EXISTS `Primer_Plate`;
CREATE TABLE `Primer_Plate` (
  `Primer_Plate_ID` int(11) NOT NULL auto_increment,
  `Primer_Plate_Name` text,
  `Order_DateTime` datetime default NULL,
  `Arrival_DateTime` datetime default NULL,
  `Primer_Plate_Status` enum('To Order','Ordered','Received','Inactive') default NULL,
  `FK_Solution__ID` int(11) default NULL,
  `Notes` varchar(40) default NULL,
  `Notify_List` text,
  `FK_Lab_Request__ID` int(11) default NULL,
  PRIMARY KEY  (`Primer_Plate_ID`),
  KEY `primerplate_arrival` (`Arrival_DateTime`),
  KEY `primerplate_status` (`Primer_Plate_Status`),
  KEY `primerplate_name` (`Primer_Plate_Name`(40)),
  KEY `FK_Solution__ID` (`FK_Solution__ID`),
  KEY `FK_Lab_Request__ID` (`FK_Lab_Request__ID`)
) TYPE=InnoDB;

