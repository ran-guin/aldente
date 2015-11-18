## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
update Attribute set Attribute_Type = "enum('N/A','Fisher 550 Sonic Dismembrator','Bioruptor','Diagenode Bioruptor','Branson Sonifer 450','Covaris-S2 series','Covaris')"  WHERE Attribute_ID =210;
DELETE from Original_Source_Attribute WHERE FK_Attribute__ID = 346;
DELETE from Attribute WHERE Attribute_ID = 346;
DELETE from Original_Source_Attribute WHERE FK_Attribute__ID = 261;
DELETE from Attribute WHERE Attribute_ID = 261;

</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
