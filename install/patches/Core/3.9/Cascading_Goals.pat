## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

LIMS-8011, Enable cascading goal definitions
- add table for a subgoal relation
- add field for goal to differentiate between a broad goal or specific goal


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE Sub_Goal( 
	Sub_Goal_ID INT NOT NULL Auto_Increment, 
	FKBroad_Goal__ID INT NOT NULL, 
	FKSub_Goal__ID INT NOT NULL, 
	Sub_Goal_Type ENUM('Mandatory','Optional') DEFAULT 'Mandatory' NOT NULL,
	Sub_Goal_Count INT,
	PRIMARY KEY (Sub_Goal_ID),
	KEY (FKBroad_Goal__ID),
	KEY (FKSub_Goal__ID)
);

ALTER TABLE Goal 
ADD Goal_Scope ENUM('Broad','Specific') NOT NULL DEFAULT 'Specific';

</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

ALTER TABLE Work_Request MODIFY Num_Plates_Submitted ENUM("0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96");

UPDATE DB_Form SET Parent_Field = 'Num_Plates_Submitted', Parent_Value = '>0' WHERE Form_Table like 'Material_Transfer';
#
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
update DBField set Prompt = 'Num Containers Submitted' where Field_Table = 'Work_Request' and Field_Name = 'Num_Plates_Submitted';

</FINAL>
