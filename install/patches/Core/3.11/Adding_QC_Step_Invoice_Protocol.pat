## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Modifying Invoice_Protocol table to include 'Sample_QC' as an enum type for Invoice_Protocol_Type.

Adding 4 QC protocols to the Invoice_Protocol  table which are,'Agilent 1 (RNA)' , 'Agilent 2 (RNA/DNAse I)' , 'Caliper total RNA QC',and 'DNA QC'.

Also adding 3 RDT steps to Invoiceable_Protocol table.


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Invoice_Protocol MODIFY Invoice_Protocol_Type enum('Upstream_Library_Construction','Library_Construction','Sample_QC', 'RD_Qubit') default NULL;


</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

INSERT INTO Invoice_Protocol
SELECT NULL,'Sample QC','Sample_QC', Lab_Protocol_ID, 'Completed Protocol' FROM Lab_Protocol WHERE Lab_Protocol_Name IN ('Agilent 1 (RNA)' , 'Agilent 2 (RNA/DNAse I)' , 'DNA QC' , 'Caliper total RNA QC');

INSERT INTO Invoice_Protocol
SELECT NULL, Lab_Protocol_Name, 'RD_Qubit', Lab_Protocol_ID, 'Completed Protocol' FROM Lab_Protocol WHERE Lab_Protocol_Name IN ('RD Template Qubit' , 'RD Sheared Qubit' , 'RD Amplicon Qubit');


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
