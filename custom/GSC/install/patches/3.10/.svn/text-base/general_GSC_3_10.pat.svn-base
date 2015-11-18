## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)


</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
UPDATE  DBField set Field_Reference = "concat(Original_Source.Original_Source_Name , ' #' , Source_Number,' (' ,Sample_Type.Sample_Type,')',' [', External_Identifier,']')"  WHERE Field_Name = 'Source_ID';

UPDATE DBField set Field_Order = Field_Order-7 WHERE Field_Table = 'Work_Request' AND Field_Name IN ('Num_Plates_Submitted','FK_Plate_Format__ID');
UPDATE DBField set Field_Description = "Indicate number of containers which will be shipped for this submission" WHERE Field_Table = 'Work_Request' AND Field_Name IN ('Num_Plates_Submitted');
UPDATE DBField set Field_Description = "If shipping containers, indicate the format of the containers being sent"  WHERE  Field_Table = 'Work_Request' AND Field_Name IN ('FK_Plate_Format__ID');
UPDATE DBField set Field_Description = "Target number to be completed (based upon specified goal)" WHERE Field_Table = 'Work_Request' AND Field_Name = 'Goal_Target';

UPDATE DBField set FKParent_DBField__ID = 3049, Parent_Value = '>0' where Field_Table = 'Work_Request' and Field_Name = 'FK_Plate_Format__ID';
</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

</FINAL>
