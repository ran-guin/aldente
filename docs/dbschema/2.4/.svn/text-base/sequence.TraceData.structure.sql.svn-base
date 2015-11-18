-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `TraceData`
--

DROP TABLE IF EXISTS `TraceData`;
CREATE TABLE `TraceData` (
  `FK_Sequence__ID` int(11) default NULL,
  `TraceData_ID` int(11) NOT NULL auto_increment,
  `Mirrored` int(11) default '0',
  `Archived` int(11) default '0',
  `Checked` datetime default NULL,
  `Machine` varchar(20) default NULL,
  `Links` int(11) default NULL,
  `Files` int(11) default NULL,
  `Broken` int(11) default NULL,
  `Path` enum('','Not Found','OK') default '',
  `Zipped` int(11) default NULL,
  `Format` varchar(20) default NULL,
  `MirroredSize` int(11) default NULL,
  `ArchivedSize` int(11) default NULL,
  `ZippedSize` int(11) default NULL,
  PRIMARY KEY  (`TraceData_ID`),
  UNIQUE KEY `run` (`FK_Sequence__ID`)
) TYPE=InnoDB;

