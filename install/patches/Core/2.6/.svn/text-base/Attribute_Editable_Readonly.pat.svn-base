## Patch file to modify a database

<DESCRIPTION>

</DESCRIPTION>
<SCHEMA> 

ALTER TABLE Attribute ADD Attribute_Access enum('Editable','NonEditable','ReadOnly') DEFAULT 'Editable';

</SCHEMA>
<DATA>

UPDATE Attribute set Attribute_Access = 'ReadOnly' WHERE Attribute_Name IN ('Replacement_for_Source','Replacement_Source_Status');
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
<FINAL>

</FINAL>
