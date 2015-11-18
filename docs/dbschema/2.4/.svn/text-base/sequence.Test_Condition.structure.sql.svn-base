-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Test_Condition`
--

DROP TABLE IF EXISTS `Test_Condition`;
CREATE TABLE `Test_Condition` (
  `Test_Condition_ID` int(11) NOT NULL auto_increment,
  `Condition_Name` varchar(40) default NULL,
  `Condition_Tables` text,
  `Condition_Field` text,
  `Condition_String` text,
  `Condition_Type` enum('Ready','In Process','Completed','Transferred within Protocol','Ready For Next Protocol','Custom') default 'Custom',
  `Procedure_Link` varchar(80) default NULL,
  `Condition_Description` text,
  `Condition_Key` varchar(40) default NULL,
  `Extra_Clause` text,
  PRIMARY KEY  (`Test_Condition_ID`)
) TYPE=InnoDB;

