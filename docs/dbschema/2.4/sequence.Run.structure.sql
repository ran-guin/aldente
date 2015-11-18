-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Run`
--

DROP TABLE IF EXISTS `Run`;
CREATE TABLE `Run` (
  `Run_ID` int(11) NOT NULL auto_increment,
  `Run_Type` enum('SequenceRun','GelRun','AffyRun') NOT NULL default 'SequenceRun',
  `FK_Plate__ID` int(11) default NULL,
  `FK_RunBatch__ID` int(11) default NULL,
  `Run_DateTime` datetime default NULL,
  `Run_Comments` text,
  `Run_Test_Status` enum('Production','Test') default NULL,
  `FKPosition_Rack__ID` int(11) default NULL,
  `Run_Status` enum('In Process','Analyzed','Aborted','Failed','Expired','Not Applicable') default NULL,
  `Run_Directory` varchar(80) default NULL,
  `Billable` enum('Yes','No') default 'Yes',
  `Run_Validation` enum('Pending','Approved','Rejected') default 'Pending',
  PRIMARY KEY  (`Run_ID`),
  UNIQUE KEY `Run_Directory` (`Run_Directory`),
  KEY `date` (`Run_DateTime`),
  KEY `plate` (`FK_Plate__ID`),
  KEY `state` (`Run_Status`),
  KEY `position` (`FKPosition_Rack__ID`),
  KEY `FK_RunBatch__ID` (`FK_RunBatch__ID`)
) TYPE=InnoDB;

