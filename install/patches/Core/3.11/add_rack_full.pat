## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

Add rack_full field to track slots that are full.  This allows for quick checking to see if they are full and possibly to see if boxes are full.
RUNNING PRIOR TO RELEASE

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Rack add Rack_Full enum('Y','N') default 'N'; 
</SCHEMA> 
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
update Rack,Source set Rack_Full = 'Y' where Rack_Type = 'Slot' and Rack_ID = Source.FK_Rack__ID;
update Rack,Plate set Rack_Full = 'Y' where Rack_Type = 'Slot' and Rack_ID = Plate.FK_Rack__ID;
update Rack,Solution set Rack_Full = 'Y' where Rack_Type = 'Slot' and Rack_ID = Solution.FK_Rack__ID;

</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
