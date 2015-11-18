package alDente::Patch;

use Data::Dumper;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;    ## for debugging only ##
use SDB::CustomSettings;
use File::Find;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

###############
sub patch_DB {
###############
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $file = $args{-file};
    my $entry = $args{-entry};
    my $action = $args{-action};
    
    my $fk_dbtable = $entry->{'FK_DBTable__ID'};

    if  (!defined $entry->{'Field_Table'} ) {
        my ($table_name) = $dbc->Table_find('DBTable', 'DBTable_Name', "WHERE DBTable_ID = $fk_dbtable");
        $entry->{'Field_Table'} = $table_name;
    }

    my ($current_version) = $dbc->Table_find( 'Version', 'Version_Name', "WHERE Release_Date < now() ORDER BY Release_Date DESC LIMIT 1" );
    my $patch_dir = "$install_dir/patches/Core/$current_version";

    if ( $action eq 'append' ) {
        return append_patch_file( -file => $file, -patch_dir => $patch_dir, -entry => $entry, -dbc => $dbc );
    }
    elsif ( $action eq 'create' ) {
        return create_patch_file( -file => $file, -patch_dir => $patch_dir, -entry => $entry, -dbc => $dbc );
    }

    return 0;
}


################
sub create_patch_file {
################
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $file = $args{-file};
    my $patch_dir = $args{-patch_dir};
    my $entry = $args{-entry};

    my @sections = ('description', 'schema', 'data', 'code_block', 'final');

    my $path = "$patch_dir/$file";
    open( FILE, ">$path" ) or die "Cannot open file '$path'";
    
    foreach my $section (@sections) {
        print FILE "<". uc($section) . ">\n";
        print FILE prepare_query( -entry => $entry, -section => $section, -dbc => $dbc );
        print FILE "</" . uc($section) . ">\n";
    }

    close( FILE );

    return 1;
}

################
sub append_patch_file {
################
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $file = $args{-file};
    my $patch_dir = $args{-patch_dir};
    my $entry = $args{-entry};

    my $input_path = "$patch_dir/$file";
    my $output_path = "$patch_dir/tmp";

    open( INFILE, $input_path ) or die "Cannot find file '$input_path'";
    open( OUTFILE, ">$output_path" ) or die "Cannot open file '$output_path'";

    while ( <INFILE> ) {
        if ( /<(\w+)>/ ) {
            my $section = lc($1);
            $_ .= prepare_query( -entry => $entry, -section => $section, -dbc => $dbc );
        }

        print OUTFILE $_;
    }

    rename( $output_path, $input_path );

    return 1;
}

################
sub prepare_query {
################
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $entry = $args{-entry};
    my $section = $args{-section};

    my $query;

    my @schema_attr = ('DBField_ID', 'FK_DBTable__ID', 'Field_Table', 'NULL_ok', 'Field_Name', 'Field_Default');

    my $table      = $entry->{'Field_Table'};
    my $field_name = $entry->{'Field_Name'};
    my $field_type = $entry->{'Field_Type'};
    my $field_default = $entry->{'Field_Default'};
        
    if ( $section eq 'schema' ) {
        $query  = "ALTER TABLE $table ADD $field_name $field_type";
        $query .= " DEFAULT $field_default" if $field_default;
        $query .= " NOT NULL" if ( $entry->{'NULL_ok'} eq 'NO' );
        $query .= "\n";
    }
    elsif ( $section eq 'final' ) {
        my %output = $dbc->Table_retrieve('DBField', ['Field_Name', 'Field_Default'], "WHERE Field_Table = 'DBField'");
        my %defaults;
        @defaults{@{$output{'Field_Name'}}} = @{$output{'Field_Default'}};

        $query = "UPDATE DBField SET ";
        while( my ($field, $value) = each(%$entry) ) {
            if (! grep /^$field$/, @schema_attr and $value ne $defaults{$field} ) {
                $query .= "$field = '$value',";
            }
        }

        chop $query;
        $query .= " WHERE Field_Table = '$table' AND Field_Name = '$field_name'\n";
    }

    return $query;
}

################
sub get_available_patches {
################
    my %args = filter_input( \@_ );
    my $dbc = $args{-dbc};

    my ($current_version) = $dbc->Table_find( 'Version', 'Version_Name', "WHERE Release_Date < now() ORDER BY Release_Date DESC LIMIT 1" );
    my $patch_dir = "$install_dir/patches/Core/$current_version";

    my @patches;

    find sub {if ( ( -f $_ ) && ( my $tmp = $_ ) && ( $_ =~ s/.pat$// ) ) { push @patches, $_ }}, $patch_dir;
    return @patches;
}
1;
