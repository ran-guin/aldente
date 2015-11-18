## Patch file to modify a database

<DESCRIPTION>
This patch assumes the following TEMPORARY tables are already in the database
 
</DESCRIPTION>



<SCHEMA>
#ALTER TABLE Original_Source DROP FK_Biological_Condition__ID;
#DROP TABLE Biological_Condition;
#DROP TABLE Anatomical_Site;

</SCHEMA>
<DATA> 
## fill Anatomic_Site

#insert into Anatomic_Site (select '', Anatomic_Site_Name ,'', Anatomic_Site_Alias, 'SOLID_Tissue' from temp_AS WHERE Anatomic_Site_Type = 'Solid_Tissue' order by Anatomic_Site_ID);
#insert into Anatomic_Site (select '', Anatomic_Site_Name ,'', Anatomic_Site_Alias, 'Fluid'        from temp_AS WHERE Anatomic_Site_Type = 'Fluid' order by Anatomic_Site_ID);
#insert into Anatomic_Site (select '', Anatomic_Site_Name ,'', Anatomic_Site_Alias, 'Exfoliate'    from temp_AS WHERE Anatomic_Site_Type = 'Exfoliate' order by Anatomic_Site_ID);
#insert into Anatomic_Site (select '', Anatomic_Site_Name ,'', Anatomic_Site_Alias, 'Stem_Cell'    from temp_AS WHERE Anatomic_Site_Type = 'Stem_Cell' order by Anatomic_Site_ID);
update Anatomic_Site as p , Anatomic_Site as c set  c.FKParent_Anatomic_Site__ID = p.Anatomic_Site_ID WHERE concat(p.Anatomic_Site_Alias,'-',c.Anatomic_Site_Name)= c.Anatomic_Site_Alias;

## fill Cell_Line
insert into Cell_Line (Cell_Line_Name)  (select distinct Tissue_Subtype from Tissue WHERE Tissue_Name LIKE 'Cell Line%');


## Adjust temp_Tissue
update temp_Tissue, temp_AS, Anatomic_Site set temp_Tissue.FK_Anatomic_Site__ID = Anatomic_Site.Anatomic_Site_ID  WHERE FK_temp_Anatomic_Site__ID= temp_AS.Anatomic_Site_ID and temp_AS.Anatomic_Site_Alias= Anatomic_Site.Anatomic_Site_Alias;

update temp_Tissue, Cell_Line set FK_Cell_Line_Type__ID = Cell_Line_ID  WHERE Tissue_Name = 'Cell Line' and Tissue_Subtype = Cell_Line_Name;
update temp_Tissue, Original_Source, Cell_Line set Original_Source.FK_Cell_Line__ID = Cell_Line_ID  WHERE FK_Tissue__ID = Tissue_ID and temp_Tissue.FK_Cell_Line_Type__ID = Cell_Line_ID;

update  Original_Source, Anatomic_Site set FK_Anatomic_Site__ID = Anatomic_Site_ID   WHERE FK_Cell_Line__ID > 0 and Anatomic_Site_Alias = 'Unknown'; 

update temp_Tissue, Original_Source, Anatomic_Site set Original_Source.FK_Anatomic_Site__ID = temp_Tissue.FK_Anatomic_Site__ID  WHERE FK_Tissue__ID = Tissue_ID and temp_Tissue.FK_Anatomic_Site__ID = Anatomic_Site_ID;

update Original_Source set  Original_Source_Type = 'Cell_Line'  WHERE  FK_Cell_Line__ID > 0;
update Anatomic_Site, Original_Source set  Original_Source_Type = Anatomic_Site_Type  WHERE Original_Source_Type IS NULL and FK_Anatomic_Site__ID = Anatomic_Site_ID;













## Updating Original Source Pathology field
update Attribute, Original_Source_Attribute , Original_Source set Pathology = 'Normal' WHERE FK_Attribute__ID = Attribute_ID and Attribute_Name LIKE "%condition%" and Attribute_Value LIKE '%normal%' and FK_Original_Source__ID = Original_Source_ID and Pathology IS NULL ;
 
 
## Fill Histology
Insert into Histology (select '', Histology_Name , '' , Histology_Alias  from temp_Histology WHERE Histology_Status = 'Active');
CREATE TABLE `super_temp` (
  `Histology_ID` int(11) NOT NULL auto_increment,
  `Histology_Name` varchar(255) NOT NULL default '',
  `FKParent_Histology__ID` int(11) default NULL,
  `Histology_Alias` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`Histology_ID`),
  KEY `parent` (`FKParent_Histology__ID`)
);
Insert into super_temp (select * from Histology order by Histology_ID);
update Histology as C, super_temp as P  set C.FKParent_Histology__ID = P.Histology_ID  WHERE concat(P.Histology_Alias, ' - ', C.Histology_Name) = C.Histology_Alias ;
drop table super_temp;


