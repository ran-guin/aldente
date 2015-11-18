## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

# This Status will tell whether an Invoice is a debit or a credit from another Invoice. By defaault it should be a n/a. If the item is not invoiced, then it will be n/a.
# Also updates a couple of triggers which  help keep the Run.Billable and Invoiceable_Work_Reference.Billable statuses consistant.

</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Invoiceable_Work_Reference ADD Invoice_Status ENUM('Debit', 'Credit', 'n/a') NOT NULL DEFAULT 'n/a' ;


</SCHEMA> 

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

## Updaing all Invoiced Items to be default debit

UPDATE Invoiceable_Work_Reference SET Invoice_Status = 'Debit' WHERE FK_Invoice__ID IS NOT NULL;

## Update triggers

UPDATE DB_Trigger SET Value = '
UPDATE Invoiceable_Work_Reference, (SELECT IWR.Invoiceable_Work_Reference_ID, IWR.FK_Invoice__ID FROM Invoiceable_Work_Reference AS IWR WHERE IWR.Invoiceable_Work_Reference_ID in (<ID>)) AS IWR_Values SET  Invoiceable_Work_Reference.FK_Invoice__ID = CASE WHEN Invoiceable_Work_Reference.FK_Invoice__ID IS NOT NULL AND IWR_Values.FK_Invoice__ID IS NOT NULL THEN Invoiceable_Work_Reference.FK_Invoice__ID ELSE IWR_Values.FK_Invoice__ID END, Invoiceable_Work_Reference.Invoice_Status = CASE WHEN IWR_Values.FK_Invoice__ID IS NOT NULL THEN \'Debit\' ELSE \'n/a\' END, Invoiceable_Work_Reference.Invoiceable_Work_Reference_Invoiced = CASE WHEN IWR_Values.FK_Invoice__ID IS NOT NULL THEN \'Yes\' ELSE \'No\' END WHERE  (Invoiceable_Work_Reference.Invoiceable_Work_Reference_ID in (<ID>) OR Invoiceable_Work_Reference.FKParent_Invoiceable_Work_Reference__ID in (<ID>)) AND (Invoiceable_Work_Reference.FKParent_Invoiceable_Work_Reference__ID = IWR_Values.Invoiceable_Work_Reference_ID OR Invoiceable_Work_Reference.Invoiceable_Work_Reference_ID = IWR_Values.Invoiceable_Work_Reference_ID);' WHERE DB_Trigger_ID = 45;

INSERT INTO DB_Trigger VALUES (NULL, 'Run', 'Perl', 'require alDente::Invoiceable_Work; my $ok = alDente::Invoiceable_Work::invoice_billable_trigger(-dbc=>$self,-id=>$id,-table=>\'Run\');', 'update', 'Active', 'Updates the redundant field in the Invoiceable_Work_Reference table.', 'No', NULL);

INSERT INTO DB_Trigger VALUES (NULL, 'Invoiceable_Work_Reference', 'Perl', 'require alDente::Invoiceable_Work; my $ok = alDente::Invoiceable_Work::invoice_billable_trigger(-dbc=>$self,-id=>$id,-table=>\'Invoiceable_Work\');', 'update', 'Active', 'Updates the redundant field in the Invoiceable_Work_Reference table.', 'No', NULL);

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

 