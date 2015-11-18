<DESCRIPTION> 
</DESCRIPTION> 
<SCHEMA>  
alter table Parameter modify Parameter_Type enum('Static','Multiple','Variable','User_Define','Hidden') default NULL;
update Parameter set Parameter_Type = 'User_Define' where Parameter_Type = 'Variable';
alter table Parameter modify Parameter_Type enum('Static','Multiple','User_Define','Hidden') default NULL;
alter table Parameter modify Parameter_Value varchar(40) NULL default NULL;
</SCHEMA>  
<DATA> 
</DATA> 
<FINAL> 
</FINAL> 
