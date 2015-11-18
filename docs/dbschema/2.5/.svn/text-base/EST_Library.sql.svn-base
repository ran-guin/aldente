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
-- Table structure for table `EST_Library`
--

DROP TABLE IF EXISTS `EST_Library`;
CREATE TABLE `EST_Library` (
  `EST_Library_ID` int(11) NOT NULL auto_increment,
  `FK_Sequencing_Library__ID` int(11) NOT NULL default '0',
  `5Prime_Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `3Prime_Insert_Site_Enzyme` varchar(40) NOT NULL default '',
  `Blue_White_Selection` enum('Yes','No') NOT NULL default 'No',
  `Enriched_For_Full_Length` enum('Yes','No') NOT NULL default 'Yes',
  `Construction_Correction` enum('','Normalized','Subtracted') NOT NULL default '',
  `FK3PrimeInsert_Restriction_Site__ID` int(11) default NULL,
  `FK5PrimeInsert_Restriction_Site__ID` int(11) default NULL,
  PRIMARY KEY  (`EST_Library_ID`),
  KEY `lib_id` (`FK_Sequencing_Library__ID`),
  KEY `FK3PrimeInsert_Restriction_Site__ID` (`FK3PrimeInsert_Restriction_Site__ID`),
  KEY `FK5PrimeInsert_Restriction_Site__ID` (`FK5PrimeInsert_Restriction_Site__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

