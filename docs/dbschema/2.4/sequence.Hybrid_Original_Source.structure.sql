-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Hybrid_Original_Source`
--

DROP TABLE IF EXISTS `Hybrid_Original_Source`;
CREATE TABLE `Hybrid_Original_Source` (
  `Hybrid_Original_Source_ID` int(11) NOT NULL auto_increment,
  `FKParent_Original_Source__ID` int(11) default NULL,
  `FKChild_Original_Source__ID` int(11) default NULL,
  PRIMARY KEY  (`Hybrid_Original_Source_ID`),
  KEY `FKParent_Source__ID` (`FKParent_Original_Source__ID`),
  KEY `FKChild_Original_Source__ID` (`FKChild_Original_Source__ID`)
) TYPE=InnoDB;

