-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `LibraryApplication`
--

DROP TABLE IF EXISTS `LibraryApplication`;
CREATE TABLE `LibraryApplication` (
  `LibraryApplication_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) NOT NULL default '',
  `Object_ID` varchar(40) NOT NULL default '',
  `FK_Object_Class__ID` int(11) NOT NULL default '0',
  `Direction` enum('3prime','5prime','N/A','Unknown') default 'N/A',
  PRIMARY KEY  (`LibraryApplication_ID`),
  UNIQUE KEY `LibApp` (`FK_Library__Name`,`Object_ID`,`FK_Object_Class__ID`),
  KEY `FK_Library__Name` (`FK_Library__Name`),
  KEY `Object_ID` (`Object_ID`),
  KEY `FK_Object_Class__ID` (`FK_Object_Class__ID`)
) TYPE=InnoDB COMMENT='Generic TABLE for reagents (etc) applied to a library';

