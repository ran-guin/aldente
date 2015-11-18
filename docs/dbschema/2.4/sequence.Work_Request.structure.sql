-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Work_Request`
--

DROP TABLE IF EXISTS `Work_Request`;
CREATE TABLE `Work_Request` (
  `Work_Request_ID` int(11) NOT NULL auto_increment,
  `Plate_Size` enum('96-well','384-well') NOT NULL default '96-well',
  `Plates_To_Seq` int(11) default '0',
  `Plates_To_Pick` int(11) default '0',
  `FK_Goal__ID` int(11) default NULL,
  `Goal_Target` int(11) default NULL,
  `Comments` text,
  `FK_Submission__ID` int(11) NOT NULL default '0',
  `Work_Request_Type` enum('1/16 End Reads','1/24 End Reads','1/256 End Reads','1/16 Custom Reads','1/24 Custom Reads','1/256 Custom Reads','DNA Preps') default NULL,
  `Num_Plates_Submitted` int(11) NOT NULL default '0',
  `FK_Plate_Format__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Work_Request_ID`)
) TYPE=MyISAM;

