-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `ReArray`
--

DROP TABLE IF EXISTS `ReArray`;
CREATE TABLE `ReArray` (
  `FKSource_Plate__ID` int(11) NOT NULL default '0',
  `Source_Well` char(3) NOT NULL default '',
  `Target_Well` char(3) NOT NULL default '',
  `ReArray_ID` int(11) NOT NULL auto_increment,
  `FK_ReArray_Request__ID` int(11) NOT NULL default '0',
  `FK_Sample__ID` int(11) default '-1',
  PRIMARY KEY  (`ReArray_ID`),
  KEY `rearray_req` (`FK_ReArray_Request__ID`),
  KEY `target` (`Target_Well`),
  KEY `source` (`FKSource_Plate__ID`),
  KEY `fk_sample` (`FK_Sample__ID`)
) TYPE=InnoDB;

