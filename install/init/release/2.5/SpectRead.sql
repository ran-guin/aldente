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
-- Table structure for table `SpectRead`
--

DROP TABLE IF EXISTS `SpectRead`;
CREATE TABLE `SpectRead` (
  `SpectRead_ID` int(11) NOT NULL auto_increment,
  `FK_Run__ID` int(11) NOT NULL default '0',
  `FK_Sample__ID` int(11) NOT NULL default '0',
  `Well` char(3) default NULL,
  `Well_Status` enum('OK','Empty','Unused','Problematic','Ignored') default NULL,
  `Well_Category` enum('Sample','Blank','ssDNA','hgDNA') default NULL,
  `A260m` float(4,3) default NULL,
  `A260cor` float(4,3) default NULL,
  `A280m` float(4,3) default NULL,
  `A280cor` float(4,3) default NULL,
  `A260` float(4,3) default NULL,
  `A280` float(4,3) default NULL,
  `A260_A280_ratio` float(4,3) default NULL,
  `Dilution_Factor` float(4,3) default NULL,
  `Concentration` float default NULL,
  `Unit` varchar(15) default NULL,
  `Read_Error` enum('low concentration','low A260cor/A280cor ratio','A260m below 0.100','SS DNA concentration out of range','human gDNA concentration out of range') default NULL,
  `Read_Warning` enum('low A260cor/A280cor ratio','SS DNA concentration out of range','human gDNA concentration out of range') default NULL,
  PRIMARY KEY  (`SpectRead_ID`),
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

