## Patch file to modify a database

<DESCRIPTION>

</DESCRIPTION>
<SCHEMA> 
</SCHEMA>
<DATA>

</DATA>
<CODE_BLOCK> 
if (1) { 
	my $ok 				= $dbc -> Table_append_array("Department",['Department_Name','Department_Status'],['Prostate_Lab','Active'],-autoquote=> 1);
	my ($department_id) = $dbc -> Table_find ('Department','Max(Department_ID)',' WHERE 1');
	my $ok 				= $dbc -> Table_append_array("Grp",['Grp_Name','FK_Department__ID','Access','Grp_Status'],['Prostate_Lab',$department_id,'Lab','Active'],-autoquote=> 1);

}

</CODE_BLOCK>
<FINAL> 


</FINAL>
