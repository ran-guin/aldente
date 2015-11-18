## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

    ALTER TABLE DBTable ADD Attach_Tables text;
    
</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

    UPDATE DBTable set Attach_Tables = "LEFT JOIN Organization ON Contact.FK_Organization__ID=Organization_ID" WHERE DBTable_Name = 'Contact';
    UPDATE DBTable set Attach_Tables = "LEFT JOIN Stock ON Solution.FK_Stock__ID=Stock_ID LEFT JOIN Stock_Catalog ON Stock.FK_Stock_Catalog__ID=Stock_Catalog_ID" WHERE DBTable_Name = 'Solution';
    UPDATE DBTable set Attach_Tables = "LEFT JOIN Stock_Catalog ON Stock.FK_Stock_Catalog__ID=Stock_Catalog_ID" WHERE DBTable_Name = 'Stock';
    UPDATE DBTable set Attach_Tables = "LEFT JOIN Prep ON Plate_Prep.FK_Prep__ID=Prep_ID" WHERE DBTable_Name = 'Plate_Prep';
    UPDATE DBTable set Attach_Tables = "LEFT JOIN Original_Source ON Source.FK_Original_Source__ID=Original_Source_ID LEFT JOIN Sample_Type ON Source.FK_Sample_Type__ID=Sample_Type_ID" WHERE DBTable_Name = 'Source';
    UPDATE DBTable set Attach_Tables = "LEFT JOIN Funding ON Work_Request.FK_Funding__ID=Funding_ID LEFT JOIN Goal ON Work_Request.FK_Goal__ID=Goal_ID" WHERE DBTable_Name = 'Work_Request';
    UPDATE DBTable set Attach_Tables = "LEFT JOIN Taxonomy ON Patient.FK_Taxonomy__ID=Taxonomy_ID" WHERE DBTable_Name = 'Patient';
    UPDATE DBTable set Attach_Tables = "LEFT JOIN BCR_Study ON BCR_Batch.FK_BCR_Study__ID=BCR_Study_ID" WHERE DBTable_Name = 'BCR_Batch';
    UPDATE DBTable set Attach_Tables = "LEFT JOIN Histology ON Pathology.FK_Histology__ID=Histology_ID LEFT JOIN Anatomic_Site ON Pathology.FKPrimary_Anatomic_Site__ID=Anatomic_Site_ID" WHERE DBTable_Name = 'Pathology';
    UPDATE DBTable set Attach_Tables = "LEFT JOIN Contact ON Sample_Request.FK_Contact__ID=Contact_ID LEFT JOIN Funding ON Sample_Request.FK_Funding__ID=Funding_ID" WHERE DBTable_Name = 'Sample_Request';

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
