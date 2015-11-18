-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `ProcedureTest_Condition`
--

DROP TABLE IF EXISTS `ProcedureTest_Condition`;
CREATE TABLE `ProcedureTest_Condition` (
  `ProcedureTest_Condition_ID` int(11) NOT NULL auto_increment,
  `FK_Ordered_Procedure__ID` int(11) NOT NULL default '0',
  `FK_Test_Condition__ID` int(11) NOT NULL default '0',
  `Test_Condition_Number` tinyint(11) NOT NULL default '0',
  PRIMARY KEY  (`ProcedureTest_Condition_ID`),
  KEY `FK_Ordered_Procedure__ID` (`FK_Ordered_Procedure__ID`),
  KEY `FK_Test_Condition__ID` (`FK_Test_Condition__ID`)
) TYPE=InnoDB;

