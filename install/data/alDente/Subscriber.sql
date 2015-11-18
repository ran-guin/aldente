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
-- Table structure for table `Subscriber`
--

DROP TABLE IF EXISTS `Subscriber`;
CREATE TABLE `Subscriber` (
  `Subscriber_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Subscription__ID` int(11) NOT NULL DEFAULT '0',
  `Subscriber_Type` enum('Employee','Grp','Contact','ExternalEmail') NOT NULL DEFAULT 'Employee',
  `FK_Employee__ID` int(11) DEFAULT NULL,
  `FK_Grp__ID` int(11) DEFAULT NULL,
  `FK_Contact__ID` int(11) DEFAULT NULL,
  `External_Email` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`Subscriber_ID`),
  KEY `FK_Subscription__ID` (`FK_Subscription__ID`),
  KEY `FK_Employee__ID` (`FK_Employee__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
