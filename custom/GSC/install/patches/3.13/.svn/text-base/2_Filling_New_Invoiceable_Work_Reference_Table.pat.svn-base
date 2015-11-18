## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Filling the new Invoiceable_Work_Reference table with old values from the Invoiceable_Work Table


</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)


</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

## Inserting all the information that is to be tranfered to the new Invoiceable_Work_Reference table

INSERT INTO Invoiceable_Work_Reference(

Invoiceable_Work_Reference_ID,
FK_Source__ID, 
Indexed, 
FKReferenced_Invoiceable_Work__ID, 
FK_Invoice__ID,
Billable, 
Invoiceable_Work_Reference_Invoiced
) 

SELECT 
Invoiceable_Work_ID,
FK_Source__ID, 
Indexed, 
Invoiceable_Work_ID, 
FK_Invoice__ID, 
Billable, 
Invoiceable_Work_Invoiced

FROM Invoiceable_Work;

## Updating the Parent_Invoiceable_Work_Reference to point to the parents

UPDATE Invoiceable_Work_Reference
SET FKParent_Invoiceable_Work_Reference__ID = (
SELECT CASE WHEN FKParent_Invoiceable_Work__ID IS NOT NULL THEN FKParent_Invoiceable_Work__ID ELSE NULL END
FROM Invoiceable_Work
WHERE Invoiceable_Work.Invoiceable_Work_ID = Invoiceable_Work_Reference.Invoiceable_Work_Reference_ID
);

</DATA>
<CODE_BLOCK>

## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('backfill_invoiceable_work_reference')) {

    use alDente::Invoiceable_Work;

    my $invoiceable_work = new alDente::Invoiceable_Work(-dbc => $dbc);
    $invoiceable_work->backfill_invoiceable_work_reference(-dbc => $dbc);

}
</CODE_BLOCK>

<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
