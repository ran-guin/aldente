## Patch file to modify a database

<DESCRIPTION> 









</DESCRIPTION>
<SCHEMA> 



ALTER TABLE Shipment MODIFY Shipment_Type  enum('Internal','Import','Export','Roundtrip') DEFAULT NULL;

</SCHEMA>
<DATA> 

</DATA>
<CODE_BLOCK> 
if (_check_block('NAME_GOES_HERE')) { 
		


}
</CODE_BLOCK>
<FINAL>

UPDATE DBField set Field_Type = "enum('Internal','Import','Export','Roundtrip')" , Editable = 'no' WHERE Field_Table = 'Shipment' and Field_Name = 'Shipment_Type';

</FINAL>
