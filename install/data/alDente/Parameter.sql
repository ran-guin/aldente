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
-- Table structure for table `Parameter`
--

DROP TABLE IF EXISTS `Parameter`;
CREATE TABLE `Parameter` (
  `FK_Standard_Solution__ID` int(11) DEFAULT NULL,
  `Parameter_Name` varchar(40) DEFAULT NULL,
  `Parameter_Description` text,
  `Parameter_Value` varchar(40) DEFAULT NULL,
  `Parameter_Type` enum('Static','Multiple','User_Define','Hidden') DEFAULT NULL,
  `Parameter_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Parameter_Format` text,
  `Parameter_Units` enum('ml','ul','ng','mg','ug','g','l','ng/uL','umoles','nmoles','pmoles') DEFAULT NULL,
  `Parameter_SType` enum('Reagent','Solution','Primer','Buffer','Matrix') DEFAULT NULL,
  `Parameter_Prompt` varchar(30) NOT NULL DEFAULT '',
  PRIMARY KEY (`Parameter_ID`),
  UNIQUE KEY `FK_Standard_Solution__ID` (`FK_Standard_Solution__ID`,`Parameter_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

