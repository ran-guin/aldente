## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Add a new DB_Trigger record for IWR.FKApplicable_Funding__ID field, and set IWR.FKApplicable_Funding__ID -> Tracked no -> yes in DBField

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

INSERT INTO DB_Trigger VALUES ('','Invoiceable_Work_Reference','Perl','require alDente::Invoiceable_Work; my $trigger = alDente::Invoiceable_Work->new(-dbc=>$dbc); $trigger->iwr_change_funding_trigger(-dbc=>$dbc, -id=>$id);','batch_update','Active','Send email notification if a FKApplicable_Funding__ID changed','No','FKApplicable_Funding__ID');

UPDATE DBField SET Tracked = 'yes' WHERE Field_Name = 'FKApplicable_Funding__ID' AND Field_Table = 'Invoiceable_Work_Reference';

</DATA>


<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
</FINAL>
