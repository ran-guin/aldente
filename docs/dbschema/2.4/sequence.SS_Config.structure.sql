-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `SS_Config`
--

DROP TABLE IF EXISTS `SS_Config`;
CREATE TABLE `SS_Config` (
  `SS_Config_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencer_Type__ID` int(4) NOT NULL default '0',
  `SS_Title` char(80) NOT NULL default '',
  `SS_Section` int(2) NOT NULL default '0',
  `SS_Order` tinyint(4) default NULL,
  `SS_Default` char(80) NOT NULL default '',
  `SS_Alias` char(80) NOT NULL default '',
  `SS_Orientation` enum('Column','Row','N/A') default NULL,
  `SS_Type` enum('Titled','Untitled','Hidden') NOT NULL default 'Titled',
  `SS_Prompt` enum('Text','Radio','Default','No') default NULL,
  `SS_Track` char(40) NOT NULL default '',
  PRIMARY KEY  (`SS_Config_ID`),
  KEY `FK_Sequencer_Type__ID` (`FK_Sequencer_Type__ID`)
) TYPE=InnoDB;

