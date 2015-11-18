#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Long;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::CustomSettings;
use alDente::Data_Submission_Config;

use vars qw( %Configs $opt_help $opt_name $opt_path $opt_xml $opt_type $opt_target);


&GetOptions(
    	'help|h|?'     => \$opt_help,
        'name|n=s'				=> \$opt_name,
        'path|p=s'				=> \$opt_path,
        'xml_path|x=s'			=> \$opt_xml,
        'type=s'					=> \$opt_type,
        'target=s'				=> \$opt_target,
);

my $help           = $opt_help;
my $name = $opt_name;
my $path = $opt_path || $Configs{data_submission_config_dir};
my $xml_path = $opt_xml || "$Configs{data_submission_config_dir}/xml_templates";
my $type = lc($opt_type) || 'all';
my $target = $opt_target;

my $data_submission_config_obj = new alDente::Data_Submission_Config( -target=>$target, -name=>$name, -path=>$path, -source_xml_template_path=>$xml_path );
$data_submission_config_obj->create_config( -type=>$type );
print "configs generated!\n";

##################
sub display_help {
##################
    print <<HELP;

Syntax
======
generate_data_submission_config.pl - This script generates the config file for data submission.

Arguments:
=====

-- required arguments --
-name			: the name of the template
-path			: the directory where the specified template will be created
-xml_path		: the directory where the source xml templates are
-type			: the data submission object type ( one of 'study', 'sample', 'experiment', 'run', 'analysis' ). If this argument is not given, the default is all object types.
-target			: the data submission target organization

-- optional arguments --
-help, -h, -?		: displays this help. (optional)

Example
=======
generate_data_submission_config.pl -name EDACC_ChIP_Seq -type experiment -target EDACC 
generate_data_submission_config.pl -name EDACC_MeDIP_Seq_1.4.3 -target EDACC
generate_data_submission_config.pl -name NCBI_RNAseq_EZH2 -type analysis -target NCBI

HELP

}
