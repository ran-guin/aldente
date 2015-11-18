## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
## LIMS-12015
</DESCRIPTION>


<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>


<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

UPDATE DB_Trigger SET Value = "require GSC::Model; my $trigger = GSC::Model->new(-dbc=>$dbc); $trigger->determine_reference_trigger(-run_analysis_id=><ID>);" WHERE DB_Trigger_ID IN (33);

UPDATE DB_Trigger SET Value = "require GSC::Model; my $trigger = GSC::Model->new(-dbc=>$dbc); $trigger->determine_reference_trigger(-multiplex_run_analysis_id=><ID>);" WHERE DB_Trigger_ID IN (37);

UPDATE DB_Trigger SET Field_Name = 'Billable' WHERE Table_Name = 'Invoiceable_Work_Reference' AND DB_Trigger_ID = 47;

INSERT INTO DB_Trigger (Table_Name, DB_Trigger_Type, Value, Trigger_On, Trigger_Description, Fatal, Field_Name) VALUES ('Invoiceable_Work_Reference', 'Perl', 'require alDente::Invoiceable_Work; my $trigger = alDente::Invoiceable_Work->new(-dbc=>$dbc); $trigger->iwr_invoice_trigger(-dbc=>$dbc, -id=>$id);', 'batch_update', 'Update Invoiceable_Work_Reference invoice related fields', 'No', 'FK_Invoice__ID');

</DATA>


<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
