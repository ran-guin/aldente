-- MySQL dump 10.9
--
-- Host: limsdev04    Database: Core_Current
-- ------------------------------------------------------
-- Server version	5.5.10

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Maintenance`
--

DROP TABLE IF EXISTS `Maintenance`;
CREATE TABLE `Maintenance` (
  `Maintenance_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Equipment__ID` int(11) DEFAULT NULL,
  `Maintenance_Description` text NOT NULL,
  `Maintenance_DateTime` datetime DEFAULT NULL,
  `FK_Employee__ID` int(11) DEFAULT NULL,
  `FK_Contact__ID` int(11) DEFAULT NULL,
  `FK_Solution__ID` int(11) DEFAULT NULL,
  `Maintenance_Cost` float DEFAULT NULL,
  `Maintenance_Finished` datetime DEFAULT NULL,
  `FKMaintenance_Status__ID` int(11) DEFAULT '0',
  `FK_Maintenance_Process_Type__ID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`Maintenance_ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`),
  KEY `FK_Solution__ID` (`FK_Solution__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKMaintenance_Status__ID` (`FKMaintenance_Status__ID`),
  KEY `FK_Maintenance_Process_Type__ID` (`FK_Maintenance_Process_Type__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

