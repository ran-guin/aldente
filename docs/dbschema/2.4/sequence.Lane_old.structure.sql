-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Lane_old`
--

DROP TABLE IF EXISTS `Lane_old`;
CREATE TABLE `Lane_old` (
  `FK_Gel__ID` int(11) unsigned NOT NULL default '0',
  `Well` char(3) NOT NULL default '',
  `Comments` enum('no digest','partial digest','no DNA','ambiguous','vector only','contaminated') default NULL,
  `Lane_No` int(11) NOT NULL default '0',
  `Lane_ID` int(11) NOT NULL auto_increment,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Band_Size_Estimate` int(11) default NULL,
  PRIMARY KEY  (`Lane_ID`),
  UNIQUE KEY `well` (`FK_Gel__ID`,`Well`),
  KEY `sample_id` (`FK_Sample__ID`)
) TYPE=InnoDB;

