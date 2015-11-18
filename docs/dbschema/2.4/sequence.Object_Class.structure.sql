-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Object_Class`
--

DROP TABLE IF EXISTS `Object_Class`;
CREATE TABLE `Object_Class` (
  `Object_Class_ID` int(11) NOT NULL auto_increment,
  `Object_Class` varchar(40) NOT NULL default '',
  `Object_Type` enum('Solution','') default NULL,
  PRIMARY KEY  (`Object_Class_ID`),
  UNIQUE KEY `object_type_class` (`Object_Type`,`Object_Class`),
  KEY `Object_Type` (`Object_Type`),
  KEY `Object_Class` (`Object_Class`)
) TYPE=InnoDB COMMENT='Object Types in the database, ie Enzyme, Antibiotic';

