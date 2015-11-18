-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Issue`
--

DROP TABLE IF EXISTS `Issue`;
CREATE TABLE `Issue` (
  `Issue_ID` int(11) NOT NULL auto_increment,
  `Type` enum('Reported','Defect','Enhancement','Conformance','Maintenance','Requirement','Work Request','Ongoing Maintenance','User Error') default NULL,
  `Description` text NOT NULL,
  `Priority` enum('Critical','High','Medium','Low') NOT NULL default 'High',
  `Severity` enum('Fatal','Major','Minor','Cosmetic') NOT NULL default 'Major',
  `Status` enum('Reported','Approved','Open','In Process','Resolved','Closed','Deferred') default 'Reported',
  `Found_Release` varchar(9) NOT NULL default '',
  `Assigned_Release` varchar(9) default NULL,
  `FKSubmitted_Employee__ID` int(11) NOT NULL default '0',
  `Submitted_DateTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `FKAssigned_Employee__ID` int(11) default NULL,
  `Resolution` enum('By Design','Cannot Reproduce','Code Fix','Data Fix','Do Not Fix','Duplicate Issue','False Submission','System Fix','Code Design') default NULL,
  `Estimated_Time` float default NULL,
  `Estimated_Time_Unit` enum('FTE','Minutes','Hours','Days','Weeks','Months') default NULL,
  `Actual_Time` float default NULL,
  `Actual_Time_Unit` enum('Minutes','Hours','Days','Weeks','Months') default NULL,
  `Last_Modified` datetime default NULL,
  `FK_Department__ID` int(11) default NULL,
  `SubType` enum('General','View','Forms','I/O','Report','Settings','Error Checking','Auto-Notification','Documentation','Scanner','Background Process') default 'General',
  `FKParent_Issue__ID` int(11) default NULL,
  `Issue_Comment` text NOT NULL,
  `FK_Grp__ID` int(11) NOT NULL default '1',
  `Latest_ETA` decimal(10,2) default NULL,
  PRIMARY KEY  (`Issue_ID`),
  KEY `Priority` (`Priority`),
  KEY `Severity` (`Severity`),
  KEY `Status` (`Status`),
  KEY `Submitted` (`FKSubmitted_Employee__ID`),
  KEY `Assigned` (`FKAssigned_Employee__ID`),
  KEY `Resolution` (`Resolution`),
  KEY `FKParent_Issue__ID` (`FKParent_Issue__ID`),
  KEY `FK_Department__ID` (`FK_Department__ID`)
) TYPE=InnoDB;

