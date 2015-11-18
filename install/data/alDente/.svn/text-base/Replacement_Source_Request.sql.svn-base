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
-- Table structure for table `Replacement_Source_Request`
--

DROP TABLE IF EXISTS `Replacement_Source_Request`;
CREATE TABLE `Replacement_Source_Request` (
  `Replacement_Source_Request_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Replacement_Source_Requested` date NOT NULL DEFAULT '0000-00-00',
  `Replacement_Source_Received` date DEFAULT NULL,
  `Replacement_Source_Status` enum('Requested','Received','Re-requested','Not Available') DEFAULT NULL,
  `FK_Source__ID` int(11) NOT NULL DEFAULT '0',
  `FKReplacement_Source__ID` int(11) DEFAULT NULL,
  `FK_Replacement_Source_Reason__ID` int(11) NOT NULL DEFAULT '0',
  `Replacement_Source_Request_Comments` text,
  PRIMARY KEY (`Replacement_Source_Request_ID`),
  KEY `Source` (`FK_Source__ID`),
  KEY `Replacement_Source` (`FKReplacement_Source__ID`),
  KEY `Replacement_Source_Reason` (`FK_Replacement_Source_Reason__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

