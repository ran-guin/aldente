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
-- Table structure for table `Standard_Solution`
--

DROP TABLE IF EXISTS `Standard_Solution`;
CREATE TABLE `Standard_Solution` (
  `Standard_Solution_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Standard_Solution_Name` varchar(40) DEFAULT NULL,
  `Standard_Solution_Parameters` int(11) DEFAULT NULL,
  `Standard_Solution_Formula` text,
  `Standard_Solution_Status` enum('Active','Inactive','Development') DEFAULT NULL,
  `Standard_Solution_Message` text,
  `Reagent_Parameter` varchar(40) DEFAULT NULL,
  `Label_Type` enum('Laser','ZPL') DEFAULT 'ZPL',
  `FK_Barcode_Label__ID` int(11) NOT NULL DEFAULT '0',
  `Prompt_Units` enum('','pl','ul','ml','l') DEFAULT '',
  PRIMARY KEY (`Standard_Solution_ID`),
  UNIQUE KEY `name` (`Standard_Solution_Name`),
  KEY `label` (`FK_Barcode_Label__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

