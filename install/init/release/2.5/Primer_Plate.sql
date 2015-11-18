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
-- Table structure for table `Primer_Plate`
--

DROP TABLE IF EXISTS `Primer_Plate`;
CREATE TABLE `Primer_Plate` (
  `Primer_Plate_ID` int(11) NOT NULL auto_increment,
  `Primer_Plate_Name` text,
  `Order_DateTime` datetime default NULL,
  `Arrival_DateTime` datetime default NULL,
  `Primer_Plate_Status` enum('To Order','Ordered','Received','Inactive') default NULL,
  `FK_Solution__ID` int(11) default NULL,
  `Notes` varchar(40) default NULL,
  `Notify_List` text,
  `FK_Lab_Request__ID` int(11) default NULL,
  PRIMARY KEY  (`Primer_Plate_ID`),
  KEY `primerplate_arrival` (`Arrival_DateTime`),
  KEY `primerplate_status` (`Primer_Plate_Status`),
  KEY `primerplate_name` (`Primer_Plate_Name`(40)),
  KEY `FK_Solution__ID` (`FK_Solution__ID`),
  KEY `FK_Lab_Request__ID` (`FK_Lab_Request__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

