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
-- Table structure for table `Source`
--

DROP TABLE IF EXISTS `Source`;
CREATE TABLE `Source` (
  `Source_ID` int(11) NOT NULL auto_increment,
  `FKParent_Source__ID` int(11) default NULL,
  `External_Identifier` varchar(40) NOT NULL default '',
  `Source_Type` enum('Library_Segment','RNA_DNA_Source','ReArray_Plate','Ligation','Microtiter','Xformed_Cells','Sorted_Cell','Tissue_Sample','External','Cells') default NULL,
  `Source_Status` enum('Active','Reserved','Inactive','Thrown Out') default NULL,
  `Label` varchar(40) default NULL,
  `FK_Original_Source__ID` int(11) default NULL,
  `Received_Date` date NOT NULL default '0000-00-00',
  `Current_Amount` float default NULL,
  `Original_Amount` float default NULL,
  `Amount_Units` enum('','ul','ml','ul/well','mg','ug','ng','pg','Cells','Embryos','Litters','Organs','Animals','Million Cells') default NULL,
  `FKReceived_Employee__ID` int(11) default NULL,
  `FK_Rack__ID` int(11) NOT NULL default '0',
  `Source_Number` varchar(40) default NULL,
  `FK_Barcode_Label__ID` int(11) NOT NULL default '0',
  `Notes` text,
  `FKSource_Plate__ID` int(11) default NULL,
  `FK_Plate_Format__ID` int(11) default NULL,
  PRIMARY KEY  (`Source_ID`),
  KEY `FK_Original_Source__ID` (`FK_Original_Source__ID`),
  KEY `FK_Rack__ID` (`FK_Rack__ID`),
  KEY `FKReceived_Employee__ID` (`FKReceived_Employee__ID`),
  KEY `FK_Barcode_Label__ID` (`FK_Barcode_Label__ID`),
  KEY `FKParent_Source__ID` (`FKParent_Source__ID`),
  KEY `label` (`Label`),
  KEY `number` (`Source_Type`,`Source_Number`),
  KEY `id` (`External_Identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

