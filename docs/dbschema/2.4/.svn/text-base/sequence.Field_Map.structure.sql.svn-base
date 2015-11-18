-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Field_Map`
--

DROP TABLE IF EXISTS `Field_Map`;
CREATE TABLE `Field_Map` (
  `Field_Map_ID` int(11) NOT NULL auto_increment,
  `FK_Attribute__ID` int(11) default NULL,
  `FKSource_DBField__ID` int(11) default NULL,
  `FKTarget_DBField__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Field_Map_ID`),
  UNIQUE KEY `Field_Attr_Map_Key` (`FKTarget_DBField__ID`,`FK_Attribute__ID`),
  UNIQUE KEY `Field_Field_Map_Key` (`FKTarget_DBField__ID`,`FKSource_DBField__ID`)
) TYPE=InnoDB;

