#!/usr/local/bin/perl

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::HTML_Table;

use vars qw($opt_help $opt_quiet);

use Getopt::Long;
&GetOptions(
    'help'  => $opt_help,
    'quiet' => $opt_quiet,
    ## 'parameter_with_value=s' => \$opt_p1,
    ## 'parameter_as_flag'      => \$opt_p2,
);

my $help  = $opt_help;
my $quiet = $opt_quiet;

my $host = 'lims01';

#my $dbase = 'alDente_unit_test_DB';
my $dbase = 'seqdev';
my $user  = 'viewer';
my $pwd   = 'viewer';

my $path = "/opt/alDente/www/htdocs/docs/Table_descriptions";

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my %table_details = $dbc->Table_retrieve(
    'DBTable,DBField',
    [ 'DBTable_Name', 'Field_Name', 'DBTable_Title', 'Prompt', 'Field_Description', 'DBTable_Description', 'Field_Type', 'Field_Format', 'Field_Options' ],
    "WHERE FK_DBTable__ID=DBTable_ID ORDER BY DBTable_Name, Prompt"
);

my %Tables;
my %Mandatory;
my %Hidden;
my %Rows;
my $i = 0;
while ( defined $table_details{DBTable_Name}[$i] ) {
    my $table      = $table_details{DBTable_Name}[$i];
    my $title      = $table_details{DBTable_Title}[$i];
    my $table_desc = $table_details{DBTable_Description}[$i];
    my $field      = $table_details{Prompt}[$i];
    my $desc       = $table_details{Field_Description}[$i];
    my $type       = $table_details{Field_Type}[$i];
    my $mandatory  = $table_details{Field_Options}[$i] =~ /Mandatory/;
    my $hidden     = $table_details{Field_Options}[$i] =~ /(Hidden|Obsolete|Removed)/;
    my $format     = $table_details{Field_Format}[$i];
    push @{ $Rows{$table} }, [ $field, $type, $desc, $format ];
    $Tables{$table}             = "<H1>$title</H1>\n<H3>$table_desc</H3>\n<I>Mandatory fields highlighted in red</I>\n";
    $Mandatory{"$table.$field"} = $mandatory;
    $Hidden{"$table.$field"}    = $hidden;
    $i++;
}

foreach my $table ( keys %Rows ) {
    open my $OUT, ">$path/$table.html" or die "Cannot open $path/$table.html";
    my $HTML = new HTML_Table();
    $HTML->Set_Headers( [ 'Attribute/Field', 'Type', 'Description', 'Format (REGEXP)' ] );
    print "Table: $table\n$Tables{$table}\n";
    foreach my $row ( @{ $Rows{$table} } ) {
        my $colour;
        if ( $Hidden{"$table.$row->[0]"} ) {next}
        if ( $Mandatory{"$table.$row->[0]"} ) { $colour = 'bgcolor=#FF9999' }
        $HTML->Set_Row( $row, $colour );
        print join "\t", @{$row};
        print "\n";
    }
    print {$OUT} $Tables{$table};
    print {$OUT} $HTML->Printout(0);
    close $OUT;
    print "*** Generated $table table ***\n";
}

exit;

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    <script> [options]

Mandatory Input:
**************************

Options:
**************************     


Examples:
***********

HELP

}
