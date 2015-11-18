## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Adds Priority and Abbreviation columns to Invoice_Protocol table for reporting in Summary of Work (Invoicing).
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
ALTER TABLE Invoice_Protocol ADD COLUMN Priority enum('1', '2', '3', '4') NOT NULL DEFAULT 3;
ALTER TABLE Invoice_Protocol ADD COLUMN Abbrev varchar(80);
</SCHEMA>

<DATA> 
UPDATE Invoice_Protocol SET Priority = 1 WHERE Invoice_Protocol_ID IN (1, 2, 3, 5, 6, 7, 8, 16, 22, 26, 27, 44, 46, 47, 48, 55);
UPDATE Invoice_Protocol SET Priority = 2 WHERE Invoice_Protocol_ID IN (23, 38, 40, 41, 49, 50, 51, 52, 54);
UPDATE Invoice_Protocol SET Priority = 3 WHERE Invoice_Protocol_ID IN (17, 18, 19, 20, 21, 24, 25, 35, 36, 37, 39, 42, 43, 45, 53, 56, 57, 59);
UPDATE Invoice_Protocol SET Priority = 4 WHERE Invoice_Protocol_ID IN (28, 29, 30, 31);

UPDATE Invoice_Protocol SET Abbrev = 'Strand Specific' WHERE Invoice_Protocol_ID = 23;
UPDATE Invoice_Protocol SET Abbrev = 'SMART' WHERE Invoice_Protocol_ID = 41;
UPDATE Invoice_Protocol SET Abbrev = 'FFPE' WHERE Invoice_Protocol_ID = 49;
UPDATE Invoice_Protocol SET Abbrev = 'Manual FFPE' WHERE Invoice_Protocol_ID = 50;
UPDATE Invoice_Protocol SET Abbrev = 'Manual Strand Specific' WHERE Invoice_Protocol_ID = 51;
UPDATE Invoice_Protocol SET Abbrev = 'Manual' WHERE Invoice_Protocol_ID = 52;
UPDATE Invoice_Protocol SET Abbrev = 'Manual SMART' WHERE Invoice_Protocol_ID = 54;
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

 
