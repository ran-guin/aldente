-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Primer_Order`
--

DROP TABLE IF EXISTS `Primer_Order`;
CREATE TABLE `Primer_Order` (
  `Primer_Order_ID` int(11) NOT NULL auto_increment,
  `Primer_Name` varchar(40) default NULL,
  `Order_DateTime` date default NULL,
  `Received_DateTime` date default '0000-00-00',
  `FK_Employee__ID` int(11) default NULL,
  PRIMARY KEY  (`Primer_Order_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

