##################################################################################################################################
# Primer_Order.pm
#
# Customized function code for interacting with custom oligonucleotide primer companies
#
###################################################################################################################################
package Sequencing::Primer_Order;                  

### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;
use Storable;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/"; 
use lib $FindBin::RealBin . "/../lib/perl/Imported/Excel/";

### Reference to alDente modules
use alDente::SDB_Defaults;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use RGTools::RGIO;
use RGTools::Object;

### Global variables
use vars qw($user $java_bin_dir $templates_dir $bin_home %Configs);

### Modular variables
my $DateTime; 

### Constants
my $FONT_COLOUR = 'BLUE'; 

# custom globals
my $IDT_EXCEL = "$templates_dir/IDT_template.xls";
my $IDT_FG_TechD_EXCEL = "$templates_dir/FG_TechD_IDT_template.xls";

my $ILLUMINA_EXCEL = "$templates_dir/oligator.xls";
my $INVITROGEN_EXCEL = "$templates_dir/InvitrogenTemplate.xls";
my $TAB_TEMPLATE = "$templates_dir/Primer Order Form.txt";
my %primer_template;
$primer_template{'IDT_xls'} = $IDT_EXCEL;
$primer_template{'FG_TechD_IDT_xls'} = $IDT_FG_TechD_EXCEL;
$primer_template{'IDT_ASP_xls'} = "$templates_dir/IDT_ASP_template.xls";
$primer_template{'IDT_Sequencing_xls'} = "$templates_dir/IDT_Sequencing_template.xls";
$primer_template{'IDT_SeqVal_xls'} = "$templates_dir/IDT_SeqVal_131119_template.xls";
$primer_template{'IDT_SeqVal_500pmole_xls'} = "$templates_dir/IDT_SeqVal_500pmole_140905_template.xls";