## Fill Pathology
# first extrenal
insert into Pathology ( select '', Anatomic_Site_ID,  Histology_ID, ''  from temp_Pathology, Anatomic_Site , Histology WHERE  Anatomic_Site_Alias = Anatomic_Site__Name aND Histology__Name = Histology_Alias) ;


##
delete from Original_Source_Attribute WHERE FK_Original_Source__ID IN (4550,4553,4559,4718,4719,4725,4948,4949,4950,4957,4958,4960,4962,5313,5324,5325,5326,5327,5341,5342,5343,5344,5345,5346,5348,5349,5350,5523,5524,5525,5629,5632,5634,5735) and FK_Attribute__ID = 28;
delete from Original_Source_Attribute WHERE FK_Original_Source__ID IN (5533,5534,5535,5536) and FK_Attribute__ID = 189;
#
#


## FILL OS_Pathology
insert into temp_OS_Pathology (select distinct  '','', Original_Source_ID, Pathology_Type,'',Patholgy_SubType,'','' ,Primary_Tissue,'', Histology_ID  from Original_Source, Original_Source_Attribute , temp_Transfer, Histology  WHERE (Pathology IS NULL OR Pathology = 'Diseased') and FK_Original_Source__ID = Original_Source_ID and FK_Attribute__ID IN (28,57,189,279) and Attribute_Value = Biologiccal_Condition and temp_Transfer.Histology_Alias = Histology.Histology_Alias);

############# WARNING GOTTA FIX DUPLICATE PROBLEM ###################
# select FK_Original_Source__ID, count(*) , Group_Concat(FK_Pathology__ID) from temp_OS_Pathology Group by FK_Original_Source__ID having count(*)> 1;
#################


update Anatomic_Site, temp_OS_Pathology set FKPrimary_Anatomic_Site__ID = Anatomic_Site_ID  WHERE FKPrimary_Anatomic_Site__ID = 0 and Primary_Tissue <> '' and Primary_Tissue = Anatomic_Site_Alias;


update temp_OS_Pathology, Original_Source set  FKPrimary_Anatomic_Site__ID = FK_Anatomic_Site__ID WHERE temp_OS_Pathology.FK_Original_Source__ID = Original_Source_ID and  FKPrimary_Anatomic_Site__ID = 0;

## FIX AML's
insert into temp_OS_Pathology (select '','',Original_Source_ID, '','','','','','','',''  from Original_Source WHERE FK_Taxonomy__ID = 9606 and (Pathology = 'Diseased' OR Pathology IS NULL)  and Original_Source_ID NOT IN (select FK_Original_Source__ID from temp_OS_Pathology ));

update  temp_OS_Pathology, Original_Source, Histology  set FK_Histology__ID = Histology_ID WHERE FK_Histology__ID = 0 and FK_Original_Source__ID= Original_Source_ID and Original_Source_Name LIKE 'AML%' and Histology_Alias = 'Leukemia - Acute Myeloid' ;





# Setting Anatomic site from tissue table through OS
update temp_OS_Pathology, Original_Source set FKPrimary_Anatomic_Site__ID = FK_Anatomic_Site__ID WHERE FKPrimary_Anatomic_Site__ID = 0 and FK_Original_Source__ID= Original_Source_ID  and FK_Anatomic_Site__ID IS NOT NULL;



