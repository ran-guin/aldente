## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> 

DELETE FROM Pipeline_StepRelationship;
DELETE FROM Pipeline_Step;
UPDATE  Protocol_Step set Protocol_Step_Name =  Replace(Protocol_Step_Name,'to 1.50 mL','to 1.5 mL')  WHERE Protocol_Step_Name LIKE '% to 1.50 %';
UPDATE  Protocol_Step set Protocol_Step_Name =  Replace(Protocol_Step_Name,'to 2.00 mL','to 2 mL')  WHERE Protocol_Step_Name LIKE '% to 2.00 %';
UPDATE  Protocol_Step set Protocol_Step_Name =  Replace(Protocol_Step_Name,'to 50.00 mL','to 50 mL')  WHERE Protocol_Step_Name LIKE '% to 50.00 %';
UPDATE  Protocol_Step set Protocol_Step_Name =  Replace(Protocol_Step_Name,'to 0.20 mL','to 0.2 mL')  WHERE Protocol_Step_Name LIKE '% to 0.20 %';
UPDATE  Protocol_Step set Protocol_Step_Name =  Replace(Protocol_Step_Name,'to 0.50 mL','to 0.5 mL')  WHERE Protocol_Step_Name LIKE '% to 0.50 %';
UPDATE  Protocol_Step set Protocol_Step_Name =  Replace(Protocol_Step_Name,'to 15.00 mL','to 15 mL')  WHERE Protocol_Step_Name LIKE '% to 15.00 %';
UPDATE  Protocol_Step set Protocol_Step_Name =  Replace(Protocol_Step_Name,'to 5.00 mL','to 5 mL')  WHERE Protocol_Step_Name LIKE '% to 5.00 %';





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
<IMPORT>
Pipeline_Step.txt
Pipeline_StepRelationship.txt
</IMPORT>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
