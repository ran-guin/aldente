-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Submission`
--

DROP TABLE IF EXISTS `Submission`;
CREATE TABLE `Submission` (
  `Submission_ID` int(11) NOT NULL auto_increment,
  `Submission_DateTime` datetime default NULL,
  `Submission_Source` enum('External','Internal') default NULL,
  `Submission_Status` enum('Draft','Submitted','Partially Approved','Approved','Completed','Cancelled','Rejected') default NULL,
  `FK_Contact__ID` int(11) default NULL,
  `FKSubmitted_Employee__ID` int(11) default NULL,
  `Submission_Comments` text,
  `FKApproved_Employee__ID` int(11) default NULL,
  `Approved_DateTime` datetime default NULL,
  PRIMARY KEY  (`Submission_ID`),
  KEY `FKSubmitted_Employee__ID` (`FKSubmitted_Employee__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKApproved_Employee__ID` (`FKApproved_Employee__ID`)
) TYPE=InnoDB;

