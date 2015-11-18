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
-- Table structure for table `Funding`
--

DROP TABLE IF EXISTS `Funding`;
CREATE TABLE `Funding` (
  `Funding_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Funding_Status` enum('Applied for','Pending','Received','Terminated') DEFAULT 'Received',
  `Funding_Name` varchar(80) NOT NULL DEFAULT '',
  `Funding_Conditions` text NOT NULL,
  `Funding_Code` varchar(20) DEFAULT NULL,
  `Funding_Description` text NOT NULL,
  `Funding_Source` enum('Internal','External') NOT NULL DEFAULT 'Internal',
  `ApplicationDate` date DEFAULT NULL,
  `FKContact_Employee__ID` int(11) DEFAULT NULL,
  `FKSource_Organization__ID` int(11) DEFAULT NULL,
  `AppliedFor` int(11) DEFAULT NULL,
  `Duration` text,
  `Funding_Type` enum('New','Renewal') DEFAULT NULL,
  `Currency` enum('US','Canadian') DEFAULT 'Canadian',
  `ExchangeRate` float DEFAULT NULL,
  `FK_Queue__ID` int(11) DEFAULT '1',
  PRIMARY KEY (`Funding_ID`),
  UNIQUE KEY `name` (`Funding_Name`),
  UNIQUE KEY `code` (`Funding_Code`),
  KEY `FKSource_Organization__ID` (`FKSource_Organization__ID`),
  KEY `FKContact_Employee__ID` (`FKContact_Employee__ID`),
  KEY `queue` (`FK_Queue__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

