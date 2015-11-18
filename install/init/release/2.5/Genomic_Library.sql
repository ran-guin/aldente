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
-- Table structure for table `Genomic_Library`
--

DROP TABLE IF EXISTS `Genomic_Library`;
CREATE TABLE `Genomic_Library` (
  `Genomic_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `Vector_Type` enum('Unspecified','Plasmid','Fosmid','Cosmid','BAC') NOT NULL default 'Plasmid',
  `FKInsertSite_Enzyme__ID` int(11) default NULL,
  `Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `DNA_Shearing_Method` enum('Unspecified','Mechanical','Enzyme') NOT NULL default 'Unspecified',
  `FKDNAShearing_Enzyme__ID` int(11) default NULL,
  `DNA_Shearing_Enzyme` varchar(40) default NULL,
  `384_Well_Plates_To_Pick` int(11) NOT NULL default '0',
  `Genomic_Library_Type` enum('Shotgun','BAC','Fosmid') default NULL,
  `Genomic_Coverage` float(5,2) default NULL,
  `Recombinant_Clones` int(11) default NULL,
  `Non_Recombinant_Clones` int(11) default NULL,
  `Blue_White_Selection` enum('Yes','No') NOT NULL default 'No',
  PRIMARY KEY  (`Genomic_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

