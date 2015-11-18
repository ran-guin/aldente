## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

insert into Department values ('','BioSpecimens','Active');
insert into Grp values ('','BioSpecimens Core',14,'Admin','','Active');
INSERT INTO Attribute (Attribute_Name, Attribute_Type, FK_Grp__ID, Inherited, Attribute_Class) select 'Target_Concentration','Decimal',Grp_ID, 'Yes','Source' from Grp where Grp_Name like 'BioSpecimens Core';
INSERT INTO Attribute (Attribute_Name, Attribute_Type, FK_Grp__ID, Inherited, Attribute_Class) select 'BioSpecimen_Barcode','VARCHAR(40)', Grp_ID, 'Yes','Source' from Grp where Grp_Name like 'BioSpecimens Core';

UPDATE Organization SET Organization_Type = Concat(Organization_Type,',','Sample Supplier') WHERE Organization_Name IN ('BCCA');


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

UPDATE DBField set Field_Options = 'Mandatory' where Field_Name in ('Container_Status','Sent_at_Temp','Received_at_Temp','Shipment_Reference') AND Field_Table = 'Shipment';

UPDATE DBField set Field_Options = 'Hidden' where Field_Name IN ('Shipping_Conditions','Package_Conditions');

</FINAL>
