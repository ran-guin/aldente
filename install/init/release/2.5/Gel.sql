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
-- Table structure for table `Gel`
--

DROP TABLE IF EXISTS `Gel`;
CREATE TABLE `Gel` (
  `Gel_ID` int(10) unsigned NOT NULL auto_increment,
  `FK_Plate__ID` int(11) NOT NULL default '0',
  `Gel_Date` datetime NOT NULL default '0000-00-00 00:00:00',
  `FK_Employee__ID` int(4) default NULL,
  `Gel_Directory` varchar(80) NOT NULL default '',
  `Status` enum('Active','Failed','On_hold','lane tracking','run bandleader','bandleader completed','bandleader failure','finished','sizes imported','size importing failure') default 'Active',
  `Gel_Comments` text,
  `Bandleader_Version` varchar(40) default '2.3.5',
  `Agarose_Percent` float(10,2) default '1.20',
  `File_Extension_Type` enum('sizes','none') default 'none',
  PRIMARY KEY  (`Gel_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

