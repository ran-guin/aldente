-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `LibraryProgress`
--

DROP TABLE IF EXISTS `LibraryProgress`;
CREATE TABLE `LibraryProgress` (
  `LibraryProgress_ID` int(11) NOT NULL auto_increment,
  `LibraryProgress_Date` date default NULL,
  `FK_Library__Name` varchar(5) default NULL,
  `LibraryProgress_Comments` text,
  PRIMARY KEY  (`LibraryProgress_ID`),
  KEY `FK_Library__Name` (`FK_Library__Name`)
) TYPE=InnoDB;

