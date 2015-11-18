<SCHEMA>
-- MySQL dump 10.9
--
-- Host: lims01    Database: sequence
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
-- Table structure for table `Vendor`
--

##DROP TABLE IF EXISTS `Vendor`;
CREATE TABLE `Vendor` (
  `VenID` int(11) NOT NULL auto_increment,
  `VendorID` int(11) default NULL,
  `VendorName` varchar(80) default NULL,
  `AcctNum` varchar(80) default NULL,
  `OrgPhone` int(40) default NULL,
  `Active` varchar(40) default NULL,
  `Created` varchar(40) default NULL,
  `Creator` varchar(40) default NULL,
  `updated` varchar(40) default NULL,
  `updator` varchar(40) default NULL,
  `ConcurrencyID` int(20) default NULL,
  `org_name` varchar(255) default NULL,
  PRIMARY KEY  (`VenID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;


</SCHEMA>
