## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
## Attribute Trigger to prevent duplicate Attribute_Name and Field_Name
INSERT into Trigger (Table_Name, Trigger_Type, Value, Trigger_On, Status, Trigger_Description, Fatal) Values ('Attribute','Method','validate_attribute_name_trigger','insert','Active','Not allowing Attribute_Name and Field_Name in tables to be the same','Yes');

## Format check for Attribute_Name to make sure it is all words
update DBField set Field_Format = "^\\\w{0,40}$" where Field_Table = 'Attribute' and Field_Name = 'Attribute_Name';

## Adding Error_Check for attribute name and field name
insert into Error_Check (Username, Table_Name, Field_Name, Command_Type, Command_String, Notice_Frequency, Comments, Description) Values ('dcheng', 'Attribute,DBField','Attribute_ID,Attribute_Name,Field_Table,Field_Name','FullSQL',"select Attribute_ID,Attribute_Name,Field_Table,Field_Name from Attribute,DBField where Attribute_Name = Field_Name AND (Field_Scope IS NULL OR Field_Scope != 'Attribute');",7,'Duplicate attribute name and field name','Duplicate attribute name and field name');

</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

</FINAL>
