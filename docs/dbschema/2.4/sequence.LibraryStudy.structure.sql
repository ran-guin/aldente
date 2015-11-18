-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `LibraryStudy`
--

DROP TABLE IF EXISTS `LibraryStudy`;
CREATE TABLE `LibraryStudy` (
  `LibraryStudy_ID` int(11) NOT NULL auto_increment,
  `FK_Library__Name` varchar(40) default NULL,
  `FK_Study__ID` int(11) default NULL,
  PRIMARY KEY  (`LibraryStudy_ID`),
  KEY `library_name` (`FK_Library__Name`),
  KEY `study_id` (`FK_Study__ID`)
) TYPE=InnoDB;

