-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Order_Notice`
--

DROP TABLE IF EXISTS `Order_Notice`;
CREATE TABLE `Order_Notice` (
  `Minimum_Units` int(11) default NULL,
  `Order_Text` text,
  `Catalog_Number` varchar(40) NOT NULL default '',
  `Notice_Sent` date default NULL,
  `Notice_Frequency` int(11) default NULL,
  `Target_List` text,
  `Maximum_Units` int(11) default '0',
  `Order_Notice_ID` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`Order_Notice_ID`)
) TYPE=InnoDB;

