$dbc->disconnect();
exit;

#########################
sub _execute_sql {
#########################
    my $sql = shift;

    print "\nExecuting '$sql'...(" . now() . ")\n";
    my $rows = $dbc->dbh()->do(qq{$sql});

    if (!$rows) {
        print "*** ERROR executing SQL: $DBI::err ($DBI::errstr)(" . now() . ").\n";
    }
    else {
        $rows += 0;
        print "--- Executed SQL successfully ($rows row(s) affected)(" . now() . ").\n";
    }

    #Returns the number of rows affected and also the newly created primary key ID.
    return ($rows,$dbc->dbh()->{'mysql_insertid'});
}

##########################
sub _set_DB {
##########################
    my $tables = shift;

    if ($tables) {$tables = "-T $tables"}
    my $cmd = "$FindBin::RealBin/../../../bin/upgrade_DB.pl -D $host:$Dbase -A set $tables -u $user -p $password";
    print "\n>>>Trying command '$cmd'...\n";
    print try_system_command($cmd);
}

############################################
# Check whether to execute the current block
############################################
sub _check_block {
    my $block = shift;
    my $ret;

    if ( (grep /^all$/i, @include_blocks) && !(grep /^$block$/i, @exclude_blocks) ) { # Run all blocks EXCEPT excluded blocks
	print ">>>>> Executing block '$block'. (" . now() . ")\n";
	$ret = 1;
    }
    elsif (@exclude_blocks and (grep /^$block$/i, @exclude_blocks)) { # Skip this block if it is in the exclusion list
	print ">>>>> Skipping block '$block'.\n";
	$ret = 0;
    }
    elsif (@include_blocks and !(grep /^$block$/i, @include_blocks)) { # Skip this block unless it is included in the inclusion list
	print ">>>>> Skipping block '$block'.\n";
	$ret = 0;
    }
    else { # Include this block
	print ">>>>> Executing block '$block'. (" . now() . ")\n";
	$ret = 1;
    }
    
    return $ret;
}
