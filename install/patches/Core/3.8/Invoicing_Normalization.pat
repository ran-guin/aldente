## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
-Addition of table Invoiceable_Work table, moving common columns from Invoiceable_Prep, Invoiceable_Run and Invoiceable_Analysis into Invoiceable_Work

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

DROP TABLE IF EXISTS Invoiceable_Work;

CREATE TABLE IF NOT EXISTS Invoiceable_Work (
	Invoiceable_Work_ID int(11) NOT NULL AUTO_INCREMENT,	
	FK_Source__ID int(11) NOT NULL,
	FK_Plate__ID int(11) NOT NULL,
	FK_Tray__ID int(11) NULL,
	FK_Invoice__ID int(11) NULL,
	FKParent_Invoiceable_Work__ID int(11) NULL,
	Indexed int(11) NULL,
	Invoiceable_Work_Type ENUM('Prep', 'Run', 'Analysis') NOT NULL,
	Invoiceable_Work_DateTime datetime NOT NULL,	
	Invoiceable_Work_Comments text NULL,	
	Billable ENUM('Yes','No') NOT NULL Default 'Yes',
	PRIMARY KEY (Invoiceable_Work_ID),
	KEY (FK_Source__ID),
	KEY (FK_Plate__ID),
	KEY (FK_Tray__ID),
	KEY (FK_Invoice__ID),
	KEY (FKParent_Invoiceable_Work__ID),
	INDEX (Invoiceable_Work_DateTime)
);

ALTER TABLE Invoiceable_Prep
DROP COLUMN FK_Source__ID,
DROP COLUMN FK_Plate__ID,
DROP COLUMN FK_Tray__ID,
DROP COLUMN FK_Invoice__ID,
DROP COLUMN FK_Work_Request__ID,
DROP COLUMN FKParent_Invoiceable_Prep__ID,
DROP COLUMN Indexed,
DROP COLUMN Invoiceable_Prep_Comments,
DROP COLUMN Billable,
ADD COLUMN FK_Invoiceable_Work__ID int(11) NOT NULL, 
ADD KEY (FK_Invoiceable_Work__ID);

ALTER TABLE Invoiceable_Run
DROP COLUMN FK_Source__ID,
DROP COLUMN FK_Plate__ID,
DROP COLUMN FK_Tray__ID,
DROP COLUMN FK_Invoice__ID,
DROP COLUMN FK_Work_Request__ID,
DROP COLUMN FKParent_Invoiceable_Run__ID,
DROP COLUMN Indexed,
DROP COLUMN Invoiceable_Run_Comments,
DROP COLUMN Billable,
ADD COLUMN FK_Invoiceable_Work__ID int(11) NOT NULL, 
ADD KEY (FK_Invoiceable_Work__ID);

ALTER TABLE Invoiceable_Analysis
DROP COLUMN FK_Source__ID,
DROP COLUMN FK_Plate__ID,
DROP COLUMN FK_Tray__ID,
DROP COLUMN FK_Invoice__ID,
DROP COLUMN FK_Work_Request__ID,
DROP COLUMN FKParent_Invoiceable_Analysis__ID,
DROP COLUMN Indexed,
DROP COLUMN Invoiceable_Analysis_Comments,
DROP COLUMN Billable,
ADD COLUMN FK_Invoiceable_Work__ID int(11) NOT NULL, 
ADD KEY (FK_Invoiceable_Work__ID);

/*Clear and reset auto increment of tables*/
TRUNCATE TABLE Invoiceable_Prep;
TRUNCATE TABLE Invoiceable_Run;
TRUNCATE TABLE Invoiceable_Analysis;

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
if (_check_block('backfill_invoiceable_tables')) { 




}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


/*Field reference for Invoice Prep*/
UPDATE DBField SET Field_Reference = 'CASE WHEN Indexed > 0 THEN CONCAT( Invoiceable_Work_ID, \' - Indexed(1/\' ,Indexed, \')\' ) ELSE Invoiceable_Work_ID END' WHERE Field_Table = 'Invoiceable_Work' AND Field_Name = 'Invoiceable_Work_ID';

/*Change references for older tables*/
UPDATE DBField SET Field_Reference = 'Invoice_Protocol.Invoice_Protocol_Name' WHERE Field_Table = 'Invoiceable_Prep' AND Field_Name = 'Invoiceable_Prep_ID';
UPDATE DBField SET Field_Reference = 'Invoice_Run_Type.Invoice_Run_Type_Name' WHERE Field_Table = 'Invoiceable_Run' AND Field_Name = 'Invoiceable_Run_ID';
UPDATE DBField SET Field_Reference = 'Invoice_Analysis_Step.Invoice_Analysis_Step_Name' WHERE Field_Table = 'Invoiceable_Analysis' AND Field_Name = 'Invoiceable_Analysis_ID';


</FINAL>
