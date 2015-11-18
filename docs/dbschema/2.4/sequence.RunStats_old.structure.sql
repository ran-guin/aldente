-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `RunStats_old`
--

DROP TABLE IF EXISTS `RunStats_old`;
CREATE TABLE `RunStats_old` (
  `RunStats_ID` int(11) NOT NULL auto_increment,
  `Q20array` blob,
  `SLarray` blob,
  `Q20mean` int(11) default NULL,
  `Q20median` int(11) default NULL,
  `Q20max` int(11) default NULL,
  `Q20min` int(11) default NULL,
  `SLmean` int(11) default NULL,
  `SLmedian` int(11) default NULL,
  `SLmax` int(11) default NULL,
  `SLmin` int(11) default NULL,
  `FK_Sequence__ID` int(11) NOT NULL default '0',
  `QVmean` int(11) default NULL,
  `QVtotal` int(11) default NULL,
  `Wells` int(11) default NULL,
  `NGs` int(11) default NULL,
  `SGs` int(11) default NULL,
  `QLmean` int(11) default NULL,
  `QLtotal` int(11) default NULL,
  `Q20total` int(11) default NULL,
  `SLtotal` int(11) default NULL,
  `AllReads` int(11) default NULL,
  `AllBPs` int(11) default NULL,
  `VectorSegmentWarnings` int(11) default NULL,
  `ContaminationWarnings` int(11) default NULL,
  `VectorOnlyWarnings` int(11) default NULL,
  `RecurringStringWarnings` int(11) default NULL,
  `PoorQualityWarnings` int(11) default NULL,
  `successful_reads` int(11) NOT NULL default '0',
  `trimmed_successful_reads` int(11) NOT NULL default '0',
  `A_SStotal` int(11) default NULL,
  `T_SStotal` int(11) default NULL,
  `G_SStotal` int(11) default NULL,
  `C_SStotal` int(11) default NULL,
  PRIMARY KEY  (`RunStats_ID`),
  UNIQUE KEY `run` (`FK_Sequence__ID`)
) TYPE=InnoDB;

