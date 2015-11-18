## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

### Enable Queueing system via Funding ###
Create TABLE Queue (Queue_ID INT NOT NULL Auto_increment PRIMARY KEY, Queue_Name varchar(40), Queue_Priority ENUM('High','Normal','Low') DEFAULT 'Normal', Queue_Description TEXT);

ALTER TABLE Funding ADD FK_Queue__ID INT DEFAULT 1;
CREATE INDEX queue on Funding (FK_Queue__ID);
INSERT INTO Queue values ('','N/A','Normal','No queue specified');
ALTER TABLE Funding DROP Source_ID;


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
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

UPDATE DBField set Field_Reference = 'Queue_Name' where Field_Name = 'Queue_ID';

</FINAL>
