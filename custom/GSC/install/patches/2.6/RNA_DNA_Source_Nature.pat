<DESCRIPTION>
 This patch is for change enum value of RNA_DNA_Source.Nature and add sample type 'aRNA'
</DESCRIPTION>
<SCHEMA>
alter table RNA_DNA_Source modify Nature enum('','Total RNA','mRNA','Tissue','Cells','RNA - DNase Treated','cDNA','1st strand cDNA','Amplified cDNA','Ditag','Concatemer - Insert','Concatemer - Cloned','DNA','labeled cRNA','aRNA') NULL default NULL;
</SCHEMA>
<DATA>
update DBField set Field_Type= "enum('','Total RNA','mRNA','Tissue','Cells','RNA - DNase Treated','cDNA','1st strand cDNA','Amplified cDNA','Ditag','Concatemer - Insert','Concatemer - Cloned','DNA','labeled cRNA','aRNA')" WHERE Field_Table = 'RNA_DNA_Source' and Field_Name = 'Nature';

insert into Sample_Type (Sample_Type) Value ('aRNA');
</DATA>
<FINAL>



</FINAL>