###########################################
# Function that generates a primer order file given primer_plate_ids
# This function either sends off an email (default) or writes a file
# 
############################################
sub generate_primer_order_file {
############################################
    my %args = &filter_input(\@_,-args=>'dbc,type,primer_plate_ids,split,email,file,format,po_number',-mandatory=>'dbc,type,primer_plate_ids,split');
    my $dbc = $args{-dbc} || $Connection;
    my $type = $args{-type};                         # (Scalar) The type of primer order file. One of Illumina_txt, Illumina_xls or IDT_xls
    my $primer_plate_ids = $args{-primer_plate_ids}; # (ArrayRef) An array reference of primer plate ids to generate
    my $split = $args{-split} || 0;                  # (Scalar) Flag that determines if the primer order files will be split up or combined
    my $email = $args{-email} || $user || $dbc->get_local('user_email');   # (Scalar) [Optional] Email addresses to be sent out 
    my $file = $args{-filename};                     # (Scalar) [Optional] filename to be written to disk, fully qualified
    my $format = $args{-format};                     # (Scalar) [Optional] file format to be written out. Only relevant if the company has two or more formats.
    my $po = $args{-po_number};                      # (Scalar [Optional] PO number of the primer order


    # check if it is split. 
    # If it is not split, then concatenate the primer plate ids 
    # if it is split, then use the primer plate ids as an array
    my @plate_ids = ();
    my $all_ids =  join(",",@{$primer_plate_ids});
    if ($split) {
	@plate_ids = @{$primer_plate_ids};
    }
    else {
	my $id_str = join(',',@{$primer_plate_ids});
	push (@plate_ids,$id_str);
    }

    my @filenames = ();

    my %attachment;

    foreach my $ids (@plate_ids) {
	# generate a random filename if a filename has not been given
	my $ext = '';;
	if ($type =~ /txt$/) {
	    $ext = "txt";
	}
	elsif ($type =~ /xls$/) {
	    $ext = "xls";
	}
	# change commas to dots for readability of filenames
	my $id_str = $ids;
	$id_str = &convert_to_range($id_str);
	$id_str =~ s/,/\./g;
	my $filename = "$alDente::SDB_Defaults::URL_temp_dir/PrimerOrderFile@{[timestamp()]}.$ext";
	if ($file) {
	    $filename = "$file.$id_str.$ext";
	}

	# initialize default set of fields
	# handle IDT primer orders differently - provide with a solution ID as well
	my $fields = "FK_Primer_Plate__ID,FK_Primer__Name,Well,Primer_Sequence";
	if ($type =~ /IDT/) {
	    $fields .= ",FK_Solution__ID,Notes";
	}

	### Generate rows of the order file, ordered by well
	my @rows = $dbc->Table_find("Primer_Plate,Primer_Plate_Well,Primer",$fields,"WHERE FK_Primer_Plate__ID=Primer_Plate_ID AND FK_Primer__Name=Primer_Name AND Primer_Plate_ID in ($ids) ORDER BY FK_Primer_Plate__ID,Well");
	
	# pass rows into appropriate function for generating a file
	if ($type =~ /Illumina_xls/) {
	    _generate_Illumina_order_xls(-data_ref=>\@rows,-filename=>$filename,-po_number=>$po);
	}
	elsif ($type =~ /Illumina_txt/) {
	    _generate_Illumina_order_text(-data_ref=>\@rows,-filename=>$filename,-po_number=>$po);
	}
	elsif ($type =~ /Invitrogen_xls/) {
	    _generate_Invitrogen_order_xls(-data_ref=>\@rows,-filename=>$filename,-po_number=>$po);
	}
	elsif ($type =~ /IDT_xls|IDT_ASP_xls|IDT_Sequencing_xls|IDT_SeqVal_xls|IDT_SeqVal_500pmole_xls/) {
	    @rows = ();
	    my @ids = Cast_List(-list=>$ids,-to=>'Array');
	    my @fields = Cast_List(-list=>$fields,-to=>'Array');
	    my @available_wells = $dbc->Table_find('Well_Lookup','Plate_96', "WHERE Quadrant ='a'");
	    foreach my $id (@ids) {
	        my %data = $dbc->Table_retrieve("Primer_Plate,Primer_Plate_Well,Primer",\@fields,"WHERE FK_Primer_Plate__ID=Primer_Plate_ID AND FK_Primer__Name=Primer_Name AND Primer_Plate_ID = $id ORDER BY Primer_Plate_ID,Well,Primer_Plate_Well_ID");
		my %new_data;
		my %size;
		my $max_size;
	        my $primer_plate;
	        my $solution;
		for (my $i = 0; $i <= $#{$data{Well}}; $i++) {
		    push @{$new_data{$data{Well}->[$i]}}, "$data{FK_Primer_Plate__ID}->[$i],$data{FK_Primer__Name}->[$i],$data{Well}->[$i],$data{Primer_Sequence}->[$i],$data{FK_Solution__ID}->[$i],$data{Notes}->[$i]";
		    $size{$data{Well}->[$i]}++;
		    if ($size{$data{Well}->[$i]} > $max_size) {
			$max_size = $size{$data{Well}->[$i]};
		    }
		    unless ($primer_plate) {
			$primer_plate = $data{FK_Primer_Plate__ID}->[$i];
			$solution = $data{FK_Solution__ID}->[$i];
		    }
		}

		for (my $i = 0; $i < $max_size; $i++) {
		    foreach my $well (@available_wells) {
			if ($new_data{$well}->[$i]) {
			    my $line = $new_data{$well}->[$i];
			    push @rows, $line;
			    my @parts = split(",",$line);
			    $primer_plate = $parts[0];
			    $solution = $parts[4];
			}
			else {
			    push @rows, "$primer_plate,empty,$well,empty,$solution";
			}
		    }
		}
	        
	    } 
	    #print HTML_Dump \@rows;

	    _generate_IDT_order_xls(-data_ref=>\@rows,-filename=>$filename,-po_number=>$po,-template => $primer_template{$type});
	}
	else {
	    Message("Error: Invalid Order type for $ids");
	}
	push (@filenames,$filename);

	# if email is defined, then send the file to the email address specified
	if ($email) {
	    # handle excel file specially
	    if ($type =~ /xls$/) { 
		# open file in binary mode
		open(INF,"$filename");
		binmode(INF);
		my @lines = <INF>;
		my $xlstr = join "",@lines;
		#$attachment{"primerorder.${id_str}.xls"} = $xlstr;
		$attachment{$filename} = "primerorder.${id_str}.xls";
	    }
	    else  {
		# assume file is text
		open(INF,"$filename");
		my @lines = <INF>;
		my $str = join "",@lines;
		#$attachment{"primerorder.${id_str}.txt"} = $str;
		$attachment{$filename} = "primerorder.${id_str}.txt";
	    }
	    
	}
    }

    # send email to user
    if ($email) {
	if ($type =~ /xls$/) { 
	    # send to user
	     my $ok = alDente::Subscription::send_notification( -dbc=>$dbc,
                                                                -name=>"Primer Order regenerated for primer plate",
                                                                -from=>'aldente@bcgsc.ca',
                                                                -subject=>"Primer Order regenerated for primer plate $all_ids (from Subscription Module)",
                                                                -body=>"Primer Order regenerated for primer plate $all_ids",
                                                                -content_type=>'html',
                                                                -attachments=>\%attachment,
                                                                -verbose=>undef,
                                                                -attachment_type=>'excel');


	}
	else  {
	    my $ok = alDente::Subscription::send_notification( -dbc=>$dbc,
                                                                -name=>"Primer Order regenerated for primer plate",
                                                                -from=>'aldente@bcgsc.ca',
	                                                        -subject=>"Primer Order regenerated for primer plate $all_ids (from Subscription Module)",
                                                                -body=>"Primer Order regenerated for primer plate $all_ids",
                                                                -content_type=>'html',
	                                                        -attachments=>\%attachment,
                                                                -verbose=>undef,
                                                                -attachment_type=>'text');
	}
    }

    # return the generated filenames
    return \@filenames;
}

