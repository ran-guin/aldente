## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

LIMS-8011, Enable cascading goal definitions
- add table for a subgoal relation
- add field for goal to differentiate between a broad goal or specific goal


</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
</SCHEMA>
<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

/*Add records for broad goals - no association yet with specific goals*/
INSERT INTO Goal (Goal_Name, Goal_Type, Goal_Scope)
	SELECT CONCAT('# of ', Library_Strategy_Name, ' Libraries to construct') as Goal_Name,  'Lab Work', 'Broad'
	FROM Library_Strategy 
	WHERE Library_Strategy_Name IN ('AMPLICON','Bisulfite_Seq','ChIP-Seq','Dnase-Hypersensitivity','EXC_Seq','EXT_Seq','MeDIP-Seq','miRNA_Seq','Mnase-Seq','MRE_Seq','RNA_Seq','SPC','WGS')
UNION
	SELECT '# of HiSeq Lanes to Sequence per Sample (library)', 'Lab Work', 'Broad';
	
/* Add work request types for solexa sequencing*/
INSERT INTO Work_Request_Type (Work_Request_Type_Name, Work_Request_Type_Status)
SELECT 'SE 36 bp', 'Active'
UNION
SELECT 'SE 50 bp', 'Active'
UNION
SELECT 'SE 75 bp', 'Active'
UNION
SELECT 'SE 100 bp', 'Active'
UNION
SELECT 'PET 50 bp',  'Active'
UNION
SELECT 'PET 75 bp',  'Active'
UNION
SELECT 'PET 100 bp',  'Active'
UNION
SELECT 'PET 150 bp',  'Active'
UNION
SELECT 'MPET 100 bp', 'Active'
UNION
SELECT 'MPET 150 bp', 'Active';

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
