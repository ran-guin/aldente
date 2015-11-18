#!/usr/local/bin/perl

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;

use SDB::Installation;

use vars qw($opt_help $opt_quiet $opt_schema $opt_data $opt_bin $opt_final $opt_name $opt_force);

use Getopt::Long;
&GetOptions(
	    'help'                  => \$opt_help,
	    'quiet'                 => \$opt_quiet,
	    'schema=s'                  => \$opt_schema,
	    'data=s'                    => \$opt_data,
	    'bin=s'                     => \$opt_bin,
	    'final=s'                   => \$opt_final,
	    'name=s'                    => \$opt_name,
	    'force'                     => \$opt_force,
	    ## 'parameter_with_value=s' => \$opt_p1,
	    ## 'parameter_as_flag'      => \$opt_p2,
	    );

my $help  = $opt_help;
my $quiet = $opt_quiet;
my $force = $opt_force;

if ($help) {
    help();
    exit;
}

Message "**********************";
Message "Welcome to Patch Gen";
Message "**********************";
Message "Why use Patch Gen?";
Message "Simple: to consolidate your sql schema, data, code, and final files all into a single file";
Message "**********************";

main();

#
#
############
sub main {  
############      
    my $schema_path = $opt_schema || Prompt_Input(-prompt=>'Enter the path for the schema-changing sql file');
    my $data_path = $opt_data || Prompt_Input(-prompt=>'Enter the path for the data-changing sql file');
    my $bin_path = $opt_bin || Prompt_Input(-prompt=>'Enter the path for the bin-file');
    my $final_path = $opt_final || Prompt_Input(-prompt=>'Enter the path for the finalization sql file (changing dbfield and dbtable records)');    

    my $patch_info = {};
    $patch_info->{schema}{tag} = 'SCHEMA';
    $patch_info->{data}{tag} = 'DATA';
    $patch_info->{bin}{tag} = 'CODE_BLOCK';
    $patch_info->{final}{tag} = 'FINAL';

    $patch_info->{schema}{file} = $schema_path;
    $patch_info->{data}{file} = $data_path;
    $patch_info->{bin}{file} = $bin_path;
    $patch_info->{final}{file} = $final_path;

    my $new_file = $opt_name || Prompt_Input(-prompt=>'Enter the full path of the target filename for the new patch');
    
    open(PATCH,">$new_file") or die "Unable to open new patch file for write"; 
    Message "Generating new patch file: $new_file";

    foreach my $key ('schema','data','bin','final') {
	if (-f "$patch_info->{$key}{file}") {
	    Message "Writing lines to new patch file from: $patch_info->{$key}{file}";
	    my $FILE;
	    open ($FILE,"<$patch_info->{$key}{file}");
	    print PATCH '<',"$patch_info->{$key}{tag}",">\n";
	    foreach my $line (<$FILE>) {
		print PATCH "$line";
	    }
	    close $FILE;
	    print PATCH "\n</"."$patch_info->{$key}{tag}".">\n";
	    Message "Wrote $key block of new patch file";
	}
    }
}

exit;

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    <script> [options]
    patch_gen.pl [-schema <schema_sql_file> -data <data_sql_file> -bin <bin_file> -final <final_sql_file> -name <name>]


Mandatory Input:
**************************

Options:
**************************     
-schema ## full path to schema sql file
-data ## full path to data sql file
-bin ## full path binary file
-final ## full path to finalizing sql file (to be run after dbfield set)
-name ## full path of newly generated patch file

Examples:
***********

## Pass all files in through command line
patch_gen.pl -schema '/path/to/schema_file.sql' -data '/path/to/data_file.sql' -bin '/folder/to/bin/bin.pl' -final '/path/to/final_sql.sql' -name '/path/to/new_file.pat'

## To get prompted for all file paths
patch_gen.pl


HELP

}
