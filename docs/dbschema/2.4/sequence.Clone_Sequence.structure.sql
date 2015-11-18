-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Clone_Sequence`
--

DROP TABLE IF EXISTS `Clone_Sequence`;
CREATE TABLE `Clone_Sequence` (
  `FK_Run__ID` int(11) default NULL,
  `Sequence` text NOT NULL,
  `Sequence_Scores` blob NOT NULL,
  `Quality_Left` smallint(6) NOT NULL default '-2',
  `Vector_Quality` smallint(6) NOT NULL default '-2',
  `Vector_Total` smallint(6) NOT NULL default '-2',
  `Well` char(3) NOT NULL default '',
  `Phred_Histogram` varchar(200) NOT NULL default '',
  `Vector_Left` smallint(6) NOT NULL default '-2',
  `Vector_Right` smallint(6) NOT NULL default '-2',
  `Sequence_Length` smallint(6) NOT NULL default '-2',
  `Quality_Histogram` varchar(200) NOT NULL default '',
  `Quality_Length` smallint(6) NOT NULL default '-2',
  `Clone_Sequence_Comments` varchar(255) NOT NULL default '',
  `FK_Note__ID` tinyint(4) default NULL,
  `Growth` enum('OK','Slow Grow','No Grow','Unused','Empty','Problematic') default NULL,
  `Test_Run_Flag` tinyint(4) NOT NULL default '0',
  `Capillary` char(3) NOT NULL default '',
  `Clone_Sequence_ID` int(11) NOT NULL auto_increment,
  `Read_Error` enum('trace data missing','Empty Read','Analysis Aborted') default NULL,
  `Read_Warning` set('Vector Only','Vector Segment','Recurring String','Contamination','Poor Quality') default NULL,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Peak_Area_Ratio` float(6,5) NOT NULL default '0.00000',
  PRIMARY KEY  (`Clone_Sequence_ID`),
  KEY `growth` (`Growth`),
  KEY `warnings` (`FK_Note__ID`),
  KEY `warning` (`Read_Warning`),
  KEY `clone` (`FK_Sample__ID`),
  KEY `seq_read` (`FK_Run__ID`,`Well`),
  KEY `length` (`Sequence_Length`)
) TYPE=MyISAM MAX_ROWS=4294967295 AVG_ROW_LENGTH=2448;

