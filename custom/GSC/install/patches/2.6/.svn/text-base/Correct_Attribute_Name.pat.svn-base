## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
## Fix Attribute_Name that has non-word characters
update Attribute set Attribute_Name = Replace(Replace(Replace(Replace(Replace(Replace(Replace(Attribute_Name,"#","_number"),"(b","_b"),"(",""),")",""),"/","_"),"-","_")," ","_") where Attribute_ID IN (25,31,79,80,83,88,111,117,243);

## Fix Attribute_Name that has duplicate DBField.Field_Name
update Attribute set Attribute_Name = 'Prep_Duration_Time' where Attribute_ID = 35;
update Attribute set Attribute_Name = 'Library_Type_Attribute' where Attribute_ID = 185;
update DBField, Attribute set Attribute_Name = CONCAT(Attribute_Class,"_",Attribute_Name) where Field_Name = Attribute_Name AND (Field_Scope != 'Attribute' OR Field_Scope IS NULL);

## Fix Protocol Step that uses attribute
update Protocol_Step set Input = Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Input,"Plate_Attribute=Concentration_(nM)","Plate_Attribute=Concentration_nM"),"Sample_Attribute=Size_Estimate","Sample_Attribute=Sample_Size_Estimate"),"Sample_Attribute=Size_StdDev","Sample_Attribute=Sample_Size_StdDev"),"WorkPackage_Attribute=Priority","WorkPackage_Attribute=WorkPackage_Priority"),"ReArray_Attribute=FK_Band__ID","ReArray_Attribute=ReArray_FK_Band__ID"),"WorkPackage_Attribute=Relevance to other Groups","WorkPackage_Attribute=Relevance_to_other_Groups"),"Original_Source_Attribute=Passage#","Original_Source_Attribute=Passage_number"),"Prep_Attribute=Time","Prep_Attribute=Prep_Duration_Time"),"Prep_Attribute=Volume","Prep_Attribute=Prep_Volume"),"Plate_Attribute=Adapter_A","Plate_Attribute=Plate_Adapter_A"),"Plate_Attribute=Adapter_B","Plate_Attribute=Plate_Adapter_B"),"Plate_Attribute=DiTag_PCR_cycle","Plate_Attribute=Plate_DiTag_PCR_cycle"),"Plate_Attribute=DiTag_Template_Dilution_Factor","Plate_Attribute=Plate_DiTag_Template_Dilution_Factor"),"Plate_Attribute=Clones_NoInsert_Percent","Plate_Attribute=Plate_Clones_NoInsert_Percent"),"Plate_Attribute=AvgInsertSize","Plate_Attribute=Plate_AvgInsertSize"),"Plate_Attribute=CFU","Plate_Attribute=Plate_CFU"),"Source_Attribute=Concentration","Source_Attribute=Source_Concentration"),"Source_Attribute=Cross-link_method","Source_Attribute=Cross_link_method"),"Source_Attribute=Cross-link_time_min","Source_Attribute=Cross_link_time_min"),"Plate_Attribute=DNA_concentration_ng/uL","Plate_Attribute=DNA_concentration_ng_uL"),"Plate_Attribute=Final_product_size(bp)","Plate_Attribute=Final_product_size_bp"),"Plate_Attribute=Agilent_concentration_ng/uL","Plate_Attribute=Agilent_concentration_ng_uL"),"Plate_Attribute=Concentration:","Plate_Attribute=Plate_Concentration:"),"Plate_Attribute=nt_index","Plate_Attribute=Plate_nt_index"),"Library_Attribute=type","Library_Attribute=Library_Library_type"),"Plate_Attribute=aRNA_used_for_cDNA_synthesis_(ng)","Plate_Attribute=aRNA_used_for_cDNA_synthesis_ng") where Input like "%Plate_Attribute=Concentration%" OR Input like "%Sample_Attribute=Size_Estimate%" OR Input like "%Sample_Attribute=Size_StdDev%" OR Input like "%WorkPackage_Attribute=Priority%" OR Input like "%ReArray_Attribute=FK_Band__ID%" OR Input like "%WorkPackage_Attribute=Relevance to other Groups%" OR Input like "%Original_Source_Attribute=Passage#%" OR Input like "%Prep_Attribute=Time%" OR Input like "%Prep_Attribute=Volume%" OR Input like "%Plate_Attribute=Adapter_A%" OR Input like "%Plate_Attribute=Adapter_B%" OR Input like "%Plate_Attribute=DiTag_PCR_cycle%" OR Input like "%Plate_Attribute=DiTag_Template_Dilution_Factor%" OR Input like "%Plate_Attribute=Clones_NoInsert_Percent%" OR Input like "%Plate_Attribute=AvgInsertSize%" OR Input like "%Plate_Attribute=CFU%" OR Input like "%Source_Attribute=Concentration%" OR Input like "%Source_Attribute=Cross-link_method%" OR Input like "%Source_Attribute=Cross-link_time_min%" OR Input like "%Plate_Attribute=DNA_concentration_ng/uL%" OR Input like "%Plate_Attribute=Final_product_size(bp)%" OR Input like "%Plate_Attribute=Agilent_concentration_ng/uL%" OR Input like "%Plate_Attribute=Concentration_(nM)%" OR Input like "%Plate_Attribute=nt_index%" OR Input like "%Library_Attribute=type%" OR Input like "%Plate_Attribute=aRNA_used_for_cDNA_synthesis_(ng)%";

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
