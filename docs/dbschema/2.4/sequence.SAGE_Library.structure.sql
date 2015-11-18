-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `SAGE_Library`
--

DROP TABLE IF EXISTS `SAGE_Library`;
CREATE TABLE `SAGE_Library` (
  `SAGE_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `Concatamer_Size_Fraction` int(11) NOT NULL default '0',
  `Clones_under500Insert_Percent` int(11) default '0',
  `Clones_over500Insert_Percent` int(11) default '0',
  `Tags_Requested` int(11) default NULL,
  `RNA_Extraction` text,
  `SAGE_Library_Type` enum('SAGE','LongSAGE','PCR-SAGE','PCR-LongSAGE','SAGELite-SAGE','SAGELite-LongSAGE') default NULL,
  `FKInsertSite_Enzyme__ID` int(11) default NULL,
  `FKAnchoring_Enzyme__ID` int(11) default NULL,
  `FKTagging_Enzyme__ID` int(11) default NULL,
  `Clones_with_no_Insert_Percent` int(11) default '0',
  `Starting_RNA_Amnt_ng` float(10,3) default NULL,
  `PCR_Cycles` int(11) default NULL,
  `cDNA_Amnt_Used_ng` float(10,3) default NULL,
  `DiTag_PCR_Cycle` int(11) default NULL,
  `DiTag_Template_Dilution_Factor` int(11) default NULL,
  `Adapter_A` varchar(20) default NULL,
  `Adapter_B` varchar(20) default NULL,
  PRIMARY KEY  (`SAGE_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`),
  KEY `FKAnchoring_Enzyme__ID` (`FKAnchoring_Enzyme__ID`),
  KEY `FKTagging_Enzyme__ID` (`FKTagging_Enzyme__ID`),
  KEY `FKInsertSite_Enzyme__ID` (`FKInsertSite_Enzyme__ID`)
) TYPE=InnoDB;

