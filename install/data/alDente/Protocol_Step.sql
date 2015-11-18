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
-- Table structure for table `Protocol_Step`
--

DROP TABLE IF EXISTS `Protocol_Step`;
CREATE TABLE `Protocol_Step` (
  `Protocol_Step_Number` int(11) DEFAULT NULL,
  `Protocol_Step_Name` varchar(80) NOT NULL DEFAULT '',
  `Protocol_Step_Instructions` text,
  `Protocol_Step_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Protocol_Step_Defaults` text,
  `Input` text,
  `Scanner` tinyint(3) unsigned DEFAULT '1',
  `Protocol_Step_Message` varchar(40) DEFAULT NULL,
  `FK_Employee__ID` int(11) DEFAULT NULL,
  `Protocol_Step_Changed` date DEFAULT NULL,
  `Input_Format` text NOT NULL,
  `FK_Lab_Protocol__ID` int(11) DEFAULT NULL,
  `FKQC_Attribute__ID` int(11) DEFAULT NULL,
  `QC_Condition` varchar(40) DEFAULT NULL,
  `Validate` enum('Primer','Enzyme','Antibiotic') DEFAULT NULL,
  `Repeatable` enum('Yes','No','') DEFAULT '',
  PRIMARY KEY (`Protocol_Step_ID`),
  UNIQUE KEY `naming` (`Protocol_Step_Name`,`FK_Lab_Protocol__ID`),
  KEY `prot` (`FK_Lab_Protocol__ID`),
  KEY `employee_id` (`FK_Employee__ID`),
  KEY `FKQC_Attribute__ID` (`FKQC_Attribute__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

