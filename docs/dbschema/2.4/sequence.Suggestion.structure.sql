-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Suggestion`
--

DROP TABLE IF EXISTS `Suggestion`;
CREATE TABLE `Suggestion` (
  `Suggestion_ID` int(11) NOT NULL auto_increment,
  `Suggestion_Text` text,
  `Suggestion_Date` date default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Response_Text` text,
  `Implementation_Date` date default NULL,
  `Priority` enum('Urgent','Useful','Wish') NOT NULL default 'Urgent',
  PRIMARY KEY  (`Suggestion_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`)
) TYPE=InnoDB;

