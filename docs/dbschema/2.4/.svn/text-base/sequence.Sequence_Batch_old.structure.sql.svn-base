-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Sequence_Batch_old`
--

DROP TABLE IF EXISTS `Sequence_Batch_old`;
CREATE TABLE `Sequence_Batch_old` (
  `Sequence_Batch_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) default NULL,
  `FK_Equipment__ID` int(11) default NULL,
  `Sequence_RequestTime` datetime default NULL,
  `FKMatrix_Solution__ID` int(11) default NULL,
  `FKBuffer_Solution__ID` int(11) default NULL,
  `Injection_Voltage` int(11) default NULL,
  `Injection_Time` int(11) default NULL,
  `Run_Voltage` int(11) default NULL,
  `Run_Time` int(11) default NULL,
  `Run_Temperature` int(11) default NULL,
  `Mobility_Version` enum('','1','2','3') default NULL,
  `Foil_Piercing` enum('ON','OFF','n/a','1','0','-1') default 'n/a',
  `PMT1` int(11) default NULL,
  `PMT2` int(11) default NULL,
  `Agarose_Percentage` float default NULL,
  `Chemistry_Version` enum('','2','3') default NULL,
  `Run_Batch_State` enum('In Process','Analyzed','Aborted','Failed','Expired') default NULL,
  `Run_Plates` int(11) default NULL,
  `Sequence_Batch_Comments` text,
  `PlateSealing` enum('None','Foil','Heat Sealing','Septa') default NULL,
  PRIMARY KEY  (`Sequence_Batch_ID`),
  KEY `sequencer` (`FK_Equipment__ID`),
  KEY `user` (`FK_Employee__ID`),
  KEY `FKBuffer_Solution__ID` (`FKBuffer_Solution__ID`),
  KEY `FKMatrix_Solution__ID` (`FKMatrix_Solution__ID`)
) TYPE=InnoDB;

