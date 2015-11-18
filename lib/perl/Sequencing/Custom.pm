#################################
# Custom.pm
# 
# Custom scripts required by the Sequencing Department:
#
#
#  Fill in set of plate IDs/tray ids to a static excel template.  The standalone script will take in a list of trays or plate ids and set the plate ids.  The created excel spreadsheet will be stored in a directory in /home/aldente/public/.   
##################################
package Sequencing::Custom;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Custom.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>
Usage:
    build_QC(-dbc=>$dbc,-plate_ids=>\@plate_ids);
    

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/bin/perl<BR>Fill in set of plate IDs/tray ids to a static excel template. The standalone script will take in a list of trays or plate ids and set the plate ids. The created excel spreadsheet will be stored in a directory in /home/aldente/public/.<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

#@ISA = qw(alDente::ReArray);            

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
#use DBI;
use Data::Dumper;
#use Storable;

use FindBin;
use Data::Dumper;

use lib $FindBin::RealBin . "/../lib/perl/";
use SDB::DBIO;

use SDB::HTML;
use RGTools::HTML_Table;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;
use alDente::Diagnostics;    ## Diagnostics module
use alDente::SDB_Defaults;
use POSIX qw(ceil floor);

##############################
# global_vars                #
##############################
### Global variables
#use vars qw( $User $project_dir $URL_version $Benchmark);
#use vars qw(@locations @libraries @plate_sizes @plate_formats %Std_Parameters @users);
#use vars qw($Connection $dbh $user  $testing $lab_administrator_email $stock_administrator_email $scanner_mode);
#use vars qw($yield_reports_dir);
use vars qw(%Configs);
use vars qw(%Settings %Benchmark $html_header);

##############################
# modular_vars               #
##############################

my @qc_source;
my @qc_tray_source;
my @qc_dest;
my @qc_tray_dest;
my @qc_96_source;
my @qc_96_dest;


my @tray_quadrant;
    my @source_sep = ('', '', '','Source');  ## three blank lines;
    my @dest_sep = ('', '', '','Destination');  ## three blank lines;
    my @section_header = ('Plate','Source','Dest','Plate','Source','Dest');

##############################
# constants                  #
##############################
##############################
# main_header                #
##############################

######################
# Returns the HTML table and a link of the excel file of the extracted table as a text string
###################
sub build_QC {
##################   
    my %args = filter_input(\@_,-args=>'dbc,plate_ids,show_table',-mandatory=>'dbc,plate_ids');

    my $dbc = $args{-dbc};
    my $debug = $args{-debug};

    my $library_plate_number;
    my @ID_array = Cast_List(-list=>$args{-plate_ids},-to=>'array',-delimiter=>','); # plate_ids to be placed on the template.  passed in as a string separated by commas

    my $display = $args{-display};
    my @plate_size_array;
    my $table;
############
# Making sure all the inputs are defined
############

    if ( @ID_array == 0 ) {
        die("Error: The ID array is empty");
    }

    my $ID;
    my @library_plate_number_array;
     
    my @formats;
    my @labels;
    my @plates;
    my $plate_index = 0;
 #   my @quadrants = ('a','b','c','d');
	my @quadrants = ();
    for $ID (@ID_array) {
        if ($ID eq '') {
            next;
        }
        # There are 3 kinds of input: 96 Well Plate, 384 Well and a Tray (which is 4 96 well plate)
        # We will have a different source column for 96 Well (A1 to H12), 384 Well/Tray (A1 to P24)
                
        my $valid_ids = $dbc->get_id(-barcode=>$ID, -table=>'Plate');
        $library_plate_number = alDente::Tools::alDente_ref(-dbc=>$dbc,-table=>'Plate',-id=>$valid_ids);

        unless ($library_plate_number && $valid_ids) { 
            Message("$ID ($library_plate_number ($valid_ids) does not appear to be valid (Aborting)"); 
            return;
        }
        
        my @list = ($library_plate_number);
        foreach (2..12) { push @list, '' }  ### add blank lines below plate label... ## 
        
        my ($tray_label) =  $dbc->Table_find_array('Plate_Tray',["Concat('Tra',FK_Tray__ID,' (',Plate_Position,')')"],"where FK_Plate__ID = $valid_ids");

        # see if it's a 384 well plate.  If so, get the 4 quadrants
       
        my $format;
		my $this_quad = '';
        if ($tray_label) {
            $list[1] = $tray_label;   ## add tray indicator on line below plate label if applicable
            $format = 'Tray';
            if ($tray_label =~ /\d+\s?\(([abcd])\)$/) {$this_quad = $1}
       }
        else { 
            my ($plate_size) = $dbc->Table_find('Plate','Plate_Size',"where Plate_ID = $valid_ids",-debug=>0);
            $format = $plate_size;
        }
        
		push @quadrants, $this_quad;
        push @labels, \@list;
        push @plates, "$library_plate_number ($format)";
        push @formats, $format;
        $plate_index++;

    } # end for

    $table =  _fill_QC(-labels=>\@labels,-debug=>$debug,-format=>\@formats,-quadrants=>\@quadrants);

    if (!$table) { return }     

    my $timestamp = timestamp();
    my $user_id = $dbc->get_local('user_name');
	my $file_name = "QC_gel_$timestamp.$user_id";

    if ($dbc->{dbase} ne $Configs{PRODUCTION_DATABASE}) { $file_name .= ".test" }
    $file_name .= '.xlsx';

    my $file = "$alDente::SDB_Defaults::URL_temp_dir/$file_name";
    
    Message("Generated xls: $file");
    
    my $output.= $table->Printout(-filename=>$file); 
    if ($display) {
        $output.= $table->Printout(0);
    }

    return $output . '<p>';    
}

