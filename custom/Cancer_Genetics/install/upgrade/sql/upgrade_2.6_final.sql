## SQL commands to set DBField, DBTable changes after dbfield_set.pl has been run.
## For example, custom Field_References, Field_Options, and Field Aliases should be set here

UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name = 'FK_Work_Request__ID';

UPDATE DBField SET Field_Options = 'Hidden' WHERE Field_Name IN ('Original_Concentration','Original_Concentration_Units') AND Field_Table = 'Tube';




