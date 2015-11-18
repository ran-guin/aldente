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
-- Table structure for table `Work_Request`
--

DROP TABLE IF EXISTS `Work_Request`;
CREATE TABLE `Work_Request` (
  `Work_Request_ID` int(11) NOT NULL auto_increment,
  `Plate_Size` enum('96-well','384-well') NOT NULL default '96-well',
  `Plates_To_Seq` int(11) default '0',
  `Plates_To_Pick` int(11) default '0',
  `FK_Goal__ID` int(11) default NULL,
  `Goal_Target` int(11) default NULL,
  `Comments` text,
  `FK_Submission__ID` int(11) NOT NULL default '0',
  `Work_Request_Type` enum('1/16 End Reads','1/24 End Reads','1/256 End Reads','1/16 Custom Reads','1/24 Custom Reads','1/256 Custom Reads','DNA Preps','Bac End Reads','1/256 Submission QC','1/256 Transposon','1/256 Single Prep End Reads','1/16 Glycerol Rearray Custom Reads','Primer Plates Ready','1/48 End Reads','1/48 Custom Reads') default NULL,
  `Num_Plates_Submitted` int(11) NOT NULL default '0',
  `FK_Plate_Format__ID` int(11) NOT NULL default '0',
  `FK_Work_Request_Type__ID` int(11) default '0',
  `FK_Library__Name` varchar(40) NOT NULL default '',
  `Goal_Target_Type` enum('Add to Original Target','Included in Original Target') default NULL,
  PRIMARY KEY  (`Work_Request_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