########################
# Fill the table by column and return the table to caller
###################
sub _fill_QC {
####################
    my %args = filter_input(\@_,-mandatory=>'labels,format');
   
 	my $format_ref = $args{-format};
	my $quadrants_ref = $args{-quadrants};
    my $plate_labels = $args{-labels};
    my $debug = $args{-debug};
    
    my $table = HTML_Table->new();
    my $count = int(@$plate_labels);
   
    my @array;
 
    my @source_array = ();
    my @dest_array = ();
    my @labels = ();
    my $plate_index = 0;
	my $block = 1;
	my @quadrants_dest = ();
	my @formats_dest = ();
	my @source_print_friendly = ();
	my @dest_print_friendly = ();
	
## initializing the $dest_array
	foreach (1..$count) {
		push @quadrants_dest, '';
		push @formats_dest, '96-well';
	}

## 
	@source_array = &tray_wells ($quadrants_ref, $format_ref);
	@dest_array = &tray_wells (\@quadrants_dest, \@formats_dest);
    while ($plate_index < $count) {
        my $p_labels = loop_index($plate_labels,$plate_index);
        push @labels, @$p_labels;

        $plate_index++;
		for (my $index=0; $index < 12; $index ++) { 
			push @source_print_friendly, $source_array[($plate_index-1) * 12 + $index];
			push @dest_print_friendly, $dest_array[($plate_index-1) * 12 + $index];
		}


        if ($plate_index%8 == 0) {
			
			write_block($block,\@source_print_friendly,\@dest_print_friendly,-clear=>1,-debug=>$debug,-table=>$table,-labels=>\@labels);
			@source_print_friendly = ();
			@dest_print_friendly = ();
            $block++;
		}
    }
    write_block($block,\@source_print_friendly,\@dest_print_friendly,-clear=>1,-debug=>$debug,-table=>$table,-labels=>\@labels);
    
    return $table;
}

#################
sub loop_index {
#################
    my $array_ref = shift;
    my $index = shift;

    if (!defined $index || !$array_ref) { return }

    my $array_size = int(@$array_ref);

    if (!$array_size) { Message("Empty array"); return; }  ## empty array
    elsif ($array_size == 1) { return $array_ref->[0] }  ## only one element ##
    
    if ($index >= 0) {
        while ($index >= $array_size) { $index -= $array_size }
    }
    else {
        while ($index < 0) { $index += $array_size }
    }
    
    return $array_ref->[$index];
}
    
##################
sub write_block {
##################
    my %args = filter_input(\@_,-args=>'block,source,dest');
   
    my $table        = $args{-table};
    my $block_number = $args{-block};
    my $source_array = $args{-source};
    my $dest_array   = $args{-dest};
    my $labels       = $args{-labels};
    my $clear        = $args{-clear}; 
    my $debug = $args{-debug};
    
    if ($debug) {
        print "<BR>*** QC $block_number ***<BR>";
                print "@$source_array<BR>";
                print "...<BR>";
                print "@$dest_array<BR>";
                print "<BR>***<BR>";
    }
    
    $table->Set_Row(["QC $block_number"],'lightblue');
    $table->Set_Row(\@section_header,'darkgrey');
    
    foreach my $line (0..47) {
        my $col2 = $line + 48;
        
        my @row = ($labels->[$line],$source_array->[$line],$dest_array->[$line]);

        if (int(@$source_array) > $col2) {  
            push @row, $labels->[$col2], $source_array->[$col2],$dest_array->[$col2]; 
        }
       
        
        if ($line%12 == 0 || $line%12 == 1) { $table->Set_Row(\@row) }
        elsif ($debug && $line%12 == 11) { 
            $table->Set_Row(['...']);  ## for debugging only 
            $table->Set_Row(\@row);
        }
	else {
            ## hide detailed rows 3..11 if debugging ##
	    if (!$debug) { $table->Set_Row(\@row) }
	}
    }
    
    if ($clear) {
        @$source_array = ();
        @$dest_array = ();
        @$labels = ();
    }
    
    return;
}