#############################################
# Function that reads a yield report and 
# creates a hash of information about it
# returns a hash if successful, undef if not.
#############################################
sub read_yield_report {
#############################################
    my %args = &filter_input(\@_,-args=>'type,file',-mandatory=>'type,file');
    
    my $type = $args{-type};               # (Scalar) The type of yield report. One of Illumina, Invitrogen, or IDT
    my $file = $args{-file};   # (Scalar) The filename of the yield report.

    my $info_hash = undef;
    # figure out what yield report needs to be parsed, then call the appropriate function
    if ($type =~ /^Illumina$/i) {
	$info_hash = &_read_Illumina_yield_report(-file=>$file);
    }
    elsif ($type =~ /^Invitrogen$/i) {
	$info_hash = &_read_Invitrogen_yield_report(-file=>$file);
    }
    elsif ($type =~ /^IDT$/i) {
	$info_hash = &_read_IDT_yield_report(-file=>$file);
    }
    elsif ($type =~ /^IDT Batch$/i) {
	$info_hash = &_read_batch_IDT_yield_report(-file=>$file);
    }

    return $info_hash;
}

##############################################
# Helper function
# creates a text order file for Illumina
# requires a filename or it writes it to the temporary directory
##############################################
sub _generate_Illumina_order_text {
##############################################
    my %args = &filter_input(\@_,-args=>'data_ref,filename,po_number',-mandatory=>'data_ref,filename');

    my $data_ref = $args{-data_ref};        # (ArrayRef) An array reference representing the rows of an order
    my $filename = $args{-filename};        # (Scalar} Filename to write. Randomly generates a filename if omitted.
    my $po =       $args{-po_number};       # (Scalar) [Optional] PO Number of the order

    my $newfile = '';
    # create file string
    my $prev_req_num = 0;
    my $counter = 0;
    foreach my $row (@{$data_ref}) {
	my ($num,$name,$well,$sequence) = split ',',$row;
	if ($num != $prev_req_num) {
            $counter++;
            $prev_req_num = $num;
        }
        # parse out the well to row and column
	my $well_row = substr($well,0,1);
	my $well_col = substr($well,1);
	if ($well_col =~ /0(\d)/) {
	    $well_col = $1;
	}
	$sequence = uc($sequence);
	$newfile .= "$counter,$well_row,$well_col,$name,,$sequence\n";
    }
    # write out file
    open(OUTF,">$filename");
    print OUTF $newfile;
    close OUTF;
    # use unix2dos
    &try_system_command("unix2dos $filename");

    return $filename;
}

