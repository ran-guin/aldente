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
-- Table structure for table `Plate`
--

DROP TABLE IF EXISTS `Plate`;
CREATE TABLE `Plate` (
  `Plate_ID` int(11) NOT NULL auto_increment,
  `Plate_Size` enum('1-well','8-well','16-well','32-well','48-well','64-well','80-well','96-well','384-well','1.5 ml','50 ml','15 ml','5 ml','2 ml','0.5 ml','0.2 ml') default NULL,
  `Plate_Created` datetime default '0000-00-00 00:00:00',
  `FK_Library__Name` varchar(40) default NULL,
  `FK_Rack__ID` int(11) default NULL,
  `Plate_Number` int(4) NOT NULL default '0',
  `FK_Employee__ID` int(11) default NULL,
  `FKParent_Plate__ID` int(11) default NULL,
  `Plate_Comments` text NOT NULL,
  `Plate_Status` enum('Active','Pre-Printed','Reserved','Temporary','Failed','Thrown Out','Exported','Archived','On Hold') default NULL,
  `Plate_Test_Status` enum('Test','Production') default 'Production',
  `FK_Plate_Format__ID` int(11) default NULL,
  `Plate_Application` enum('Sequencing','PCR','Mapping','Gene Expression','Affymetrix') default NULL,
  `Plate_Type` enum('Library_Plate','Tube','Array') default NULL,
  `FKOriginal_Plate__ID` int(10) unsigned default NULL,
  `Current_Volume` float default NULL,
  `Current_Volume_Units` enum('l','ml','ul','nl','g','mg','ug','ng') NOT NULL default 'ul',
  `Plate_Content_Type` enum('DNA','RNA','Protein','Mixed','Amplicon','Clone','mRNA','Tissue','Cells','RNA - DNase Treated','cDNA','1st strand cDNA','Amplified cDNA','Ditag','Concatemer - Insert','Concatemer - Cloned') default NULL,
  `Parent_Quadrant` enum('','a','b','c','d') NOT NULL default '',
  `Plate_Parent_Well` char(3) NOT NULL default '',
  `QC_Status` enum('N/A','Pending','Failed','Re-Test','Passed') default 'N/A',
  `FK_Branch__Code` varchar(5) NOT NULL default '',
  `FK_Pipeline__ID` int(11) NOT NULL default '0',
  `Plate_Label` varchar(40) default NULL,
  `FKLast_Prep__ID` int(11) default NULL,
  PRIMARY KEY  (`Plate_ID`),
  KEY `lib` (`FK_Library__Name`),
  KEY `user` (`FK_Employee__ID`),
  KEY `made` (`Plate_Created`),
  KEY `number` (`Plate_Number`),
  KEY `orderlist` (`FK_Library__Name`,`Plate_Number`),
  KEY `parent` (`FKParent_Plate__ID`),
  KEY `format` (`FK_Plate_Format__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKOriginal_Plate__ID` (`FKOriginal_Plate__ID`),
  KEY `FKOriginal_Plate__ID_2` (`FKOriginal_Plate__ID`),
  KEY `Plate_Status` (`Plate_Status`),
  KEY `Plate_Content_Type` (`Plate_Content_Type`),
  KEY `FKLast_Prep__ID` (`FKLast_Prep__ID`),
  KEY `label` (`Plate_Label`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

