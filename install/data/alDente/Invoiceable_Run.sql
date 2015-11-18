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
-- Table structure for table `Invoiceable_Run`
--

DROP TABLE IF EXISTS `Invoiceable_Run`;
CREATE TABLE `Invoiceable_Run` (
  `Invoiceable_Run_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Source__ID` int(11) NOT NULL,
  `FK_Plate__ID` int(11) NOT NULL,
  `FK_Tray__ID` int(11) DEFAULT NULL,
  `FK_Run__ID` int(11) NOT NULL,
  `FK_Invoice_Run_Type__ID` int(11) NOT NULL,
  `FK_Invoice__ID` int(11) DEFAULT NULL,
  `FK_Work_Request__ID` int(11) DEFAULT NULL,
  `FKParent_Invoiceable_Run__ID` int(11) DEFAULT NULL,
  `Indexed` int(11) DEFAULT NULL,
  `Invoiceable_Run_Comments` text,
  `Billable` enum('Yes','No') NOT NULL DEFAULT 'Yes',
  PRIMARY KEY (`Invoiceable_Run_ID`),
  KEY `FK_Source__ID` (`FK_Source__ID`),
  KEY `FK_Plate__ID` (`FK_Plate__ID`),
  KEY `FK_Tray__ID` (`FK_Tray__ID`),
  KEY `FK_Run__ID` (`FK_Run__ID`),
  KEY `FK_Invoice_Run_Type__ID` (`FK_Invoice_Run_Type__ID`),
  KEY `FK_Invoice__ID` (`FK_Invoice__ID`),
  KEY `FK_Work_Request__ID` (`FK_Work_Request__ID`),
  KEY `FKParent_Invoiceable_Run__ID` (`FKParent_Invoiceable_Run__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

