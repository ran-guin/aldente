-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `RNA_Source`
--

DROP TABLE IF EXISTS `RNA_Source`;
CREATE TABLE `RNA_Source` (
  `RNA_Source_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `Sample_Collection_Date` date NOT NULL default '0000-00-00',
  `RNA_Isolation_Date` date NOT NULL default '0000-00-00',
  `RNA_Isolation_Method` varchar(40) default NULL,
  `Nature` enum('','Total RNA','mRNA','Tissue','Cells','RNA - DNase Treated','cDNA','1st strand cDNA','Amplified cDNA','Ditag','Concatemer - Insert','Concatemer - Cloned') NOT NULL default '',
  `Description` text,
  `Submitted_Amount` double(8,4) default NULL,
  `Submitted_Amount_Units` enum('','Cells','Embryos','Litters','Organs','mg','ug','ng','pg') default NULL,
  `Storage_Medium` enum('','RNALater','Trizol','Lysis Buffer','Ethanol','DEPC Water','Qiazol') default '',
  `Storage_Medium_Quantity` double(8,4) default NULL,
  `Storage_Medium_Quantity_Units` enum('ml','ul') default NULL,
  PRIMARY KEY  (`RNA_Source_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) TYPE=InnoDB;

