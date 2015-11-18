## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
This patch expands the shipment tracking to enable more detailed tracking of internal shipments 

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Shipment 
ADD Shipment_Status ENUM('Sent','Received','Lost','Exported'),
ADD Shipment_Type ENUM('Internal','Import','Export'),
ADD Shipment_Sent DateTime,
ADD FKFrom_Grp__ID INT,
ADD FKTarget_Grp__ID INT,
ADD FKSender_Employee__ID INT,
ADD FK_Contact__ID INT,
ADD FKTransport_Rack__ID INT,
ADD FKFrom_Site__ID INT,
ADD FKTarget_Site__ID INT,
ADD Addressee VARCHAR(255);

alter table Shipment ADD Shipment_Sent datetime default '0000-00-00 00:00:00' NOT NULL;
 
 
CREATE TABLE Shipped_Object (
Shipped_Object_ID INT NOT NULL Auto_Increment Primary Key,
FK_Shipment__ID INT NOT NULL,
FK_Object_Class__ID INT NOT NULL,
Object_ID INT NOT NULL
);

ALTER TABLE Equipment MODIFY Equipment_Status enum('In Use','Inactive - Removed','Inactive - In Repair','Inactive - Hold','Sold','Unknown','Returned to Vendor (RTV)','In Transit'); 

ALTER TABLE Shipment ADD Sent_at_Temp INT;
ALTER TABLE Shipment ADD Received_at_Temp INT;
ALTER Table Shipment ADD Container_Status ENUM('Locked','Unlocked');
ALTER Table Shipment ADD Shipment_Reference VARCHAR(255);

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

UPDATE DBField set Field_Default = '<NOW>' where Field_name = 'Shipment_Received';
UPDATE DBField set Field_Description = 'Enter Temperature in Celsius' where Field_Name like '%_at_Temp';

</FINAL>
