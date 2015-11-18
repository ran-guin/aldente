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
-- Table structure for table `BioanalyzerRead`
--

DROP TABLE IF EXISTS `BioanalyzerRead`;
CREATE TABLE `BioanalyzerRead` (
  `BioanalyzerRead_ID` int(11) NOT NULL auto_increment,
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `FK_Run__ID` int(11) NOT NULL default '0',
  `Well` varchar(4) default NULL,
  `Well_Status` enum('Empty','OK','Problematic','Unused') default NULL,
  `Well_Category` enum('Sample','Ladder') default NULL,
  `RNA_DNA_Concentration` float default NULL,
  `RNA_DNA_Concentration_Unit` varchar(15) default NULL,
  `RNA_DNA_Integrity_Number` float default NULL,
  `Read_Error` enum('low concentration','low RNA Integrity Number') default NULL,
  `Read_Warning` enum('low concentration','low RNA Integrity Number') default NULL,
  `Sample_Comment` text,
  PRIMARY KEY  (`BioanalyzerRead_ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FK_Sample__ID` (`FK_Sample__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

