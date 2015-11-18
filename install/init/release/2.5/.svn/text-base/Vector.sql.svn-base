-- MySQL dump 10.9
--
-- Host: limsdev02    Database: aldente_init
-- ------------------------------------------------------
-- Server version	4.1.20

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Vector`
--

DROP TABLE IF EXISTS `Vector`;
CREATE TABLE `Vector` (
  `Vector_Name` varchar(40) NOT NULL default '',
  `Vector_Manufacturer` text,
  `Vector_Catalog_Number` text,
  `Vector_Sequence_File` text NOT NULL,
  `Vector_Sequence_Source` text,
  `Antibiotic_Marker` enum('Ampicillin','Zeocin','Kanamycin','Chloramphenicol','Tetracycline','N/A') default NULL,
  `Vector_ID` int(11) NOT NULL auto_increment,
  `Inducer` varchar(40) default NULL,
  `Substrate` varchar(40) default NULL,
  `FKManufacturer_Organization__ID` int(11) default NULL,
  `FKSource_Organization__ID` int(11) default NULL,
  `Vector_Sequence` longtext,
  `FK_Vector_Type__ID` int(11) NOT NULL default '0',
  `Vector_Type` enum('Plasmid','Fosmid','Cosmid','BAC','N/A') default NULL,
  PRIMARY KEY  (`Vector_ID`),
  KEY `FKSource_Organization__ID` (`FKSource_Organization__ID`),
  KEY `FKManufacturer_Organization__ID` (`FKManufacturer_Organization__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

