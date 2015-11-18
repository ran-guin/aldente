-- MySQL dump 10.9
--
-- Host: limsdev02    Database: aldente_init
-- ------------------------------------------------------
-- Server version	4.1.20

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
  `DBField_ID` int(11) NOT NULL auto_increment,
  `Field_Description` text NOT NULL,
  `Field_Table` text NOT NULL,
  `Prompt` varchar(255) NOT NULL default '',
  `Field_Alias` varchar(255) NOT NULL default '',
  `Field_Options` set('Hidden','Mandatory','Primary','Unique','NewLink','ViewLink','ListLink','Searchable','Obsolete') default NULL,
  `Field_Reference` varchar(255) NOT NULL default '',
  `Field_Order` int(11) NOT NULL default '0',
  `Field_Name` varchar(255) NOT NULL default '',
  `Field_Type` text NOT NULL,
  `Field_Index` varchar(255) NOT NULL default '',
  `NULL_ok` enum('NO','YES') NOT NULL default 'YES',
  `Field_Default` varchar(255) NOT NULL default '',
  `Field_Size` tinyint(4) default '20',
  `Field_Format` varchar(80) default NULL,
  `FK_DBTable__ID` int(11) default NULL,
  `Foreign_Key` varchar(255) default NULL,
  `DBField_Notes` text,
  `Editable` enum('yes','no') default 'yes',
  `Tracked` enum('yes','no') default 'no',
  `Field_Scope` enum('Core','Optional','Custom') default 'Custom',
  PRIMARY KEY  (`DBField_ID`),
  UNIQUE KEY `tblfld` (`FK_DBTable__ID`,`Field_Name`),
  UNIQUE KEY `field_name` (`Field_Name`,`FK_DBTable__ID`),
  KEY `fld` (`Field_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

