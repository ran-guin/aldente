-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Error_Check`
--

DROP TABLE IF EXISTS `Error_Check`;
CREATE TABLE `Error_Check` (
  `Error_Check_ID` int(11) NOT NULL auto_increment,
  `Username` varchar(20) NOT NULL default '',
  `Table_Name` mediumtext NOT NULL,
  `Field_Name` mediumtext NOT NULL,
  `Command_Type` enum('SQL','RegExp','FullSQL','Perl') default NULL,
  `Command_String` mediumtext NOT NULL,
  `Notice_Sent` date default NULL,
  `Notice_Frequency` int(11) default NULL,
  `Comments` text,
  `Description` text,
  `Action` text,
  `Priority` mediumtext,
  PRIMARY KEY  (`Error_Check_ID`)
) TYPE=InnoDB;

