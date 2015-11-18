## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)

UPDATE Protocol_Step set Protocol_Step_Name = Replace(Protocol_Step_Name,'to cryovial','to 2 ml cryovial') where Protocol_Step_Name like '%to cryovial';
UPDATE Protocol_Step set Protocol_Step_Name = Replace(Protocol_Step_Name,'to Conical Tube','to 50 ml Conical Tube') where Protocol_Step_Name like '%to Conical Tube';

</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)
INSERT INTO DB_Trigger VALUES ("","Maintenance","Perl","require alDente::Equipment; my $ok = alDente::Equipment::new_maintenance_trigger(-dbc=>$self,-maintenance_id=><ID>); return 1;" ,"insert", "Active" ," ", "No ", "");
INSERT INTO DB_Trigger VALUES ("","Pipeline_Step","Perl","require alDente::Pipeline; my $ok = alDente::Pipeline::pipeline_step_trigger(-dbc=>$self,-pipeline_step_id=><ID>); ", "insert"     , "Active" , ""  , "Yes"   , "");
INSERT INTO DB_Trigger VALUES ("","Maintenance_Schedule ","Perl", "require alDente::Equipment; print alDente::Equipment::scheduled_maintenance(-dbc=>$self,-return_html=>1); return 1;", "insert"   , "Active" ," " , "No", "");
INSERT INTO DB_Trigger VALUES ("","Plate_Schedule","Method","plate_schedule_trigger", "insert", "Active" ,"  ", "Yes ", "");
INSERT INTO DB_Trigger VALUES ("","Plate_Attribute","Perl","require alDente::Container; alDente::Container::Plate_Attribute_trigger(-dbc=>$self,-id=><ID>);", "insert" ,"Active" , "" , "No", "");
INSERT INTO DB_Trigger VALUES ("","Work_Request", "Perl","require alDente::Goal; my $ok =alDente::Goal::set_Library_Status(-dbc=>$self,-work_request=><ID>);", "insert", "Active" ," " , "No"    , "");
INSERT INTO DB_Trigger VALUES ("","Library_Source", "Perl","require alDente::Source; my $ok = alDente::Source::new_library_source_trigger(-dbc=>$self,-id=><ID>);"                           , "insert"     , "Active" ," " , "Yes","");
INSERT INTO DB_Trigger VALUES ("","LibraryApplication","Perl","require alDente::Library; my $ok = alDente::Library::new_library_assoc_trigger(-dbc=>$self,-id=><ID>);","insert","Active","  ", "No","");
INSERT INTO DB_Trigger VALUES ("","Work_Request","Method","new_work_request_trigger" , "insert", "Active" ," " ,"No", "");
INSERT INTO DB_Trigger VALUES ("","Employee","Method","new_Employee_trigger" , "insert", "Active" , "" , "No", "");           
INSERT INTO DB_Trigger VALUES ("","Plate","Perl", "require alDente::Container; my $ok = alDente::Container::plate_QC_trigger(-dbc=>$self,-id=>$id);", "update", "Active" ,""  ,"No", "QC_Status");  
INSERT INTO DB_Trigger VALUES ("","Library","Method","update_Status_trigger", "update" ,"Active" ,"" , "No", "Library_Status");
INSERT INTO DB_Trigger VALUES ("","Equipment","Perl","require alDente::Equipment; my $ok = alDente::Equipment::new_Equipment_trigger(-dbc=>$self,-id=><ID>);", "insert", "Active" ," " , "No" , "");
INSERT INTO DB_Trigger VALUES ("","Change_History","Perl","require alDente::Rack; alDente::Rack::rack_change_history_trigger(-dbc=>$self,-change_history_id=><ID>);", "insert", "Active" , "" ,"No", "");    
</DATA>


<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below

</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)

</FINAL>
