#!/usr/local/bin/perl

#!/gsc/software/cluster/perl-illumina-5.10/bin/perl

use DBI;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Benchmark;

use FindBin;

use RGTools::RGIO;
use SDB::DBIO;
use alDente::Container;
use alDente::Data_Fix;

use Sequencing::Sequencing_API;

use vars qw(%Benchmark);

my $dbase = 'seqtest';
my $user  = 'super_cron';
my $pwd;
my $host = 'lims05';
my $dbc  = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

$dbc->set_local( 'user_id', 4 );
my $debug = 0;

my $API = Sequencing_API->new( -dbase => $dbase, -host => $host, -DB_password => $pwd, -DB_user => $user );
$API->connect();
print Dumper $API;

my $condition;

# $condition = "FKSource_Plate__ID = 335775";  ## test condition ##
$condition ||= 1;

my %rearray_plates = $dbc->Table_retrieve(
    "Plate_Format,ReArray,ReArray_Request,Plate,Library JOIN Plate as Source_Plate on Source_Plate.Plate_ID = FKSource_Plate__ID",
    [   'count(*) as Count',
        'FK_Project__ID',
        'FKSource_Plate__ID',
        'Group_Concat(Source_Well) AS Source_Well',
        'Target_Well',
        'Plate.FK_Library__Name as Lib',
        'Source_Plate.FK_Library__Name as Source_Library',
        'Plate.FK_Library__Name as Target_Library',
        'Plate_Format_Type',
        'ReArray_Request.FKTarget_Plate__ID as Target_Plate'
    ],
    "WHERE Plate.FK_Library__Name=Library_Name AND FKTarget_Plate__ID = Plate.Plate_ID and Plate.FK_Library__Name like 'M%' and ReArray.FK_ReArray_Request__ID = ReArray_Request_ID and Plate.FK_Plate_Format__ID = Plate_Format_ID AND Plate_Format_Type like 'Abgene%' AND $condition GROUP BY Plate.Plate_ID ORDER BY Plate.FK_Library__Name, Plate.Plate_ID ASC",
    -limit => 0,
    -debug => $debug + 1
);

#print Dumper \%mx_libraries;
my $index = 0;

## try 335775

while ( defined $rearray_plates{'FKSource_Plate__ID'}[$index] ) {
    my $source_plate   = $rearray_plates{'FKSource_Plate__ID'}[$index];
    my $source_well    = $rearray_plates{'Source_Well'}[$index];
    my $source_library = $rearray_plates{'Source_Library'}[$index];
    my $target_library = $rearray_plates{'Target_Library'}[$index];
    my $target_plate   = $rearray_plates{'Target_Plate'}[$index];
    my $type           = $rearray_plates{'Plate_Format_Type'}[$index];
    my $count          = $rearray_plates{'Count'}[$index];
    $index++;

    ## check the source library to see if is a manual rearray
    print "$count X Source PLA $source_plate [$source_library] ($type) Wells INTO $target_library";

    &alDente::Data_Fix::replace_rearrayed_plate_with_tubes( -dbc => $dbc, -plate_id => $target_plate );

    #    NOT QUITE RIGHT ?? ... &alDente::Data_Fix::replace_rearrayed_plate_with_tubes(-dbc=>$dbc, -condition => "FK_Library__Name = '$library'", -plate_field=>'FKSource_Plate__ID', -library=>$library);

    print "\n";
    next;

}

exit;

=pod

