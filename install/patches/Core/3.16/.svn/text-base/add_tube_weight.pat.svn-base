## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Plate_Format ADD COLUMN Empty_Container_Weight_in_g FLOAT DEFAULT NULL;
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
insert into Attribute (Attribute_Name, Attribute_Type, FK_Grp__ID, Inherited, Attribute_Class, Attribute_Access, Attribute_Description) values ('Measured_Tube_Weight_in_g', 'Decimal', 23, 'no', 'Plate', 'Editable', "This attribute can be used to calculate accurate volumes. If this attribute is entered and Plate_Format.Wells = 1 and Container Format has defined Empty_Container_Weight_g, the following calculation will be performed: 1. Subtract empty tube weight from entered (measured) weight. 2. convert grams to ml (assuming water density)" ); 
</DATA>

<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below

</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
