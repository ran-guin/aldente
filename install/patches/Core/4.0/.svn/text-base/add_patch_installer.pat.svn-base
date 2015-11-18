## Patch file to modify a database

<DESCRIPTION> ## Put a sentence or two here about what this patch changes in the database

LIMS-11231 - add db user 'patch_installer' for installing patches to test database 

</DESCRIPTION>
<SCHEMA> ## Put SQL statements here that change the structure of databases (ALTER, ADD, DROP, MODIFY)
</SCHEMA>

<DATA> ## Put statements here that change or add data to the database. These statements will be executed after the schema statements above (INSERT, UPDATE)

INSERT INTO DB_Login (DB_User, DB_Access_Level, DB_Login_Description) values ('patch_installer',2,'used for installing patches to test database');

</DATA>

<CODE_BLOCK> 
## This block of code will be executed after all of the above SQL statements are executed;
## Assume you have an active database connection object (SDB::DBIO) by the name $dbc;
## Also, assume the script is using RGTools::RGIO. 
## There are more perl modules that are included with the script; for  a full list, please look at the header file (header.pl)
## If you need to use additional modules, just enter the appropriate use statements in the block
## Name the block of code below
if (_check_block('new_users')) { 

    use SDB::DB_Access;
    
    print "*** Add DB user 'patch_installer' to mysql database (and append to login file) ***\n";

    my ($s, $i, $u, $d, $create, $drop, $alter); 
   	if( $dbc->{dbase} eq 'seqdev' ) {	# give create/drop/alter table privileges on seqdev
		($s, $i, $u, $d, $create, $drop, $alter) = ('Y','Y','Y','Y', 'Y','Y','Y');  ### default to full privileges for now...
   	}
   	else {
		($s, $i, $u, $d, $create, $drop, $alter) = ('Y','Y','Y','Y', 'N','N','N'); 
   	}
	
    my $login_file = "$Configs{Home_dir}/versions/$Configs{version_name}/conf/mysql.login";
    SDB::DB_Access::add_DB_user(-db_user=>'patch_installer', -password=>rand(1000), -privileges=>[$s,$i,$u,$d,$create,$drop,$alter],-append_login_file=>$login_file, -dbc=>$dbc);
}

</CODE_BLOCK>
<FINAL> ## Put statements here that change existing entries in DBField or DBTable. These statements will be executed after all tables and fields in those tables have been refreshed (via dbfield_set.pl)


</FINAL>
