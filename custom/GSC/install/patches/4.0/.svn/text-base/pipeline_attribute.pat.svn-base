## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database
Create Attributes and Attribute table for Pipeline, immediate purpose is to tie Pipeline with Goal, inferred purpose is for linking Run_Analysis and associated Invoicing tables with Work_Request's Funding_ID
</DESCRIPTION>

<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
CREATE TABLE `Pipeline_Attribute` (
  `Pipeline_Attribute_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FK_Pipeline__ID` int(11) NOT NULL DEFAULT '0',
  `FK_Attribute__ID` int(11) NOT NULL DEFAULT '0',
  `Attribute_Value` int(11) NOT NULL,
  PRIMARY KEY (`Pipeline_Attribute_ID`),
  UNIQUE KEY `FK_Attribute__ID_2` (`FK_Attribute__ID`,`FK_Pipeline__ID`),
  KEY `FK_Pipeline__ID` (`FK_Pipeline__ID`),
  KEY `FK_Attribute__ID` (`FK_Attribute__ID`)
);
</SCHEMA>

<DATA> 
insert into Attribute (Attribute_Name, Attribute_Type, FK_Grp__ID, Attribute_Class) VALUES ('Pipeline_FK_Goal__ID','FK_Goal__ID','1','Pipeline');

</DATA>

<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the bl of code below

my %info = $dbc->Table_retrieve("Goal",['Goal_ID', 'Goal_Condition'],"where Goal_Condition like '%Pipeline_Name%' and Goal_Type = 'Data Analysis'");

my ($attribute_id) = $dbc->Table_find("Attribute","Attribute_ID","Where Attribute_Name = 'Pipeline_FK_Goal__ID'");
my @Pipeline_Names;
my $count = 0;
foreach my $cond (@{$info{Goal_Condition}}){
	$cond =~ /Pipeline_Name = \'(.*)\' and Run_Analysis/;
	#print "$count  $1";	
	#print "\n\n\n";	
	my $temp = $1;
	push @{$info{Pipeline_Name}}, $temp;
	my ($pipeline_id) = $dbc->Table_find("Pipeline","Pipeline_ID","Where Pipeline_Name = '$temp'");
	push @{$info{Pipeline_ID}}, $pipeline_id;
	


my @fields = ("FK_Pipeline__ID","FK_Attribute__ID","Attribute_Value");
my @values = ($info{Pipeline_ID}->[$count] , $attribute_id , $info{Goal_ID}->[$count]);
$dbc->Table_append_array("Pipeline_Attribute", \@fields, \@values);
$count++;
}

</CODE_BLOCK>

<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)
</FINAL>
