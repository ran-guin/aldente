-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `PoolSample`
--

DROP TABLE IF EXISTS `PoolSample`;
CREATE TABLE `PoolSample` (
  `PoolSample_ID` int(11) NOT NULL auto_increment,
  `FK_Pool__ID` int(11) NOT NULL default '0',
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `Well` char(3) default NULL,
  `FK_Sample__ID` int(11) default NULL,
  `Sample_Quantity_Units` enum('ml','ul','mg','ug','ng','pg') default NULL,
  `Sample_Quantity` float default NULL,
  PRIMARY KEY  (`PoolSample_ID`),
  KEY `sample` (`FK_Sample__ID`),
  KEY `pool` (`FK_Pool__ID`),
  KEY `plated` (`FK_Plate__ID`,`Well`)
) TYPE=InnoDB;

