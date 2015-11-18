-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Library_Segment`
--

DROP TABLE IF EXISTS `Library_Segment`;
CREATE TABLE `Library_Segment` (
  `Library_Segment_ID` int(11) NOT NULL auto_increment,
  `FK_Vector__ID` int(11) NOT NULL default '0',
  `Non_Recombinants` int(11) default NULL,
  `Non_Insert_Clones` int(11) default NULL,
  `Recombinant_Clones` int(11) default NULL,
  `Average_Insert_Size` int(11) default NULL,
  `FK_Antibiotic__ID` int(11) default NULL,
  `Genome_Coverage` int(11) default NULL,
  `FK_Restriction_Site__ID` int(11) default NULL,
  `FK_Source__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Library_Segment_ID`)
) TYPE=InnoDB;

