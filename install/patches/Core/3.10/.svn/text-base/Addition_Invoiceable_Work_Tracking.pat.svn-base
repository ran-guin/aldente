## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
- addition of new goal for tracking (indexed library tracking)
- addition of lab protocols for invoicing
- add column to determine prep name to track for each protocol

invoiceBackfill procedure Usage:
Parameters are: 
	Type of backfill: Prep, Run 
	Ids of invoice types: Invoice_Protocol_ID, Invoice_Run_Type_ID 
	Temporary table name: used for manipulating data (will add then drop the table when it is done) 
	Temporary column name: adds into Invoiceable_Work table (will add then drop the column when it is done)
eg. 
Preps_backfill:	CALL invoiceBackfill( 'Prep', '1,2,3,4', '2011-01-01', 'Invoice_Work_Temp', 'TempCol');
Runs_backfill: CALL invoiceBackfill( 'Run', '1,2,3,4', '2011-01-01', 'Invoice_Work_Temp', 'TempCol');

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Invoice_Protocol
ADD COLUMN `Tracked_Prep_Name` varchar(80) DEFAULT 'Completed Protocol';

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO Goal (Goal_Name, Goal_Description, Goal_Type, Goal_Scope)
VALUES( 'Indexed Library Tracking', 'Upload index via a file into LIMS to keep track of offsite constructed libraries that were indexed and pooled for submission', 'Data Analysis', 'Specific');

INSERT INTO Invoice_Protocol (Invoice_Protocol_Name, FK_Lab_Protocol__ID, Invoice_Protocol_Type)
SELECT LP.Lab_Protocol_Name, LP.Lab_Protocol_ID, 'Upstream_Library_Construction' FROM Lab_Protocol LP 
WHERE LP.Lab_Protocol_Name IN( 'AllPrep RNA and DNA Extraction', 'FG Trizol RNA Extraction', 'DNA Extraction from Blood Samples', 'Genomic DNA Extraction', 'SLX-ChIP', 'miRNA3_PCR', 'SLX 96well Strand Specific');

UPDATE Invoice_Protocol SET Tracked_Prep_Name = 'Disruption of tissue or cells' WHERE Invoice_Protocol_Name = 'AllPrep RNA and DNA Extraction';


/*Call stored procedure to reset all Invoiceable work items, should never be done again Truncates all invoiceable work tables and backfills.... only Backfill from now onwards*/
CALL backfillResetInvoiceableWork('ResetAll', '16,17,18,19,20,21', '2011-01-01', 'Somethingl','something');

/*	Drop this version of backfill*/
DROP PROCEDURE backfillResetInvoiceableWork;

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
