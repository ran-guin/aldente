-- MySQL dump 10.9
--
-- Host: lims02    Database: sequence
-- ------------------------------------------------------
-- Server version	4.1.20-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `RNA_DNA_Source`
--

DROP TABLE IF EXISTS `RNA_DNA_Source`;
CREATE TABLE `RNA_DNA_Source` (
  `RNA_DNA_Source_ID` int(11) NOT NULL auto_increment,
  `FK_Source__ID` int(11) NOT NULL default '0',
  `Sample_Collection_Date` date NOT NULL default '0000-00-00',
  `RNA_DNA_Isolation_Date` date NOT NULL default '0000-00-00',
  `RNA_DNA_Isolation_Method` varchar(40) default NULL,
  `Nature` enum('','Total RNA','mRNA','Tissue','Cells','RNA - DNase Treated','cDNA','1st strand cDNA','Amplified cDNA','Ditag','Concatemer - Insert','Concatemer - Cloned','DNA','labeled cRNA') default NULL,
  `Description` text,
  `Submitted_Amount` double(8,4) default NULL,
  `Submitted_Amount_Units` enum('','Cells','Embryos','Litters','Organs','mg','ug','ng','pg') default NULL,
  `Storage_Medium` enum('','RNALater','Trizol','Lysis Buffer','Ethanol','DEPC Water','Qiazol','TE 10:0.1','TE 10:1','RNAse-free Water','Water','EB Buffer') default NULL,
  `Storage_Medium_Quantity` double(8,4) default NULL,
  `storage_medium_quantity_units` enum('','ml','ul') default NULL,
  PRIMARY KEY  (`RNA_DNA_Source_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

