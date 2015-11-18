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
-- Table structure for table `Maintenance_Protocol`
--

DROP TABLE IF EXISTS `Maintenance_Protocol`;
CREATE TABLE `Maintenance_Protocol` (
  `Maintenance_Protocol_ID` int(11) NOT NULL auto_increment,
  `FK_Service__Name` varchar(40) default NULL,
  `Step` int(11) default NULL,
  `Maintenance_Step_Name` varchar(40) default NULL,
  `Maintenance_Instructions` text,
  `FK_Employee__ID` int(11) default NULL,
  `Protocol_Date` date default '0000-00-00',
  `Maintenance_Protocol_Name` text,
  `FK_Contact__ID` int(11) default NULL,
  PRIMARY KEY  (`Maintenance_Protocol_ID`),
  UNIQUE KEY `step` (`FK_Service__Name`,`Step`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

