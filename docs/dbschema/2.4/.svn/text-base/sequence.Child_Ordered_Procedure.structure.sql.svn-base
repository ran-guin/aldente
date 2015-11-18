-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Child_Ordered_Procedure`
--

DROP TABLE IF EXISTS `Child_Ordered_Procedure`;
CREATE TABLE `Child_Ordered_Procedure` (
  `Child_Ordered_Procedure_ID` int(11) NOT NULL auto_increment,
  `FKParent_Ordered_Procedure__ID` int(11) NOT NULL default '0',
  `FKChild_Ordered_Procedure__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Child_Ordered_Procedure_ID`),
  KEY `FKParent_Procedure__ID` (`FKParent_Ordered_Procedure__ID`),
  KEY `FKChild_Procedure__ID` (`FKChild_Ordered_Procedure__ID`)
) TYPE=InnoDB;

