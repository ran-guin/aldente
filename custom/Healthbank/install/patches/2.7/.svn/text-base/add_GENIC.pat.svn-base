## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

ALTER TABLE Source MODIFY COLUMN Source_Type ENUM('Mixed','Tissue','Cells','Whole Blood','Blood Serum','Blood Plasma','Red Blood Cells','White Blood Cells','Urine','Saliva','RBC+WBC');

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
insert into Department values ('','GENIC','Active');
insert into Project (Project_Name, Project_Status) values ('GENIC','Active');

insert into Grp select '','GENIC Lab',Department_ID,'Lab','Lab','Active' from Department where Department_name = 'GENIC';
insert into Grp select '','GENIC Lab Admin',Department_ID,'Admin','Lab Admin','Active' from Department where Department_name = 'GENIC';
insert into Grp_Relationship select '',Min(Grp_ID),Max(Grp_ID) from Grp where Grp_Name like 'GENIC %';

update Grp set Grp_Name = CONCAT('BCG ',Grp_Name) where Grp_Name like 'Lab%';

insert into Attribute values ('','Picogreen DNA Quant (ng/uL)','','Decimal','7','Yes','Plate','Editable');
insert into Library (Library_Name, FK_Project__ID, External_Library_Name, Library_FullName, Library_Status, FK_Grp__ID, FK_Original_Source__ID) select 'SHE',Project_ID,'LIB002','Multiple Myeloma Samples (Skin Health and Environment Study)', 'In Production', Grp_ID, '1' from Grp,Project where Grp_Name = 'GENIC Lab' AND Project_Name = 'GENIC';

insert into Attribute values ('','Picogreen DNA Quant (ng/uL)','','Decimal','7','Yes','Plate','Editable');

</DATA>
<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('FORMATS')) {
    my %sample_types = ('T06' => 
                        {'Sample' => 'EDTA (6 mL) RBC+WBC Tube',
                         'Volume' => '6',
                         'Code' => 'RW6',
                         'Protocol' => 'EDTA RBC WBC Protocol, Sucrose Extraction' 
                        },
                    'T07' =>
                        {'Sample' => 'EDTA (6 mL) Tube',
                         'Volume' => '6',
                         'Code' => 'ED6',
                         'Protocol' => 'EDTA 6 ml Extraction Protocol'
                        },
                    'T09' =>
                        {'Sample' => 'EDTA Plasma Tube',
                         'Volume' => '6',
                         'Code' => 'PMA',
                         'Protocol' => 'Weigh Tube'
                        },
                    'T10' =>
                        {'Sample' => 'Frozen Red Top Serum Tube',
                         'Volume' => '6',
                         'Code' => 'SER',
                         'Protocol' => 'Weigh Tube',
                        },
                    'T11' =>
                        {'Sample' => 'EDTA (4 mL) RBC+WBC Tube',
                         'Volume' => '4',
                         'Code' => 'RW4',
                         'Protocol' => 'EDTA RBC WBC Protocol, Sucrose Extraction'
                        },
                    'T12' =>
                        {'Sample' => 'EDTA (4 mL) Tube',
                         'Volume' => '4',
                         'Code' => 'ED4',
                         'Protocol' => 'EDTA 4 ml Extraction Protocol' 
                        },
                    'T14' =>
                        {'Sample' => 'Saliva Cup',
                         'Volume' => '100',
                         'Code' => 'SAL',
                         'Protocol' => 'Saliva DNA Extraction'
                        }
                   );

    my ($protocol_class) = $dbc->Table_find('Object_Class','Object_Class_ID',"WHERE Object_Class = 'Lab_Protocol'");

    foreach my $format (sort keys %sample_types) {
        my $sample = $sample_types{$format}{Sample};
        my ($format_id) = $dbc->Table_find('Plate_Format','Plate_Format_ID',"WHERE Plate_Format_Type = '$sample'");
        $format_id ||= $dbc->Table_append_array(
                -table => 'Plate_Format', 
                -fields => ['Plate_Format_Type', 'Plate_Format_Status', 'FK_Barcode_Label__ID', 'Max_Row', 'Max_Col', 'Plate_Format_Style', 'Well_Capacity_mL', 'Capacity_Units', 'Wells', 'Well_Lookup_Key'], 
                -values => [$sample, 'Active', 36, 'A', 1, 'Tube', $sample_types{$format}{Volume}, 'ml', 1, ''], 
                -autoquote => 1);
        
        my ($grp_id) = $dbc->Table_find('Grp','Grp_ID',"WHERE Grp_Name = 'GENIC Lab'");
        my ($public_id) = $dbc->Table_find('Grp','Grp_ID',"WHERE Grp_Name = 'Public'");
        my ($pipeline_id) = $dbc->Table_find('Pipeline','Pipeline_ID',"WHERE Pipeline_Name = '$sample Prep'");
        
        my $ref_grp = $grp_id;
        if ($sample_types{$format}{Sample} =~ /(Saliva)/) { $ref_grp = $public_id }  ## make Saliva extraction public... 
        
        $pipeline_id ||= $dbc->Table_append_array(
                -table => 'Pipeline',
                -fields => ['Pipeline_Name', 'Pipeline_Description', 'Pipeline_Code', 'Pipeline_Status', 'FKApplicable_Plate_Format__ID','FK_Grp__ID'], 
                -values => [$sample . ' Prep', 'Handling of '.$sample_types{$format}{Sample}, $sample_types{$format}{Code}, 'Active', $format_id,$ref_grp],
                -autoquote => 1);
        
        
        my $protocol = $sample_types{$format}{Protocol};
        my @protocols = split ', ', $protocol;
        my $index = 1;
        foreach my $prot (@protocols) {
            my ($protocol_id) = $dbc->Table_find('Lab_Protocol','Lab_Protocol_ID',"WHERE Lab_Protocol_Name = '$prot'");
            if (!$protocol_id) { $dbc->warning("$prot NOT DEFINED"); next; }

            $dbc->Table_append_array(
                -table => 'Pipeline_Step',
                -fields=> ['FK_Object_Class__ID','Object_ID','Pipeline_Step_Order','FK_Pipeline__ID'],
                -values=> [$protocol_class, $protocol_id, $index, $pipeline_id],
                -autoquote=>1);
            $index++;
        }
    }

}
</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

update DBField set Field_Reference = "Concat(Sample_Type.Sample_Type,'-',External_Identifier)" WHERE Field_Name = 'Source_ID';

</FINAL>