#set Anatomic_Sites to their parents
update Anatomic_Site, temp_OS_Pathology set  FKPrimary_Anatomic_Site__ID = FKParent_Anatomic_Site__ID WHERE FKPrimary_Anatomic_Site__ID = Anatomic_Site_ID and Anatomic_Site_Alias LIKE '%-%'  ;
update Anatomic_Site, temp_OS_Pathology set  FKPrimary_Anatomic_Site__ID = FKParent_Anatomic_Site__ID WHERE FKPrimary_Anatomic_Site__ID = Anatomic_Site_ID and Anatomic_Site_Alias LIKE '%-%'  ;
update Anatomic_Site, temp_OS_Pathology set  FKPrimary_Anatomic_Site__ID = FKParent_Anatomic_Site__ID WHERE FKPrimary_Anatomic_Site__ID = Anatomic_Site_ID and Anatomic_Site_Alias LIKE '%-%'  ;
update Anatomic_Site, temp_OS_Pathology set  FKPrimary_Anatomic_Site__ID = FKParent_Anatomic_Site__ID WHERE FKPrimary_Anatomic_Site__ID = Anatomic_Site_ID and Anatomic_Site_Alias LIKE '%-%'  ;

#update temp_OS_Pathology, Original_Source, temp_Tissue, Anatomic_Site set FKPrimary_Anatomic_Site__ID= Anatomic_Site_ID  WHERE FK_Histology__ID <> 0 and FKPrimary_Anatomic_Site__ID = 0 and FK_Original_Source__ID = Original_Source_ID and FK_Tissue__ID = Tissue_ID and Anatomic_Site_Name LIKE '%unknown%' and FK_Cell_Line_Type__ID IS NOT NULL;



update temp_OS_Pathology , Pathology  set  temp_OS_Pathology.FK_Pathology__ID = Pathology_ID   WHERE Pathology.FKPrimary_Anatomic_Site__ID  = temp_OS_Pathology.FKPrimary_Anatomic_Site__ID and Pathology.FK_Histology__ID = temp_OS_Pathology.FK_Histology__ID;

insert into Pathology (select distinct '' ,FKPrimary_Anatomic_Site__ID, FK_Histology__ID,''  from temp_OS_Pathology WHERE FK_Pathology__ID  = 0 and FK_Histology__ID <> 0 and FKPrimary_Anatomic_Site__ID <> 0);

update temp_OS_Pathology , Pathology  set  temp_OS_Pathology.FK_Pathology__ID = Pathology_ID   WHERE Pathology.FKPrimary_Anatomic_Site__ID  = temp_OS_Pathology.FKPrimary_Anatomic_Site__ID and Pathology.FK_Histology__ID = temp_OS_Pathology.FK_Histology__ID;



# Setting Anatomic site from tissue table through OS
#update temp_OS_Pathology, Original_Source, temp_Tissue   set FKPrimary_Anatomic_Site__ID = FK_Anatomic_Site__ID WHERE FKPrimary_Anatomic_Site__ID = 0 and FK_Original_Source__ID= Original_Source_ID and FK_Tissue__ID= Tissue_ID and FK_Anatomic_Site__ID IS NOT NULL;


INSERT INTO Original_Source_Pathology (select Distinct '', FK_Pathology__ID , FK_Original_Source__ID , Pathology_Type ,'', '','', Patholgy_SubType , '', '' from temp_OS_Pathology WHERE FK_Pathology__ID > 0);

## Removing hybrids
delete temp_OS_Pathology  from Hybrid_Original_Source, temp_OS_Pathology WHERE FKChild_Original_Source__ID = FK_Original_Source__ID and FK_Histology__ID = 0;


##  select Original_Source_Name, Tissue_Name, Tissue_Subtype  , Histology_Alias, temp_Tissue.*  from temp_OS_Pathology, Original_Source, temp_Tissue , Histology WHERE FK_Histology__ID = Histology_ID  and FKPrimary_Anatomic_Site__ID = 0 and FK_Original_Source__ID= Original_Source_ID and FK_Tissue__ID= Tissue_ID;

## BLOOD REMAINS


</DATA>


<CODE_BLOCK> 

if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL> 
update Pathology, Anatomic_Site, Histology set  Pathology_Alias = concat(Histology_Alias,' ( ', Anatomic_Site_Alias,' )')   WHERE FKPrimary_Anatomic_Site__ID = Anatomic_Site_ID and FK_Histology__ID = Histology_ID and Pathology_Alias = '';

delete DBField from DBTable, DBField  WHERE DBTable_Name LIKE 'temp\_%' and FK_DBTable__ID= DBTable_ID;
delete from DBTable WHERE DBTable_Name LIKE 'temp\_%';




</FINAL>