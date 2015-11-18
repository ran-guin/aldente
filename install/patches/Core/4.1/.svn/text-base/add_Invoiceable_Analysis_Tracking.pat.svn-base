## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Adds foreign key references (FK_Run_Analysis__ID, FK_Multiplex_Run_Analysis__ID) to the Invoiceable_Work table to allow for invoiceable run analysis tracking.
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Invoiceable_Work ADD COLUMN FK_Run_Analysis__ID int(11), ADD FOREIGN KEY (FK_Run_Analysis__ID) REFERENCES Run_Analysis(Run_Analysis_ID);
ALTER TABLE Invoiceable_Work ADD COLUMN FK_Multiplex_Run_Analysis__ID int(11), ADD FOREIGN KEY (FK_Multiplex_Run_Analysis__ID) REFERENCES Multiplex_Run_Analysis(Multiplex_Run_Analysis_ID);
</SCHEMA>

<DATA> 
</DATA>

<CODE_BLOCK>
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
</CODE_BLOCK>

<FINAL> 
## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
</FINAL>

 