##############################################
# Helper function
# creates a Excel order file for Illumina
# requires a filename or it writes it to the temporary directory
##############################################
sub _generate_Illumina_order_xls {
##############################################
    my %args = &filter_input(\@_,-args=>'data_ref,filename,po_number',-mandatory=>'data_ref,filename');
    
    my $data_ref = $args{-data_ref};        # (ArrayRef) An array reference representing the rows of an order
    my $filename = $args{-filename};        # (Scalar} Filename to write. Randomly generates a filename if omitted.
    my $po =       $args{-po_number};       # (Scalar) [Optional] PO Number of the order

    # format the data to string format
    my $prev_req_num = 0;
    my $counter = 0;
    foreach my $row (@$data_ref) {
	my ($num,$name,$well,$sequence) = split ',',$row;
	if ($num != $prev_req_num) {
	    $counter++;
	    $prev_req_num = $num;
	}
	$row = "$counter,$name,$well,$sequence"; 
    }

    # load up the tab_delimited file template
    # load up tab-delimited template
    open(TABFILE, $TAB_TEMPLATE);
    my @header = <TABFILE>;
    close(TABFILE);
    my $new_tabfile = "";
    foreach my $row (@header) {
	$new_tabfile .= $row;
    }

    ## for header, do replacement for stuff in <ANGLE_BRACES> to correct values
    # date
    my $today_date = &today();
    $new_tabfile =~ s/<DATE>/$today_date/;
    
    # append to the header
    foreach my $row (@{$data_ref}) {
	my ($num,$name,$well,$sequence) = split ',',$row;
	# parse out the well to row and column
	my $well_row = substr($well,0,1);
	my $well_col = substr($well,1);
	if ($well_col =~ /0(\d)/) {
	    $well_col = $1;
	}
	$sequence = uc($sequence);
	$new_tabfile .= "$num\t$well_row\t$well_col\t$name\t\t$sequence\t\t\n";
    }

    ## write out temp file 
    my $tempfile = "$URL_temp_dir/Primer@{[timestamp()]}";
    open(OUTF,">${tempfile}.txt");
    print OUTF $new_tabfile;
    close(OUTF);

    &try_system_command("$java_bin_dir/java -jar $bin_home/../lib/java/IlluminaConvert/IlluminaConvert.jar ${tempfile}.txt $ILLUMINA_EXCEL");
    # move temp file to correct name
    &try_system_command("mv ${tempfile}.txt.Illumina.xls $filename");

    return $filename;
}

