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
-- Table structure for table `Barcode_Label`
--

DROP TABLE IF EXISTS `Barcode_Label`;
CREATE TABLE `Barcode_Label` (
  `Barcode_Label_ID` int(11) NOT NULL auto_increment,
  `Barcode_Label_Name` char(40) default NULL,
  `Label_Height` float default NULL,
  `Label_Width` float default NULL,
  `Zero_X` int(11) default NULL,
  `Zero_Y` int(11) default NULL,
  `Top` int(11) default NULL,
  `FK_Setting__ID` int(11) NOT NULL default '0',
  `Label_Descriptive_Name` char(40) NOT NULL default '',
  `Barcode_Label_Type` enum('plate','mulplate','solution','equipment','source','employee','microarray') default NULL,
  `FK_Label_Format__ID` int(11) NOT NULL default '0',
  PRIMARY KEY  (`Barcode_Label_ID`),
  KEY `setting` (`FK_Setting__ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

