## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Shipment ADD FKOriginal_Shipment__ID int(11) DEFAULT NULL;
</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

UPDATE DBField set Tracked = 'yes' , Editable = 'no' , Field_Options= 'ReadOnly' WHERE Field_Table = 'Shipment' and Field_Name = 'FKOriginal_Shipment__ID';

update DBField set Field_Order = 5  WHERE Field_Table = 'Shipment' and Field_Name = 'FK_Transport_Container__ID';

</FINAL>