##############################################
# Helper function
# creates a Excel order file for Invitrogen
# requires a filename or it writes it to the temporary directory
##############################################
sub _generate_Invitrogen_order_xls {
##############################################
    my %args = &filter_input(\@_,-args=>'data_ref,filename,po_number',-mandatory=>'data_ref,filename');
    
    my $data_ref = $args{-data_ref};        # (ArrayRef) An array reference representing the rows of an order
    my $filename = $args{-filename};        # (Scalar} Filename to write. Randomly generates a filename if omitted.
    my $po =       $args{-po_number};       # (Scalar) [Optional] PO Number of the order

    # format the data to string format
    my $prev_req_num = 0;
    my $counter = 0;
    foreach my $row (@$data_ref) {
	my ($num,$name,$well,$sequence) = split ',',$row;
	if ($num != $prev_req_num) {
	    $counter++;
	    $prev_req_num = $num;
	}
	$row = "$counter,$name,$well,$sequence"; 
    }

    # load up the tab_delimited file template
    # load up tab-delimited template
    open(TABFILE, $TAB_TEMPLATE);
    my @header = <TABFILE>;
    close(TABFILE);
    my $new_tabfile = "";
    foreach my $row (@header) {
	$new_tabfile .= $row;
    }

    ## for header, do replacement for stuff in <ANGLE_BRACES> to correct values
    # date
    my $today_date = &today();
    $new_tabfile =~ s/<DATE>/$today_date/;
    
    # append to the header
    foreach my $row (@{$data_ref}) {
	my ($num,$name,$well,$sequence) = split ',',$row;
	# parse out the well to row and column
	my $well_row = substr($well,0,1);
	my $well_col = substr($well,1);
	if ($well_col =~ /0(\d)/) {
	    $well_col = $1;
	}
	$sequence = uc($sequence);
	$new_tabfile .= "$num\t$well_row\t$well_col\t$name\t\t$sequence\t\t\n";
    }

    ## write out temp file 
    my $tempfile = "$URL_temp_dir/Primer@{[timestamp()]}";
    open(OUTF,">${tempfile}.txt");
    print OUTF $new_tabfile;
    close(OUTF);

    &try_system_command("$java_bin_dir/java -jar $bin_home/../lib/java/IlluminaConvert/InvitrogenConvert.jar ${tempfile}.txt $INVITROGEN_EXCEL");
    # move temp file to correct name
    &try_system_command("mv ${tempfile}.txt.Invitrogen.xls $filename");

    return $filename;
}

##############################################
# Helper function
# creates an Excel order file for Illumina
# requires a filename or it writes it to the temporary directory
##############################################
sub _generate_IDT_order_xls {
##############################################
   my %args = &filter_input(\@_,-args=>'data_ref,filename,po_number',-mandatory=>'data_ref,filename');

   my $data_ref = $args{-data_ref};        # (ArrayRef) An array reference representing the rows of an order
   my $filename = $args{-filename};        # (Scalar} Filename to write. Randomly generates a filename if omitted.
   my $po =       $args{-po_number};       # (Scalar) [Optional] PO Number of the order
   my $template = $args{-template};

   # load up the excel template
   my $oBook = Spreadsheet::ParseExcel::SaveParser::Workbook->Parse("$template");
   my @worksheet_array = @{$oBook->{Worksheet}};
   my $sheet = $worksheet_array[0];
   #$sheet->{ColWidth}[0] = 45;
    
   # the format for the order array is primer_order_number,name,well,sequence. 
   # Add a header for each new solution ID
   # save all information into the excel sheet
   my $counter = 0;
   my $prev_sol_id = '';

  my $format = $oBook->AddFont(
			     Name      => 'Arial',
			     Height    => 14,
			     Bold      => 1, #Bold
			     Italic    => 0, 
			     Underline => 0,
			     Strikeout => 0,
			     Super     => 0,
       );
   my $cellformat =
      $oBook->AddFormat(
			 Font => $oBook->{Font}[$format]
			 );

   my %plate_names;
   foreach my $row (@$data_ref) {
       my ($num,$name,$well,$sequence,$sol_id,$notes) = split ',',$row;
       # need to zeropad by 10
       my $padded_sol_id = sprintf("%010d",$sol_id);
       if ($notes) {
	   $plate_names{$sol_id} = "SOL${padded_sol_id}_$notes";
       }
       elsif ($plate_names{$sol_id}) {
	   next;
       }
       else {
	   $plate_names{$sol_id} = "SOL${padded_sol_id}";
       }
   }

   foreach my $row (@$data_ref) {
       my ($num,$name,$well,$sequence,$sol_id,$notes) = split ',',$row;
       my $rownum = $counter+39;
    
       $sheet->AddCell($rownum,0,$plate_names{$sol_id});
       $sheet->AddCell($rownum,1,$well);
       $sheet->AddCell($rownum,2,$name);
       $sheet->AddCell($rownum,3,uc($sequence));
       $counter++;
   }
   
   # save PO number if necessary
   if ($po) {
       $sheet->AddCell(11,3,$po);  
   } 
   # save date
   #$sheet->AddCell(1,1,&today());
   
   $oBook->SaveAs("$filename");
   
   
   return $filename;
}

