## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO DB_Trigger values ('','Library','Perl','require TCGA::Trigger; my $trigger = TCGA::Trigger->new(-dbc=>$dbc); $trigger->TCGA_Library_trigger(-id=>"<ID>");','insert','Active','Special trigger to set Library_FullName','No','');


</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
