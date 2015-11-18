-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `DB_Form`
--

DROP TABLE IF EXISTS `DB_Form`;
CREATE TABLE `DB_Form` (
  `DB_Form_ID` int(11) NOT NULL auto_increment,
  `Form_Table` varchar(80) NOT NULL default '',
  `Form_Order` int(2) default '1',
  `Min_Records` int(2) NOT NULL default '1',
  `Max_Records` int(2) NOT NULL default '1',
  `FKParent_DB_Form__ID` int(11) default NULL,
  `Parent_Field` varchar(80) default NULL,
  `Parent_Value` varchar(200) default NULL,
  `Finish` int(11) default '0',
  `Class` varchar(40) default NULL,
  PRIMARY KEY  (`DB_Form_ID`),
  KEY `FKParent_DB_Form__ID` (`FKParent_DB_Form__ID`)
) TYPE=InnoDB;