##############################################
# Helper function
# reads an Illumina yield report
# Return: a hashref of {order_name} => [primer_name,well]
##############################################
sub _read_Illumina_yield_report {
##############################################
    my %args = &filter_input(\@_,-args=>'file',-mandatory=>'file');

    my $file = $args{-file};           # (Scalar) Filename of the yield report

    # open file
    my $fh;
    open($fh,"$file");

    # Push file lines into an array
    my @file_array = ();
    while (<$fh>) {
	push (@file_array,$_);
    }
    
    my $order_id =0;
    my $oligo_info = 0;
    my %oligo_hash;
    # parse file
    foreach (@file_array) {
	my @row_array = split ',';
	# look for the order ID in the first column
	if (@row_array && (!$oligo_info) && ($row_array[0] =~ /Order ID/i)) {
	    $order_id = $row_array[1];
	    $order_id = &chomp_edge_whitespace($order_id);
	    next;
	}
	# find the header of the body of the file to figure out where to start parsing
	if (/Barcode,Plate,Customer Well,Well,Oligator Lot,Seq Name,Seq,Length,Comment,MW,E260,Tm,Yield_OD260,Yield_ug,Yield_nanomoles,Conc_uM,Volume_ul,Conc_ug\/ul/) {
	    $oligo_info = 1;
	    next;
	}
	# if this header is seen again, then two or more files have been concatenated. Just set oligo_info to 0 again
	if (/Illumina Oligator Shipping Manifest/) {
	    $oligo_info = 0;
	    next;
	}
	# parse a 'body' line and push into oligo hash
	if ($oligo_info) {
	    my (undef,$platenum,undef,$well,undef,$primername,undef) = split ',';
	    if ($primername =~ /autoblank/i) {
		next;
	    }
	    if (defined $oligo_hash{"$order_id-$platenum"}) {
		push (@{$oligo_hash{"$order_id-$platenum"}},[$primername,$well]);
	    }
	    else {
		$oligo_hash{"$order_id-$platenum"} = [[$primername,$well]];
	    }
	    next;
	}
    }
    # return hash
    return \%oligo_hash;
}

##############################################
# Helper function
# reads an Invitrogen yield report
# Return: a hashref of {order_name} => [primer_name,well]
##############################################
sub _read_Invitrogen_yield_report {
##############################################
    my %args = &filter_input(\@_,-args=>'file',-mandatory=>'file');

    my $file = $args{-file}; # (Scalar) Filename of the yield report
    
    eval {
	require Spreadsheet::ParseExcel;
    };
    if ($@) {
	print "Missing required modules: $@";
	return undef;
    }

    # open the Excel file
    my $oBook = Spreadsheet::ParseExcel::Workbook->Parse("$file");
    my @worksheet_array = @{$oBook->{Worksheet}};
    my $sheet = $worksheet_array[0];
    
    # scan for a line that starts with Num_Suf in the 0th column (the orderid column), and PRIMER_NAME in the 4th column
    my $order_id =0;
    my $oligo_info = 0;
    my %oligo_hash;

    foreach my $i (1..$sheet->{MaxRow}) {
	my $orderid_cell = $sheet->{Cells}[$i-1][0];	
	unless ($orderid_cell) {
	    # no value found, skip line
	    next;
	}
	$order_id = $orderid_cell->Value;
	$order_id = &chomp_edge_whitespace($order_id);
	if ($order_id =~ /^Num_Suf$/) {
	    $oligo_info = 1;
	    next;
	}
	if ($oligo_info) {
	    my $well_cell = $sheet->{Cells}[$i-1][1];
	    my $primername_cell = $sheet->{Cells}[$i-1][4];
	    my $well = &chomp_edge_whitespace($well_cell->Value);
	    my $primername = &chomp_edge_whitespace($primername_cell->Value);
	    if (defined $oligo_hash{"$order_id"}) {
		push (@{$oligo_hash{"$order_id"}},[$primername,$well]);
	    }
	    else {
		$oligo_hash{"$order_id"} = [[$primername,$well]];
	    }
	    next;
	}
    }
    return \%oligo_hash;
}

