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
-- Table structure for table `Library`
--

DROP TABLE IF EXISTS `Library`;
CREATE TABLE `Library` (
  `Library_Source_Name` text,
  `Library_Type` enum('Vector_Based','RNA/DNA','PCR_Product') DEFAULT NULL,
  `Library_Obtained_Date` date NOT NULL DEFAULT '0000-00-00',
  `Library_Source` text,
  `Library_Name` varchar(40) NOT NULL DEFAULT '',
  `External_Library_Name` text NOT NULL,
  `Library_Description` text,
  `FK_Project__ID` int(11) DEFAULT NULL,
  `Library_Notes` text,
  `Library_FullName` varchar(80) DEFAULT NULL,
  `FKParent_Library__Name` varchar(40) DEFAULT NULL,
  `Library_Goals` text,
  `Library_Status` enum('Submitted','On Hold','In Production','Complete','Cancelled','Contaminated','Failed') DEFAULT 'Submitted',
  `FK_Contact__ID` int(11) DEFAULT NULL,
  `FKCreated_Employee__ID` int(11) DEFAULT NULL,
  `FK_Grp__ID` int(11) NOT NULL DEFAULT '0',
  `FK_Original_Source__ID` int(11) NOT NULL DEFAULT '0',
  `Library_URL` text,
  `Starting_Plate_Number` smallint(6) NOT NULL DEFAULT '1',
  `Source_In_House` enum('Yes','No') NOT NULL DEFAULT 'Yes',
  `Requested_Completion_Date` date DEFAULT NULL,
  `FKConstructed_Contact__ID` int(11) DEFAULT '0',
  `Library_Completion_Date` date DEFAULT NULL,
  PRIMARY KEY (`Library_Name`),
  KEY `proj` (`FK_Project__ID`),
  KEY `FK_Contact__ID` (`FK_Contact__ID`),
  KEY `FKParent_Library__Name` (`FKParent_Library__Name`),
  KEY `FKCreated_Employee__ID` (`FKCreated_Employee__ID`),
  KEY `FK_Grp__ID` (`FK_Grp__ID`),
  KEY `FK_Original_Source__ID` (`FK_Original_Source__ID`),
  KEY `FKConstructed_Contact__ID` (`FKConstructed_Contact__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

