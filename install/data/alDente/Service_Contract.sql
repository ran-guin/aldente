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
-- Table structure for table `Service_Contract`
--

DROP TABLE IF EXISTS `Service_Contract`;
CREATE TABLE `Service_Contract` (
  `Service_Contract_BeginDate` date DEFAULT NULL,
  `Service_Contract_ExpiryDate` date DEFAULT NULL,
  `FK_Organization__ID` int(11) DEFAULT NULL,
  `FK_Equipment__ID` int(11) DEFAULT NULL,
  `FK_Orders__ID` int(11) DEFAULT NULL,
  `Service_Contract_Number` int(11) DEFAULT NULL,
  `Service_Contract_Number_in_Batch` int(11) DEFAULT NULL,
  `Service_Contract_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Service_Contract_Status` enum('Pending','Current','Expired','Invalid') DEFAULT 'Pending',
  PRIMARY KEY (`Service_Contract_ID`),
  KEY `FK_Orders__ID` (`FK_Orders__ID`),
  KEY `FK_Organization__ID` (`FK_Organization__ID`),
  KEY `FK_Equipment__ID` (`FK_Equipment__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

