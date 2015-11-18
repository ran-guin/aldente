-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `How_To_Step`
--

DROP TABLE IF EXISTS `How_To_Step`;
CREATE TABLE `How_To_Step` (
  `How_To_Step_ID` int(11) NOT NULL auto_increment,
  `How_To_Step_Number` int(11) default NULL,
  `How_To_Step_Description` text,
  `How_To_Step_Result` text,
  `Users` set('A','T','L') default 'T',
  `Mode` set('Scanner','PC') default 'PC',
  `FK_How_To_Topic__ID` int(11) default NULL,
  PRIMARY KEY  (`How_To_Step_ID`),
  KEY `title` (`FK_How_To_Topic__ID`)
) TYPE=InnoDB;

