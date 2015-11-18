## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

##Creates a trigger that will change the Invoiced Status to 'Yes' when there is an associated invoice and 'No' when there is not.

## Also gets rid of the text ' - DRAFT' at the end of all draft names


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

INSERT INTO DB_Trigger (DB_Trigger_ID, Table_Name, DB_Trigger_Type, Value, Trigger_On, Status, Trigger_Description,  Fatal, Field_Name) VALUES ( NULL, 'Invoiceable_Work_Reference', 'SQL', 'UPDATE Invoiceable_Work_Reference SET FK_Invoice__ID = (SELECT IWR.FK_Invoice__ID FROM (SELECT * FROM Invoiceable_Work_Reference) AS IWR WHERE IWR.Invoiceable_Work_Reference_ID in (<ID>)), Invoiceable_Work_Reference_Invoiced = CASE WHEN FK_Invoice__ID IS NOT NULL AND FK_Invoice__ID > 0 THEN \'Yes\' ELSE \'No\' END WHERE Invoiceable_Work_Reference_ID in (<ID>) OR FKParent_Invoiceable_Work_Reference__ID in (<ID>)', 'update', 'Active', 'Update the Invoiceable_Work_Referenced_Invoiced column to reflect whether something is invoiced or not. Also updates all the children of the Invoiceable_Work_Reference with the FK_Invoice__ID ', 'Yes', NULL);


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


UPDATE DBField SET Field_Reference = 'CASE WHEN Invoice_Code IS NOT NULL THEN Invoice_Code ELSE Invoice_Draft_Name END' WHERE Field_Table = 'Invoice' AND Field_Name = 'Invoice_ID';


</FINAL>
