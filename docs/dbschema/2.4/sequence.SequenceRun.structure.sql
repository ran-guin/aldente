-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `SequenceRun`
--

DROP TABLE IF EXISTS `SequenceRun`;
CREATE TABLE `SequenceRun` (
  `SequenceRun_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) default NULL,
  `FK_Chemistry_Code__Name` varchar(5) default NULL,
  `FKPrimer_Solution__ID` int(11) default NULL,
  `FKMatrix_Solution__ID` int(11) default NULL,
  `FKBuffer_Solution__ID` int(11) default NULL,
  `DNA_Volume` float default NULL,
  `Total_Prep_Volume` smallint(6) default NULL,
  `BrewMix_Concentration` float default NULL,
  `Reaction_Volume` tinyint(4) default NULL,
  `Resuspension_Volume` tinyint(4) default NULL,
  `Slices` varchar(20) default NULL,
  `Run_Format` enum('96','384','96x4','16xN') default NULL,
  `Run_Module` varchar(128) default NULL,
  `Run_Time` int(11) default NULL,
  `Run_Voltage` int(11) default NULL,
  `Run_Temperature` int(11) default NULL,
  `Injection_Time` int(11) default NULL,
  `Injection_Voltage` int(11) default NULL,
  `Mobility_Version` enum('','1','2','3') default '',
  `PlateSealing` enum('None','Foil','Heat Sealing','Septa') default 'None',
  PRIMARY KEY  (`SequenceRun_ID`),
  UNIQUE KEY `FK_Run__ID_2` (`FK_Run__ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FKPrimer_Solution__ID` (`FKPrimer_Solution__ID`),
  KEY `FK_Chemistry_Code__Name` (`FK_Chemistry_Code__Name`),
  KEY `FKMatrix_Solution__ID` (`FKMatrix_Solution__ID`,`FKBuffer_Solution__ID`)
) TYPE=InnoDB;

