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
-- Table structure for table `Original_Source`
--

DROP TABLE IF EXISTS `Original_Source`;
CREATE TABLE `Original_Source` (
  `Original_Source_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Original_Source_Name` varchar(40) NOT NULL DEFAULT '',
  `Description` text,
  `FK_Contact__ID` int(11) DEFAULT NULL,
  `FKCreated_Employee__ID` int(11) DEFAULT NULL,
  `Defined_Date` date NOT NULL DEFAULT '0000-00-00',
  `Sample_Available` enum('Yes','No','Later') DEFAULT NULL,
  `FK_Pathology__ID` int(11) NOT NULL DEFAULT '0',
  `Pathology_Type` enum('Benign','Pre-malignant','Malignant','Non-neoplastic','Undetermined','Hyperplasia','Metaplasia','Dysplasia') DEFAULT NULL,
  `Pathology_Grade` set('G1','G2','G3','G4') DEFAULT NULL,
  `Pathology_Stage` enum('0','I','I-A','I-B','I-C','II','II-A','II-B','II-C','III','III-A','III-B','III-C','IV','>=pT2') DEFAULT NULL,
  `Invasive` enum('Invasive','Noninvasive') DEFAULT NULL,
  `FK_Strain__ID` int(11) DEFAULT NULL,
  `Pathology_Occurrence` enum('Primary','Reccurent-Relapse','Metastatic','Remission','Undetermined','Unspecified') NOT NULL DEFAULT 'Unspecified',
  PRIMARY KEY (`Original_Source_ID`),
  UNIQUE KEY `OS_Name` (`Original_Source_Name`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKCreated_Employee__ID` (`FKCreated_Employee__ID`),
  KEY `Pathology` (`FK_Pathology__ID`),
  KEY `Strain` (`FK_Strain__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

