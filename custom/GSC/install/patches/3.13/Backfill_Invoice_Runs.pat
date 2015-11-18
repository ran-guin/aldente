## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

## This patch is backfilling Invoiceable_Runs that were suppose to be there but were not due to a bug in the release.

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)


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
if (_check_block('backfill_invoiceable_work_reference')) {

    use alDente::Invoiceable_Work;

    my $invoiceable_work = new alDente::Invoiceable_Work(-dbc => $dbc);
    $invoiceable_work->backfill_invoiceable_work(-run => 'SolexaRun');
    $invoiceable_work->backfill_invoiceable_work(-run => 'SequenceRun');
    $invoiceable_work->backfill_invoiceable_work(-run => 'GenechipRun');
    $invoiceable_work->backfill_invoiceable_work(-run => 'GelRun');
    $invoiceable_work->backfill_invoiceable_work(-run => 'SOLIDRun');
    $invoiceable_work->backfill_invoiceable_work(-run => 'Ion_Torrent_Run');

}
</CODE_BLOCK>







<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
