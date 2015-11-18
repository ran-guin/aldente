-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `ProjectStudy`
--

DROP TABLE IF EXISTS `ProjectStudy`;
CREATE TABLE `ProjectStudy` (
  `ProjectStudy_ID` int(11) NOT NULL auto_increment,
  `FK_Project__ID` int(11) default NULL,
  `FK_Study__ID` int(11) default NULL,
  PRIMARY KEY  (`ProjectStudy_ID`),
  UNIQUE KEY `projectstudy` (`FK_Project__ID`,`FK_Study__ID`),
  KEY `project_id` (`FK_Project__ID`),
  KEY `study_id` (`FK_Study__ID`)
) TYPE=InnoDB;

