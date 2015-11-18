## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

## Split up OS records by Anatomic Site (Blood / Saliva / Urine) 

 UPDATE Original_Source, Source SET FK_Anatomic_Site__ID = 1, Original_Source_Name = CONCAT(Original_Source_Name,' Blood') WHERE FK_Original_Source__ID=Original_Source_ID AND Source.FK_Sample_Type__ID IN (4,5,6,7,10,12) AND Length(Original_Source_Name) = 8 ;

UPDATE Original_Source, Source SET FK_Anatomic_Site__ID = 2, Original_Source_Name = CONCAT(Original_Source_Name,' Urine') WHERE FK_Original_Source__ID=Original_Source_ID AND Source.FK_Sample_Type__ID IN (8) AND Length(Original_Source_Name) = 8;

UPDATE Original_Source, Source SET FK_Anatomic_Site__ID = 3, Original_Source_Name = CONCAT(Original_Source_Name,' Saliva') WHERE FK_Original_Source__ID=Original_Source_ID AND Source.FK_Sample_Type__ID IN (9) AND Length(Original_Source_Name) = 8;


INSERT INTO Original_Source (Original_Source_ID, Original_Source_Name, Description, FK_Contact__ID, FKCreated_Employee__ID, Defined_Date, Sample_Available, FK_Patient__ID, Disease_Status, Original_Source_Type, FK_Anatomic_Site__ID) select '', CONCAT(LEFT(External_Identifier,8),' Saliva'), Description, FK_Contact__ID, FKCreated_Employee__ID, Defined_Date, Sample_Available, FK_Patient__ID, Disease_Status, 'Bodily_Fluid', 3 FROM Original_Source, Source WHERE FK_Original_Source__ID=Original_Source_ID AND FK_Anatomic_Site__ID !=3 AND FK_Sample_Type__ID = 9 GROUP BY Original_Source_ID;

INSERT INTO Original_Source (Original_Source_ID, Original_Source_Name, Description, FK_Contact__ID, FKCreated_Employee__ID, Defined_Date, Sample_Available, FK_Patient__ID, Disease_Status, Original_Source_Type, FK_Anatomic_Site__ID) select '', CONCAT(LEFT(External_Identifier,8),' Urine'), Description, FK_Contact__ID, FKCreated_Employee__ID, Defined_Date, Sample_Available, FK_Patient__ID, Disease_Status, 'Bodily_Fluid', 2 FROM Original_Source, Source WHERE FK_Original_Source__ID=Original_Source_ID AND FK_Anatomic_Site__ID != 2 AND FK_Sample_Type__ID = 8 GROUP BY Original_Source_ID;

### Update Sample_Collection_Time (replaces collection_time attribute) ###

UPDATE Source, Source_Attribute SET Sample_Collection_Time = Attribute_Value WHERE FK_Source__ID=Source_ID AND FK_Attribute__ID = 10 AND Sample_Collection_Time IS NULL;

</DATA>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
