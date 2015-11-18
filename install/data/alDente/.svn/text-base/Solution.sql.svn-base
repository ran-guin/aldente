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
-- Table structure for table `Solution`
--

DROP TABLE IF EXISTS `Solution`;
CREATE TABLE `Solution` (
  `Solution_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Solution_Started` datetime DEFAULT NULL,
  `Solution_Quantity` float DEFAULT NULL,
  `Solution_Expiry` date DEFAULT NULL,
  `Quantity_Used` float DEFAULT '0',
  `FK_Rack__ID` int(11) DEFAULT NULL,
  `Solution_Finished` date DEFAULT NULL,
  `Solution_Type` enum('Reagent','Solution','Primer','Buffer','Matrix') DEFAULT NULL,
  `Solution_Status` enum('Unopened','Open','Finished','Temporary','Expired') DEFAULT 'Unopened',
  `FK_Stock__ID` int(11) DEFAULT NULL,
  `FK_Solution_Info__ID` int(11) DEFAULT NULL,
  `Solution_Number` int(11) DEFAULT NULL,
  `Solution_Number_in_Batch` int(11) DEFAULT NULL,
  `Solution_Notes` text,
  `QC_Status` enum('N/A','Pending','Failed','Re-Test','Passed') DEFAULT 'N/A',
  `Solution_Label` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`Solution_ID`),
  KEY `stock` (`FK_Stock__ID`),
  KEY `FK_Solution_Info__ID` (`FK_Solution_Info__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `label` (`Solution_Label`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

