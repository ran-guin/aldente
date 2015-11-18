## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

## This patch is doing three things
## 1) Update the 'Scope' of existing work requests to 'Library'
## 2) Create new records which are grouped by FK_Source__ID, FK_Goal__ID, FK_Funding__ID, FK_Work_Request_Type__ID and have the 'scope' set to 'Source'
## 3) Create new records which are grouped by SOW and have the 'scope' set to 'SOW'

## Also updates the Invoiceable_Work Items


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)



</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

UPDATE Work_Request SET Scope = 'Library';

# INSERT INTO Work_Request 
# SELECT NULL, FK_Goal__ID, MAX(Goal_Target), NULL, NULL, MAX(Num_Plates_Submitted), FK_Plate_Format__ID, FK_Work_Request_Type__ID, NULL, 'Original Request', FK_Funding__ID, Work_Request_Title, FK_Jira__ID, MIN(Work_Request_Created), FK_Source__ID, Percent_Complete, FKRequest_Employee__ID, FKRequest_Contact__ID, 'Source' FROM Work_Request WHERE Scope = 'Library' GROUP BY FK_Source__ID, FK_Goal__ID, FK_Funding__ID, FK_Work_Request_Type__ID; 

# INSERT INTO Work_Request 
# SELECT NULL, FK_Goal__ID, MAX(Goal_Target), NULL, NULL, MAX(Num_Plates_Submitted), FK_Plate_Format__ID, FK_Work_Request_Type__ID, NULL, 'Original Request', FK_Funding__ID, Work_Request_Title, FK_Jira__ID, MIN(Work_Request_Created), NULL, Percent_Complete, FKRequest_Employee__ID, FKRequest_Contact__ID, 'SOW' FROM Work_Request WHERE Scope = 'Source' GROUP BY FK_Goal__ID, FK_Funding__ID, FK_Work_Request_Type__ID; 


</DATA>
<CODE_BLOCK>

## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('NAME_GOES_HERE')) {


#    use alDente::Invoice;
#    use alDente::Work_Request;

#    my $invoice = new alDente::Invoice(-dbc => $dbc);
#    $invoice->backfill_invoiceable_work(-project_status => 'Active');
    
    
#    my $wr = new alDente::Work_Request(-dbc => $dbc);
#    $wr -> backfill_work_request( -dbc => $dbc);


}
</CODE_BLOCK>

<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
