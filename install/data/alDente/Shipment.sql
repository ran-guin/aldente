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
-- Table structure for table `Shipment`
--

DROP TABLE IF EXISTS `Shipment`;
CREATE TABLE `Shipment` (
  `Shipment_ID` int(11) NOT NULL AUTO_INCREMENT,
  `Shipment_Sent` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Shipment_Received` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `FKSupplier_Organization__ID` int(11) NOT NULL DEFAULT '0',
  `Shipping_Container` enum('Bag','Cryoport','Styrofoam Box') DEFAULT NULL,
  `FKRecipient_Employee__ID` int(11) NOT NULL DEFAULT '0',
  `Waybill_Number` varchar(255) DEFAULT NULL,
  `Shipping_Conditions` enum('Ambient Temperature','Cooled','Frozen') DEFAULT NULL,
  `Package_Conditions` enum('refrigerated - on ice','refrigerated - wet ice','refrigerated - cold water','refrigerated - warm water','room temp - cool','room temp - ok','room temp - warm','frozen - sufficient dry ice','frozen - cryoport temp ok','frozen - little dry ice','frozen - no dry ice') DEFAULT NULL,
  `Shipment_Comments` text,
  `Sent_at_Temp` int(11) DEFAULT NULL,
  `Received_at_Temp` int(11) DEFAULT NULL,
  `Container_Status` enum('Locked','Unlocked') DEFAULT NULL,
  `Shipment_Reference` varchar(255) NOT NULL DEFAULT '',
  `Shipment_Status` enum('Sent','Received','Lost','Exported') DEFAULT NULL,
  `Shipment_Type` enum('Internal','Import','Export','Roundtrip') DEFAULT NULL,
  `FKFrom_Grp__ID` int(11) DEFAULT NULL,
  `FKTarget_Grp__ID` int(11) DEFAULT NULL,
  `FKSender_Employee__ID` int(11) DEFAULT NULL,
  `FK_Contact__ID` int(11) DEFAULT NULL,
  `FKTransport_Rack__ID` int(11) DEFAULT NULL,
  `FKFrom_Site__ID` int(11) DEFAULT NULL,
  `FKTarget_Site__ID` int(11) DEFAULT NULL,
  `Addressee` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`Shipment_ID`),
  KEY `Supplier_Organization` (`FKSupplier_Organization__ID`),
  KEY `Recipient_Employee` (`FKRecipient_Employee__ID`),
  KEY `From_Grp` (`FKFrom_Grp__ID`),
  KEY `Target_Grp` (`FKTarget_Grp__ID`),
  KEY `Sender_Employee` (`FKSender_Employee__ID`),
  KEY `Contact` (`FK_Contact__ID`),
  KEY `Transport_Rack` (`FKTransport_Rack__ID`),
  KEY `From_Site` (`FKFrom_Site__ID`),
  KEY `Target_Site` (`FKTarget_Site__ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

