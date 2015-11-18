-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `DB_Login`
--

DROP TABLE IF EXISTS `DB_Login`;
CREATE TABLE `DB_Login` (
  `DB_Login_ID` int(11) NOT NULL auto_increment,
  `FK_Employee__ID` int(11) NOT NULL default '0',
  `DB_User` char(40) NOT NULL default '',
  PRIMARY KEY  (`DB_Login_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

