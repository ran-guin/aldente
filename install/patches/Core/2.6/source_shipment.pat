## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
This patch will be used to enable tracking of source shipments if desired.

An additional optional field will be added to the Source table referencing the shipment table.
Shipment_Attributes may be added as well as a number of standard shipment fields.

This information should be either visible or readily accessible from the Source home page
Shipment reception will be handled in a specific run mode in a set of Shipment plugin modules.

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Source ADD FK_Shipment__ID INT;

CREATE TABLE `Shipment` (
  `Shipment_ID` int(11) NOT NULL auto_increment,
  `Shipment_Sent` datetime NOT NULL default '0000-00-00 00:00:00',
  `Shipment_Received` datetime NOT NULL default '0000-00-00 00:00:00',
  `FKSupplier_Organization__ID` int(11) NOT NULL default '0',
  `Shipping_Container` enum('Bag','Cryoport','Styrofoam Box') default NULL,
  `FKRecipient_Employee__ID` int(11) NOT NULL default '0',
  `Waybill_Number` varchar(255) default NULL,
  `Shipping_Conditions` enum('Ambient Temperature','Cooled','Frozen') default NULL,
  `Package_Conditions` enum('refrigerated - on ice','refrigerated - wet ice','refrigerated - cold water','refrigerated - warm water','room temp - cool','room temp - ok','room temp - warm','frozen - sufficient dry ice','frozen - cryoport temp ok','frozen - little dry ice','frozen - no dry ice') default NULL,
  `Shipment_Comments` text,
  `Sent_at_Temp` int(11) default NULL,
  `Received_at_Temp` int(11) default NULL,
  `Container_Status` enum('Locked','Unlocked') default NULL,
  `Shipment_Reference` varchar(255) NOT NULL default '',
  `Shipment_Status` enum('Sent','Received','Lost','Exported') default NULL,
  `Shipment_Type` enum('Internal','Import','Export') default NULL,
  `FKFrom_Grp__ID` int(11) default NULL,
  `FKTarget_Grp__ID` int(11) default NULL,
  `FKSender_Employee__ID` int(11) default NULL,
  `FK_Contact__ID` int(11) default NULL,
  `FKTransport_Rack__ID` int(11) default NULL,
  `FKFrom_Site__ID` int(11) default NULL,
  `FKTarget_Site__ID` int(11) default NULL,
  `Addressee` varchar(255) default NULL,
  PRIMARY KEY  (`Shipment_ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1; 

ALTER TABLE Attribute MODIFY Attribute_Type VARCHAR(255);

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## To report an error from this block (so that it can be picked up in SDB::Installation), print "error";
## Name the block of code below
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

UPDATE DBField SET Field_Options = 'Mandatory' WHERE Field_Table = 'Shipment' AND Field_Name IN ('Shipping_Conditions','Shipping_Container');
UPDATE DBField SET Field_Options = 'Mandatory,NewLink' WHERE Field_Table = 'Shipment' AND Field_Name IN ('FKSupplier_Organization__ID');
UPDATE DBField SET Field_Default = '<NOW>' WHERE Field_Table = 'Shipment' and Field_Name IN ('Shipment_Received');
UPDATE DBField SET Field_Default = '<USER>' WHERE Field_Table = 'Shipment' and Field_Name IN ('FKRecipient_Employee__ID');
UPDATE DBField SET List_Condition = "Organization_Type = 'Sample Supplier'" WHERE Field_Name = 'FKSupplier_Organization__ID' AND Field_Table = 'Shipment';

</FINAL>
