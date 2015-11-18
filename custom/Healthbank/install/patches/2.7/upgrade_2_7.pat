## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

UPDATE Protocol_Step set Protocol_Step_Name = Replace(Protocol_Step_Name,'to cryovial','to 2 ml cryovial') where Protocol_Step_Name like '%to cryovial';

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

update DBField set Field_Reference = "Concat(Sample_Type.Sample_Type,'-',External_Identifier)" WHERE Field_Name = 'Source_ID';
update DBField set Field_Options = 'Required' WHERE Field_Table = 'Shipment' and Field_Name like 'Package_Conditions';
update DBField set Field_Options = 'Required' WHERE Field_Table = 'Shipment' and Field_Name like 'Waybill_Number';




</FINAL>
