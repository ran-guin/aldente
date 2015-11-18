-- MySQL dump 10.9
--
-- Host: lims02    Database: sequence
-- ------------------------------------------------------
-- Server version	4.1.20-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Plate_Format`
--

DROP TABLE IF EXISTS `Plate_Format`;
CREATE TABLE `Plate_Format` (
  `Plate_Format_ID` int(11) NOT NULL auto_increment,
  `Plate_Format_Type` char(40) default NULL,
  `Plate_Format_Size` enum('1-well','8-well','96-well','384-well','1.5 ml','50 ml','15 ml','5 ml','2 ml','0.5 ml','0.2 ml') default NULL,
  `Plate_Format_Status` enum('Active','Inactive') default NULL,
  `FK_Barcode_Label__ID` int(11) default NULL,
  `Max_Row` char(2) default NULL,
  `Max_Col` tinyint(4) default NULL,
  `Plate_Format_Style` enum('Plate','Tube','Array','Gel') default NULL,
  `Capacity` char(4) default NULL,
  `Capacity_Units` char(4) default NULL,
  `Wells` smallint(6) NOT NULL default '1',
  `Well_Lookup_Key` enum('Plate_384','Plate_96','Gel_121_Standard','Gel_121_Custom','Tube') default NULL,
  PRIMARY KEY  (`Plate_Format_ID`),
  UNIQUE KEY `name` (`Plate_Format_Type`,`Plate_Format_Size`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