##############################################
# Helper function
# reads an IDT yield report
# Return: a hashref of {order_name} => [primer_name,well]
##############################################
sub _read_IDT_yield_report_old {
##############################################
    my %args = &filter_input(\@_,-args=>'file',-mandatory=>'file');

    my $file = $args{-file}; # (Scalar) Filename of the yield report

    # need to read in the Excel file first 
    # need to check if the Excel parser is installed first before trying
    eval {
	require Spreadsheet::ParseExcel;
    };
    if ($@) {
	print "Missing required modules: $@";
	return undef;
    }

    # open the Excel file
    my $oBook = Spreadsheet::ParseExcel::Workbook->Parse("$file");
    my @worksheet_array = @{$oBook->{Worksheet}};
    my $sheet = $worksheet_array[0];

    # grab the order ID
    my $order_id =0;
    my $orderid_cell = $sheet->{Cells}[2][7] || $sheet->{Cells}[2][8];
    $order_id = $orderid_cell->Value;
    $order_id = &chomp_edge_whitespace($order_id);
    # scan for a line that starts with Ref in the 0th column (the orderid column), and PRIMER_NAME in the 4th column
    my $oligo_info = 0;
    my %oligo_hash;

    foreach my $i (1..$sheet->{MaxRow}+1) {
	my $row_cell = $sheet->{Cells}[$i-1][0];	
	unless ($row_cell) {
	    # no value found, skip line
	    next;
	}
	my $rowval = $row_cell->Value;
	$rowval = &chomp_edge_whitespace($rowval);
	if ($rowval =~ /^Ref/) {
	    $oligo_info = 1;
	    next;
	}
	if ($oligo_info) {
	    my $well_cell = $sheet->{Cells}[$i-1][2];
	    my $primername_cell = $sheet->{Cells}[$i-1][1];
	    my $well = &chomp_edge_whitespace($well_cell->Value);
	    my $primername = &chomp_edge_whitespace($primername_cell->Value);
	    # if primername or well has no value, just skip
	    unless ($primername) {
		next;
	    }
	    unless ($well) {
		next;
	    }
	    if (defined $oligo_hash{"$order_id"}) {
		push (@{$oligo_hash{"$order_id"}},[$primername,$well]);
	    }
	    else {
		$oligo_hash{"$order_id"} = [[$primername,$well]];
	    }
	    next;
	}
    }
    return \%oligo_hash;
}

