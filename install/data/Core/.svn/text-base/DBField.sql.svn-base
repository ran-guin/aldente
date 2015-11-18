-- MySQL dump 10.9
--
-- Host: limsdev04    Database: skeleton
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
-- Table structure for table `DBField`
--

DROP TABLE IF EXISTS `DBField`;
CREATE TABLE `DBField` (
  `DBField_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Field_Description` text NOT NULL,
  `Field_Table` text NOT NULL,
  `Prompt` varchar(255) NOT NULL DEFAULT '',
  `Field_Alias` varchar(255) NOT NULL DEFAULT '',
  `Field_Options` set('Hidden','Mandatory','Primary','Unique','NewLink','ViewLink','ListLink','Searchable','Obsolete','ReadOnly','Required','Removed') DEFAULT NULL,
  `Field_Reference` varchar(255) NOT NULL DEFAULT '',
  `Field_Order` int(11) NOT NULL DEFAULT '0',
  `Field_Name` varchar(255) NOT NULL DEFAULT '',
  `Field_Type` text NOT NULL,
  `Field_Index` varchar(255) NOT NULL DEFAULT '',
  `NULL_ok` enum('NO','YES') NOT NULL DEFAULT 'YES',
  `Field_Default` varchar(255) NOT NULL DEFAULT '',
  `Field_Size` tinyint(4) DEFAULT '20',
  `Field_Format` varchar(80) DEFAULT NULL,
  `FK_DBTable__ID` int(11) DEFAULT NULL,
  `Foreign_Key` varchar(255) DEFAULT NULL,
  `DBField_Notes` text,
  `Editable` enum('yes','admin','no') DEFAULT 'yes',
  `Tracked` enum('yes','no') DEFAULT 'no',
  `Field_Scope` enum('Core','Optional','Custom') DEFAULT 'Custom',
  `FK_Package__ID` int(11) DEFAULT NULL,
  `List_Condition` varchar(255) DEFAULT NULL,
  `FKParent_DBField__ID` int(11) DEFAULT NULL,
  `Parent_Value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`DBField_ID`),
  UNIQUE KEY `tblfld` (`FK_DBTable__ID`,`Field_Name`),
  UNIQUE KEY `field_name` (`Field_Name`,`FK_DBTable__ID`),
  KEY `fld` (`Field_Name`),
  KEY `package` (`FK_Package__ID`),
  KEY `Parent_DBField` (`FKParent_DBField__ID`)
) ENGINE=InnoDB AUTO_INCREMENT=4929 DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

