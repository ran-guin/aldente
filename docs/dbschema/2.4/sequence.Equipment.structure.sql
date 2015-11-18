-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Equipment`
--

DROP TABLE IF EXISTS `Equipment`;
CREATE TABLE `Equipment` (
  `Equipment_ID` int(4) NOT NULL auto_increment,
  `Equipment_Name` varchar(40) default NULL,
  `Equipment_Type` enum('','Sequencer','Centrifuge','Thermal Cycler','Freezer','Liquid Dispenser','Platform Shaker','Incubator','Colony Picker','Plate Reader','Storage','Power Supply','Miscellaneous','Genechip Scanner','Gel Comb','Gel Box','Fluorimager') default NULL,
  `Equipment_Comments` text,
  `Model` text NOT NULL,
  `Serial_Number` varchar(80) default NULL,
  `Acquired` date default NULL,
  `Equipment_Cost` float default NULL,
  `Equipment_Number` int(11) default NULL,
  `Equipment_Number_in_Batch` int(11) default NULL,
  `FK_Stock__ID` int(11) default NULL,
  `Equipment_Alias` varchar(40) default NULL,
  `Equipment_Description` text,
  `Equipment_Location` enum('Sequence Lab','Chromos','CDC','CRC','Functional Genomics','Linen','GE Lab','GE Lab - RNA area','GE Lab - DITAG area','Mapping Lab','MGC Lab') default NULL,
  `Equipment_Status` enum('In Use','Not In Use','Removed') default 'In Use',
  `FK_Location__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Equipment_ID`),
  UNIQUE KEY `equip` (`Equipment_Name`),
  KEY `FK_Stock__ID` (`FK_Stock__ID`)
) TYPE=InnoDB;

