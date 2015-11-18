## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Move the FKApplicable_Funding__ID field from Invoiceable_Work table to Invoiceable_Work_Reference table, copy the values from old table to the new one, and add a new trigger method

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Invoiceable_Work_Reference ADD COLUMN FKApplicable_Funding__ID int(11) default NULL AFTER FK_Invoice__ID;

</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

UPDATE Invoiceable_Work_Reference,Invoiceable_Work SET Invoiceable_Work_Reference.FKApplicable_Funding__ID = Invoiceable_Work.FKApplicable_Funding__ID WHERE FKReferenced_Invoiceable_Work__ID = Invoiceable_Work_ID;

INSERT INTO DB_Trigger VALUES ('','Plate','Perl','require alDente::Work_Request; my $trigger = alDente::Work_Request->new(-dbc=>$dbc); $trigger->change_plate_WR_trigger(-dbc=>$dbc, -id=>$id);','batch_update','Active','Update the FKApplicable_Funding__ID if the Plate.FK_Work_Request__ID is changed','No','FK_Work_Request__ID');

</DATA>


<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

UPDATE DBField SET Field_Options = 'Obsolete' WHERE Field_Name = 'FKApplicable_Funding__ID' AND Field_Table = 'Invoiceable_Work';

</FINAL>
