## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
# Add attribute to DBField to help the submission process involving attributes

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

### Add Attribute to DBField ###
#alter table DBField modify Field_Scope enum('Core','Optional','Custom','Attribute') NULL default 'Custom';


</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)


</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('Add_Attribute_To_DBField')) { 
    return 1;		
    my @attributes = (
'Sample_Common_Name',
'Biological_Condition',
'Biomaterial_Provider',
'Biomaterial_Type',
'Lineage',
'Cellular_Condition',
'Differentiation_Method',
'Passage',
'Medium',
'Original_Source_Cell_Type',
'Markers',
'Donor_ID',
'Donor_Age',
'Donor_Health_Status',
'Donor_Ethnicity',
'Tissue_Type',
'Tissue_Depot',
'Collection_Method'
                      );

    my $debug = 0;

    for my $attribute (@attributes) {
        print "$attribute\n" if $debug;
        my ($attribute_info) = $dbc->Table_find('Attribute,DBTable','Attribute_ID,DBTable_ID,DBTable_Name',"WHERE Attribute_Name = '$attribute' and DBTable_Name = Attribute_Class");
        my ($attribute_ID, $table_id, $table_name) = split (/,/,$attribute_info);
	if (!$attribute_ID) { next; }
        print "$attribute_ID\t$table_id\n" if $debug;
        my $prompt = $attribute;
        my $alias = $attribute;
        my $options = '';
        my $ref = '';
        my ($order) = $dbc->Table_find('DBField','Field_Order+1',"DBField where FK_DBTable__ID = $table_id order by Field_Order desc limit 1");
        print "$order\n" if $debug;
        my $type = "varchar(40)";
        my $null_ok = "YES";
        my $fk = '';
        my $field_size = 40;
        my $field_scope = 'Attribute';

        my $new_dbfield_id = &Table_append_array($dbc,'DBField',
                                     ['Field_Name','FK_DBTable__ID','Prompt','Field_Alias','Field_Options','Field_Reference','Field_Order','Field_Type','NULL_ok','Foreign_Key','Field_table','Field_Size','Field_Scope'],
                                     [$attribute,$table_id,$prompt,$alias,$options,$ref,$order,$type,$null_ok,$fk,$table_name,$field_size,$field_scope],-autoquote=>1,-debug=>$debug);
        my $new_field_map = &Table_append_array($dbc,'Field_Map',
                                     ['FK_Attribute__ID','FKTarget_DBField__ID'],
                                     [$attribute_ID, $new_dbfield_id],
                                                -autoquote=>1,-debug=>$debug
                                                );
    }



}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

</FINAL>
