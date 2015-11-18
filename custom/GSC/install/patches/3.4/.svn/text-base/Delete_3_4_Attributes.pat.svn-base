## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
DELETE Original_Source_Attribute  from Attribute, Original_Source_Attribute  WHERE Attribute_Name IN ('Biological_Condition','Donor_Health_Status') and FK_Attribute__ID = Attribute_ID;
DELETE from Attribute   WHERE Attribute_Name IN ('Biological_Condition','Donor_Health_Status') ;

</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
