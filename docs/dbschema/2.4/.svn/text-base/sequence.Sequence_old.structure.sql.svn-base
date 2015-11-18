-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Sequence_old`
--

DROP TABLE IF EXISTS `Sequence_old`;
CREATE TABLE `Sequence_old` (
  `Sequence_ID` int(11) NOT NULL auto_increment,
  `FK_Plate__ID` int(11) default NULL,
  `Sequence_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Sequence_Comments` text NOT NULL,
  `FK_Chemistry_Code__Name` varchar(5) default NULL,
  `Sequence_Subdirectory` varchar(80) NOT NULL default '',
  `FKMatrix_Solution__ID` int(11) default NULL,
  `FKPrimer_Solution__ID` int(11) default NULL,
  `DNA_Volume` float default NULL,
  `Total_Prep_Volume` smallint(6) default NULL,
  `BrewMix_Concentration` float default NULL,
  `Reaction_Volume` tinyint(4) default NULL,
  `Resuspension_Volume` tinyint(4) default NULL,
  `Run_Status` enum('Production','Test') default NULL,
  `Fail_Status` enum('Run Failure','No Data','No Quality','Poor Quality','Prep Failure') default NULL,
  `Run_State` enum('In Process','Analyzed','Aborted','Failed','Expired','Not Applicable') default NULL,
  `FK_Sequence_Batch__ID` int(11) default NULL,
  `Run_Format` enum('96','384','96x4') default NULL,
  `Analysis_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `Run_Number` int(11) NOT NULL default '0',
  `Run_Directory` text,
  `Run_Module` varchar(128) default NULL,
  `Phred_Version` varchar(20) NOT NULL default '',
  `Reads` int(11) default NULL,
  `Billable` enum('Yes','No') default 'Yes',
  `Slices` varchar(20) default NULL,
  `Run_Validation` enum('Pending','Approved','Rejected') default 'Pending',
  PRIMARY KEY  (`Sequence_ID`),
  UNIQUE KEY `ss` (`Sequence_Subdirectory`),
  KEY `path` (`Sequence_Subdirectory`),
  KEY `date` (`Sequence_DateTime`),
  KEY `plate` (`FK_Plate__ID`),
  KEY `batch` (`FK_Sequence_Batch__ID`),
  KEY `status` (`Run_Status`),
  KEY `chemistry` (`FK_Chemistry_Code__Name`),
  KEY `state` (`Run_State`),
  KEY `validation` (`Run_Validation`),
  KEY `billable` (`Billable`),
  KEY `lib` (`Sequence_Subdirectory`(5)),
  KEY `FKMatrix_Solution__ID` (`FKMatrix_Solution__ID`),
  KEY `FKPrimer_Solution__ID` (`FKPrimer_Solution__ID`)
) TYPE=InnoDB;

