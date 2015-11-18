-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `EmployeeSetting`
--

DROP TABLE IF EXISTS `EmployeeSetting`;
CREATE TABLE `EmployeeSetting` (
  `EmployeeSetting_ID` int(11) NOT NULL auto_increment,
  `FK_Setting__ID` int(11) default NULL,
  `FK_Employee__ID` int(11) default NULL,
  `Setting_Value` char(40) default NULL,
  PRIMARY KEY  (`EmployeeSetting_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Setting__ID` (`FK_Setting__ID`)
) TYPE=InnoDB;