** REPLACE Plate_Prep & Plate_Set records 315425 -> 349903 ** 
** REPLACE Plate_Prep & Plate_Set records 315331 -> 349807 ** 
** REPLACE Plate_Prep & Plate_Set records 315184 -> 349711 ** 
** REPLACE Plate_Prep & Plate_Set records 315434 -> 349999 ** 
** REPLACE Plate_Prep & Plate_Set records 316022 -> 350287 ** 
** REPLACE Plate_Prep & Plate_Set records 316020 -> 350191 ** 
** REPLACE Plate_Prep & Plate_Set records 316018 -> 350095 ** 
** REPLACE Plate_Prep & Plate_Set records 316929 -> 350575 ** 
** REPLACE Plate_Prep & Plate_Set records 316927 -> 350479 ** 
** REPLACE Plate_Prep & Plate_Set records 316877 -> 350383 ** 
** REPLACE Plate_Prep & Plate_Set records 317830 -> 350863 ** 
** REPLACE Plate_Prep & Plate_Set records 317829 -> 350767 ** 
** REPLACE Plate_Prep & Plate_Set records 317664 -> 350671 ** 
** REPLACE Plate_Prep & Plate_Set records 321965 -> 351151 ** 
** REPLACE Plate_Prep & Plate_Set records 321964 -> 351055 ** 
** REPLACE Plate_Prep & Plate_Set records 321660 -> 350959 ** 
** REPLACE Plate_Prep & Plate_Set records 335871 -> 351535 ** 
** REPLACE Plate_Prep & Plate_Set records 335206 -> 351439 ** 
** REPLACE Plate_Prep & Plate_Set records 335182 -> 351343 ** 
** REPLACE Plate_Prep & Plate_Set records 322869 -> 351247 ** 
** REPLACE Plate_Prep & Plate_Set records 335872 -> 351919 ** 
** REPLACE Plate_Prep & Plate_Set records 335207 -> 351823 ** 
** REPLACE Plate_Prep & Plate_Set records 335183 -> 351727 ** 
** REPLACE Plate_Prep & Plate_Set records 324901 -> 351631 ** 
** REPLACE Plate_Prep & Plate_Set records 332798 -> 352207 ** 
** REPLACE Plate_Prep & Plate_Set records 332796 -> 352111 ** 
** REPLACE Plate_Prep & Plate_Set records 329858 -> 352015 ** 
** REPLACE Plate_Prep & Plate_Set records 331631 -> 352315 ** 
** REPLACE Plate_Prep & Plate_Set records 331630 -> 352309 ** 
** REPLACE Plate_Prep & Plate_Set records 330463 -> 352303 ** 
** REPLACE Plate_Prep & Plate_Set records 334960 -> 352609 ** 
** REPLACE Plate_Prep & Plate_Set records 334959 -> 352513 ** 
** REPLACE Plate_Prep & Plate_Set records 334958 -> 352417 ** 
** REPLACE Plate_Prep & Plate_Set records 333824 -> 352321 ** 
** REPLACE Plate_Prep & Plate_Set records 335884 -> 352705 ** 
** REPLACE Plate_Prep & Plate_Set records 338772 -> 353089 ** 
** REPLACE Plate_Prep & Plate_Set records 338771 -> 352993 ** 
** REPLACE Plate_Prep & Plate_Set records 338770 -> 352897 ** 
** REPLACE Plate_Prep & Plate_Set records 336013 -> 352801 ** 
** REPLACE Plate_Prep & Plate_Set records 344687 -> 353377 ** 
** REPLACE Plate_Prep & Plate_Set records 344674 -> 353281 ** 
** REPLACE Plate_Prep & Plate_Set records 336647 -> 353185 ** 
** REPLACE Plate_Prep & Plate_Set records 341261 -> 353761 ** 
** REPLACE Plate_Prep & Plate_Set records 341136 -> 353665 ** 
** REPLACE Plate_Prep & Plate_Set records 341135 -> 353569 ** 
** REPLACE Plate_Prep & Plate_Set records 341048 -> 353473 ** 

my @libs = qw(
M00122
M00211
M00301
M00391
M00481
M00571
M00661
M00746
M00747
M00834
M00927
M01020
M01113
	      );

foreach my $lib (@libs) {
    Message("Delete Lib: $lib");
    
    $dbc->delete_records(-table=>'Work_Request', -dfield=>'FK_Library__Name', -cascade=>['Material_Transfer'], -id_list=>$lib, -condition=>'FK_Goal__ID=7');   ## No defined Goals record removed ##
    
    $dbc->delete_records(-table=>'Library', -dfield=>'Library_Name',-id_list=>$lib, -cascade=>['Library_Source','RNA_DNA_Collection']);
    
}

(316018 
,316929 
,316929 
,316927 
,316877 
,317830 
,317830 
,317829 
,317664 
,321965 
,321965 
,321964 
,321660 
,335871 
,335871 
,335206 
,335871 
,335871 
,335206 
,335182 
,322869 
,335872 
,335872 
,335207 
,335872 
,335872 
,335207 
,335183 
,324901 
,332798 
,332798 
,332796 
,329858 
,331631 
,331631 
,331630 
,330463 
,341261 
,341261 
,341136 
,341261 
,341261 
,341136 
,341135 
 ,341048);

Delete Libraries...

M00122
M00211
M00301
M00391
M00481
M00571
M00661
M00746
M00747
M00834
M00927
M01020
M01113

=cut

