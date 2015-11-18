## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Add FK_Taxonomy__ID to Original_Source table; backfill Original_Source.FK_Taxonomy__ID; change Original_Source.Organism to obsolete

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Original_Source ADD FK_Taxonomy__ID INT(11) NOT NULL; 
ALTER TABLE Original_Source add index FK_Taxonomy__ID (FK_Taxonomy__ID);

</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Taxonomy VALUES (9606, 'Homo sapiens', 'human');
UPDATE Original_Source set FK_Taxonomy__ID = 9606;
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
UPDATE DBField set Field_Options = 'Obsolete' where Field_Name = 'Organism' and Field_Table = 'Original_Source';

</FINAL>
