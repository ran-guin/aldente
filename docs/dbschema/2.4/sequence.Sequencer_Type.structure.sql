-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Sequencer_Type`
--

DROP TABLE IF EXISTS `Sequencer_Type`;
CREATE TABLE `Sequencer_Type` (
  `Sequencer_Type_ID` tinyint(4) NOT NULL auto_increment,
  `Sequencer_Type_Name` varchar(20) NOT NULL default '',
  `Well_Ordering` enum('Columns','Rows') NOT NULL default 'Columns',
  `Zero_Pad_Columns` enum('YES','NO') NOT NULL default 'NO',
  `FileFormat` varchar(255) NOT NULL default '',
  `RunDirectory` varchar(255) NOT NULL default '',
  `TraceFileExt` varchar(40) NOT NULL default '',
  `FailedTraceFileExt` varchar(40) NOT NULL default '',
  `SS_extension` varchar(5) default NULL,
  `Default_Terminator` enum('Big Dye','Water') NOT NULL default 'Water',
  `Capillaries` int(3) default NULL,
  `Sliceable` enum('Yes','No') default 'No',
  `By_Quadrant` enum('Yes','No') default 'No',
  PRIMARY KEY  (`Sequencer_Type_ID`)
) TYPE=InnoDB;

