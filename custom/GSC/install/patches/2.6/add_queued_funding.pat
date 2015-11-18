## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
insert into Queue values ('','GBC','High','Genome BC Funded');
insert into Queue values ('','NCI','High','National Cancer Institute Funded');
insert into Queue values ('','Aparicio','High','Funded by Sam Aparicio');
insert into Queue values ('','Collins','High','Funded by C Collins');
insert into Queue values ('','Huntsman','High','Funded by David Huntsman');

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

update Funding set FK_Queue__ID = 4 where Funding_Name IN ('GSC-0156','GSC-0245','GSC-0297','GSC-0258');
# update Library,Work_Request,Funding SET FK_Queue__ID = 4 WHERE FK_Library__Name=Library_Name AND FK_Funding__ID=Funding_ID AND FK_Project__ID IN (274,279,234,261,186);

update Funding set FK_Queue__ID = 5 where Funding_Name IN ('GSC-0411');
# update Library,Work_Request,Funding SET FK_Queue__ID = 5 WHERE FK_Library__Name=Library_Name AND FK_Funding__ID=Funding_ID AND FK_Project__ID IN (190);

update Funding set FK_Queue__ID = 6 where Funding_Name IN ('GSC-0205','GSC-0278','GSC-0315');
# update Library,Work_Request,Funding SET FK_Queue__ID = 6 WHERE FK_Library__Name=Library_Name AND FK_Funding__ID=Funding_ID AND FK_Project__ID IN (237,272,210);

# update Funding set FK_Queue__ID = 2 where Funding_Name like 'Genome BC%';
update Funding Set FK_Queue__ID = 2 WHERE LEFT(Funding_Code,8) IN 
('GSC-0103'
,'GSC-0151'
,'GSC-0183'
,'GSC-0187'
,'GSC-0194'
,'GSC-0213'
,'GSC-0235'
,'GSC-0249'
,'GSC-0250'
,'GSC-0288'
,'GSC-0304'
,'GSC-0321'
,'GSC-0329'
,'GSC-0329A'
,'GSC-0334'
,'GSC-0345'
,'GSC-0365'
,'GSC-0370'
,'GSC-0371'
,'GSC-0376'
,'GSC-0383'
,'GSC-0384'
,'GSC-0385'
,'GSC-0386'
,'GSC-0388'
,'GSC-0389'
,'GSC-0390'
,'GSC-0391'
,'GSC-0392'
,'GSC-0393'
,'GSC-0397'
,'GSC-0406'
,'GSC-0450'
,'GSC-0457'
,'GSC-0464'
,'GSC-0467'
,'GSC-0471'
,'GSC-0472'
,'GSC-0480'
,'GSC-0502');

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
