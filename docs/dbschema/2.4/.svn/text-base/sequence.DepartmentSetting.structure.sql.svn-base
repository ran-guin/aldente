-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `DepartmentSetting`
--

DROP TABLE IF EXISTS `DepartmentSetting`;
CREATE TABLE `DepartmentSetting` (
  `DepartmentSetting_ID` int(11) NOT NULL auto_increment,
  `FK_Setting__ID` int(11) default NULL,
  `FK_Department__ID` int(11) default NULL,
  `Setting_Value` char(40) default NULL,
  PRIMARY KEY  (`DepartmentSetting_ID`),
  KEY `FK_Department__ID` (`FK_Department__ID`),
  KEY `FK_Setting__ID` (`FK_Setting__ID`)
) TYPE=InnoDB;

