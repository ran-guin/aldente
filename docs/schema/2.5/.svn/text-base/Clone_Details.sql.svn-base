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
-- Table structure for table `Clone_Details`
--

DROP TABLE IF EXISTS `Clone_Details`;
CREATE TABLE `Clone_Details` (
  `Clone_Details_ID` int(11) NOT NULL auto_increment,
  `FK_Clone_Sample__ID` int(11) NOT NULL default '0',
  `Clone_Comments` text,
  `PolyA_Tail` int(11) default NULL,
  `Chimerism_check_with_ESTs` enum('no','yes','warning','single EST match') default NULL,
  `Score` int(11) default NULL,
  `5Prime_found` tinyint(4) default NULL,
  `Genes_Protein` text,
  `Incyte_Match` int(11) default NULL,
  `PolyA_Signal` int(11) default NULL,
  `Clone_Vector` text,
  `Genbank_ID` text,
  `Lukas_Passed` int(11) default NULL,
  `Size_Estimate` int(11) default NULL,
  `Size_StdDev` int(11) default NULL,
  PRIMARY KEY  (`Clone_Details_ID`),
  UNIQUE KEY `clone` (`FK_Clone_Sample__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

