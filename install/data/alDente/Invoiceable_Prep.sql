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
-- Table structure for table `Invoiceable_Prep`
--

DROP TABLE IF EXISTS `Invoiceable_Prep`;
CREATE TABLE `Invoiceable_Prep` (
  `Invoiceable_Prep_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Source__ID` int(11) NOT NULL,
  `FK_Plate__ID` int(11) NOT NULL,
  `FK_Tray__ID` int(11) DEFAULT NULL,
  `FK_Prep__ID` int(11) NOT NULL,
  `FK_Invoice_Protocol__ID` int(11) NOT NULL,
  `FK_Invoice__ID` int(11) DEFAULT NULL,
  `FK_Work_Request__ID` int(11) DEFAULT NULL,
  `FKParent_Invoiceable_Prep__ID` int(11) DEFAULT NULL,
  `Indexed` int(11) DEFAULT NULL,
  `Invoiceable_Prep_Comments` text,
  `Billable` enum('Yes','No') NOT NULL DEFAULT 'Yes',
  PRIMARY KEY (`Invoiceable_Prep_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`),
  KEY `FK_Tray__ID` (`FK_Tray__ID`),
  KEY `FK_Prep__ID` (`FK_Prep__ID`),
  KEY `FK_Invoice_Protocol__ID` (`FK_Invoice_Protocol__ID`),
  KEY `FK_Invoice__ID` (`FK_Invoice__ID`),
  KEY `FK_Work_Request__ID` (`FK_Work_Request__ID`),
  KEY `FKParent_Invoiceable_Prep__ID` (`FKParent_Invoiceable_Prep__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

