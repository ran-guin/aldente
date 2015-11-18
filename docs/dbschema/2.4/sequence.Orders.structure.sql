-- MySQL dump 9.10
--
-- Host: seqdb01    Database: sequence
-- ------------------------------------------------------
-- Server version	4.0.17-standard-log

--
-- Table structure for table `Orders`
--

DROP TABLE IF EXISTS `Orders`;
CREATE TABLE `Orders` (
  `Orders_ID` int(11) NOT NULL auto_increment,
  `Orders_Item` text,
  `Orders_Quantity` int(11) default NULL,
  `Item_Size` float default NULL,
  `Item_Units` enum('mL','litres','mg','grams','kg','pcs','boxes','tubes','n/a') default NULL,
  `Orders_Catalog_Number` text,
  `Orders_Lot_Number` text,
  `Unit_Cost` float default NULL,
  `Orders_Notes` text,
  `Orders_Req_Number` text,
  `Orders_PO_Number` text,
  `Quote_Number` text,
  `Orders_Received` int(11) NOT NULL default '0',
  `Orders_Status` enum('On Order','Received','Incomplete','Pending') default NULL,
  `PO_Date` date default NULL,
  `Orders_Quantity_Received` int(11) NOT NULL default '0',
  `Req_Date` date default NULL,
  `Orders_Cost` float(6,2) default NULL,
  `Taxes` float default NULL,
  `Freight_Costs` float default NULL,
  `Total_Ledger_Amount` float default NULL,
  `Ledger_Period` text,
  `Expense_Code` text,
  `Serial_Num` text,
  `FK_Funding__Code` text NOT NULL,
  `Expense_Type` enum('Reagents','Equip - C','Equip -M','Glass','Plastics','Kits','Service','Other') default NULL,
  `Item_Unit` enum('EA','CS','BX','PK','RL','HR') default NULL,
  `Req_Number` text,
  `PO_Number` text,
  `Warranty` text,
  `MSDS` enum('Yes','No','N/A') default NULL,
  `old_Expense` text,
  `old_Org_Name` text,
  `Orders_Received_Date` date default NULL,
  `Currency` enum('Can','US') default 'Can',
  `FK_Account__ID` int(11) default NULL,
  `FKVendor_Organization__ID` int(11) default NULL,
  `FKManufacturer_Organization__ID` int(11) default NULL,
  `Orders_Item_Description` text,
  PRIMARY KEY  (`Orders_ID`),
  KEY `FKManufacturer_Organization__ID` (`FKManufacturer_Organization__ID`),
  KEY `FKVendor_Organization__ID` (`FKVendor_Organization__ID`),
  KEY `FK_Account__ID` (`FK_Account__ID`)
) TYPE=InnoDB;