##############################################
# Helper function
# reads an IDT yield report
# Return: a hashref of {order_name} => [primer_name,well]
##############################################
sub _read_batch_IDT_yield_report {
##############################################
    my %args = &filter_input(\@_,-args=>'file',-mandatory=>'file');

    my $file = $args{-file}; # (Scalar) Filename of the yield report

    # need to read in the Excel file first 
    # need to check if the Excel parser is installed first before trying
    eval {
	require Spreadsheet::ParseExcel;
    };
    if ($@) {
	print "Missing required modules: $@";
	return undef;
    }

    # open the Excel file
    my $oBook = Spreadsheet::ParseExcel::Workbook->Parse("$file");
    my @worksheet_array = @{$oBook->{Worksheet}};
    my $sheet = $worksheet_array[0];

    # scan for a line that starts with Ref in the 0th column (the orderid column), and PRIMER_NAME in the 4th column
    my $oligo_info = 0;
    my %oligo_hash;

    foreach my $i (2..$sheet->{MaxRow}+1) {
	my $row_cell = $sheet->{Cells}[$i-1][0];	
	unless ($row_cell) {
	    # no value found, skip line
	    next;
	}

	my $order_id_cell = $sheet->{Cells}[$i-1][0];
	my $well_cell = $sheet->{Cells}[$i-1][5];
	my $primername_cell = $sheet->{Cells}[$i-1][6];
	my $order_id = &chomp_edge_whitespace($order_id_cell->Value);
	my $well = &chomp_edge_whitespace($well_cell->Value);
	my $primername = &chomp_edge_whitespace($primername_cell->Value);
	my $solution_cell = $sheet->{Cells}[$i-1][0];
	my $solution_id =  &chomp_edge_whitespace($solution_cell->Value);
	$solution_id =~ s/\_.*//; #take away the notes
	$solution_id =~s/\**SOL[0]+(\d+)?/$1/g;

	# if primername or well has no value, just skip
	unless ($primername) {
	    next;
	}
	unless ($well) {
	    next;
	}
	unless ($order_id) {
	    next;
	}
	if (defined $oligo_hash{"$order_id"}) {
	    push (@{$oligo_hash{"$order_id"}},[$primername,$well,$solution_id]);
	}
	else {
	    $oligo_hash{"$order_id"} = [[$primername,$well,$solution_id]];
	}
	next;

    }
    return \%oligo_hash;
}


##############################################
# Helper function
# reads an IDT yield report
# Return: a hashref of {order_name} => [primer_name,well]
##############################################
sub _read_IDT_yield_report {
##############################################
    my %args = &filter_input(\@_,-args=>'file',-mandatory=>'file');

    my $file = $args{-file}; # (Scalar) Filename of the yield report

    # need to read in the Excel file first 
    # need to check if the Excel parser is installed first before trying
    eval {
	require Spreadsheet::ParseExcel;
    };
    if ($@) {
	print "Missing required modules: $@";
	return undef;
    }

    # open the Excel file
    my $oBook = Spreadsheet::ParseExcel::Workbook->Parse("$file");
    my @worksheet_array = @{$oBook->{Worksheet}};
    my $sheet = $worksheet_array[0];

    # scan for a line that starts with Ref in the 0th column (the orderid column), and PRIMER_NAME in the 4th column
    my $oligo_info = 0;
    my %oligo_hash;

    foreach my $i (2..$sheet->{MaxRow}+1) {
	my $row_cell = $sheet->{Cells}[$i-1][0];	
	unless ($row_cell) {
	    # no value found, skip line
	    next;
	}

	my $order_id_cell = $sheet->{Cells}[$i-1][2];
	my $well_cell = $sheet->{Cells}[$i-1][5];
	my $primername_cell = $sheet->{Cells}[$i-1][6];
	my $order_id = &chomp_edge_whitespace($order_id_cell->Value);
	my $well = &chomp_edge_whitespace($well_cell->Value);
	my $primername = &chomp_edge_whitespace($primername_cell->Value);
	my $solution_cell = $sheet->{Cells}[$i-1][0];
	my $solution_id =  &chomp_edge_whitespace($solution_cell->Value);
	$solution_id =~s/\**SOL[0]+(\d+)?/$1/g;

	# if primername or well has no value, just skip
	unless ($primername) {
	    next;
	}
	unless ($well) {
	    next;
	}
	unless ($order_id) {
	    next;
	}
	if (defined $oligo_hash{"$order_id"}) {
	    push (@{$oligo_hash{"$order_id"}},[$primername,$well,$solution_id]);
	}
	else {
	    $oligo_hash{"$order_id"} = [[$primername,$well,$solution_id]];
	}
	next;

    }
    return \%oligo_hash;
}


return 1;