################### 
sub tray_wells {
####################
#	
#	
#
#	Should be used as such:
#			@source = tray_wells (\@quadrants, \@quadrant_types);
#	where it takes in two references to two arrays and returns a new array
#	
#	The input arrays should be equal in size and their elemts should match the description else will generte errors
#	First Input Array: elements can only be [a-d]	or ''
#	Second Input Array: elements can only be 'tray', '384' or '98'
#				where [a-d] respond to only 'tray' and 
#				'384' and '98' corespond only to '' 
#
##################################
###		The quadrants


	my $quadrants_ref =  shift;
	my @quadrants = @$quadrants_ref;
	
	my $quadrants_type_ref = shift;
	my @quadrants_type = @$quadrants_type_ref;
	
	my $quadrants_size = int @quadrants;
	my $quadrants_type_size = int @quadrants_type;
	
	my @errors;
	my @source = ();
	my @block;
	my $row;
	my $column;
	my $normalized_counter;
	my $normalized_counter_char;
	my $index_counter=0;
	my $input;

	if ($quadrants_size != $quadrants_type_size) {
		push @errors, "The size of quadrants and their types don't match";
	}
	if (@errors) { Message("Errors found: @errors"); return; }

	
	foreach $input (@quadrants) {
		if ($quadrants_type[$index_counter] eq '96-well') {
			if ($input ne '') {
				push @errors, "the quadrant $index_counter is $quadrants_type[$index_counter] type and cannot contain a character";
				last;
			}
			$normalized_counter = $index_counter % 8; 
			$row = 'A';
			if ($normalized_counter) {
				foreach (1..$normalized_counter) {$row++ }
			}
				@block = &get_block ($row, 1, 12, 1);
				push @source, @block;
		}
		elsif ($quadrants_type[$index_counter] eq '384-well') {
			if ($input ne '') {
				push @errors, "the quadrant $index_counter is $quadrants_type[$index_counter] type and cannot contain a character";
				last;
			}			
			$normalized_counter = $index_counter % 32;
			$row = 'A';
			
			$normalized_counter_char = $normalized_counter % 16;
			if ($normalized_counter_char) {
				foreach (1..$normalized_counter_char) {$row++ }
			}
			
			if ($normalized_counter % 2 == 0 && $normalized_counter > 16 ) { $column = 2} 
			elsif ($normalized_counter % 2 == 1 && $normalized_counter > 16) { $column = 1}
			elsif ($normalized_counter % 2 == 0 && $normalized_counter < 16) { $column = 1}
			else { $column = 2}

			@block = &get_block ($row, $column, 12, 2);
			push @source, @block;
		}
		elsif ($quadrants_type[$index_counter] eq 'Tray') {
			if ($input !~ /^[abcd]$/ ) {
				push @errors, "unrecognized quadrant ('$input' ?)";
				last;
			}
	
			$normalized_counter = $index_counter;# % 16;
			if ($input eq 'a' || $input eq 'b') { $row = 'A'}
			else { $row = 'B'}	
			
			$normalized_counter_char = $normalized_counter % 8;
			if ($normalized_counter_char) {
				foreach (1..$normalized_counter_char) {$row ++; $row++; } 
			}
			
			if ($input eq 'a' || $input eq 'c') { $column = 1}
			else { $column = 2}

			@block = &get_block ($row, $column, 12, 2);
			push @source, @block;
		}
		else {
			push @errors, "unrecognized quadrant type $quadrants_type[$index_counter]";
			last;			
		} 
		$index_counter ++;
	}
	if (@errors) { Message("Errors found: @errors"); return; }
	return @source;
}


################### 
sub get_block {
#################### 
	my $row = shift;
	my $first_column = shift;
	my $block_size = shift;
	my $increment = shift;
	my $element;
	my $column = $first_column;
	my @block;
	
	for (my $counter = 0; $counter < $block_size; $counter ++ ) {
		$element = $row . $column;
		push @block, $element;
		$column+= $increment;			
	}
	return @block;
}

return 1;


