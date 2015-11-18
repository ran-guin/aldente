## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database



</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Collaboration ADD Collaboration_Type enum('Standard','Admin') NOT NULL DEFAULT 'Standard' ;
ALTER TABLE Submission ADD FKAdmin_Contact__ID int(11) DEFAULT NULL;


</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO DB_Form values ('','Contact',1,1,1,'','','',0,'');
INSERT INTO DB_Form (select '', 'Collaboration' , 1,1,5, DB_Form_ID ,'','',0,'' from DB_Form WHERE Form_Table = 'Contact');



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
update DBField set Prompt = 'Principle Investigator'  WHERE Field_Name = 'FKAdmin_Contact__ID';
UPDATE DBField set Editable= 'Admin'  WHERE Field_Name like  '%Receive%' and Field_Table = 'Source';  


</FINAL>
