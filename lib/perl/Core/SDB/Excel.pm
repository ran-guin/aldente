############
# Excel.pm #
############
# This module facilitates some simple Excel based functionality
###################
package SDB::Excel;
use strict;
use RGTools::RGIO;    ## general tools module required
use FindBin;

########################
sub load_Parser {
########################
    my %args = filter_input(\@_);
    my $file = $args{-file};
    
    my $ok = "require Spreadsheet::ParseXLSX" || "require Spreadsheet::ParseExcel";
    
    if (!$ok) {
        ## dynamically add Excel to use lib in Imported directory ##
        push @INC, $FindBin::RealBin . "/../lib/perl/Imported/Excel/";  ## custom path
        $ok = "require Spreadsheet::ParseXLSX" || "require Spreadsheet::ParseExcel";
    }
    
    my $parser;
    
    if ( !$file || $file =~ /\.xls$/ ) {
        if ( eval "require Spreadsheet::ParseXLSX") { 
            $parser = Spreadsheet::ParseXLSX->new;
        }
        elsif ( eval "require Spreadsheet::ParseExcel") { 
            $parser = Spreadsheet::ParseExcel->new;
        }
        else {
           Message("Errors: Excel module(s) not loaded for parsing");
        }
    }
    elsif ( $file =~ /\.xlsx$/ ) {
        if ( eval "require Spreadsheet::ParseXLSX") { 
            $parser = Spreadsheet::ParseXLSX->new;
        }
        elsif ( eval "require Spreadsheet::ParseExcel") { 
                print "Error: XLSX module(s) not loaded for parsing- try old xls format instead";
        }  
        else {
            print "Excel module(s) not loaded";
        }
    }
    else {
        print "Expecting xls or xlsx extension";
        #support only excel files
    }

    return $parser;
}   

########################
sub load_Writer {
########################
    my %args = filter_input(\@_, -args=>'file');
    my $file = $args{-file};
    
    my $ok = "require Excel::Writer::XLSX" || "require Spreadsheet::WriteExcel" ;
    
    if (!$ok) {
        ## dynamically add Excel to use lib in Imported directory ##
        push @INC, $FindBin::RealBin . "/../lib/perl/Imported/Excel/";  ## custom path
        $ok = "require Excel::Writer" || "require Spreadsheet::WriteExcel";
    }
    
    my $writer;
    
    if ( !$file || $file =~ /\.xls$/ ) {
        if ( eval "require Excel::Writer::XLSX") { 
            $writer = Excel::Writer::XLSX->new;
        }
        elsif ( eval "require Spreadsheet::WriteExcel") { 
            $writer = new Spreadsheet::WriteExcel($file);
        }
        else {
           Message("Errors: Excel module(s) not loaded - you need to load the Excel::Writer::XLSX module");
        }
     }
    elsif ( $file =~ /\.xlsx$/ ) {
        if ( eval "require Excel::Writer::XLSX") { 
             $writer = Excel::Writer::XLSX->new;
         }
         elsif ( eval "require Spreadsheet::WriteExcel") { 
              Message("Error: XLSX module(s) not loaded for writing - you need to load Excel::Writer::XLSX module<BR>");
         }
         else {
            Message("Error: Excel module(s) not loaded - you need to load the Excel::Writer::XLSX module");
         }
    }
    else {
        print "Expecting xls or xlsx extension";
        #support only excel files
    }

    return $writer;
}

################################################################################################
# save_Excel is a wrapper to enable population of a template excel file with specified data
################################################################################################
#
# This is used to enable dumping data to an excel spreadsheet (specifying a template).
#  Input would be a hash like $hash{$sheet}{$row}{$col} = value... et$module_patc.
#
# <snip>
#  Example:
#  my %cell_contents;
#  $cell_contents{"0:1:5"} = "New cell contents (sheet 0, row 1, column 5)";
#  &save_Excel(-file=>'file.xls',-template=>'template.xlt',-data=>\%cell_contents,
#              -module_path=>"/usr/local/lib/perl").
# </snip>
#
# (It requires the Spreadsheet::ParseExcel::SaveParser module)
#
# Return : Excel:Spreadsheet:WriteExcel object on success (0 on failure).
################
sub save_Excel {
################
    my %args        = &filter_input( \@_, -args => 'template,filename,data', -mandatory => 'template,filename,data' );    ## input filter.
    my $filename    = $args{-filename};                                                                                   ## Filename to save result in
    my $template    = $args{-template};                                                                                   ## Excel template to start with
    my $cell_ref    = $args{-data};                                                                                       ## hash of data to be input to the excel template.
    my $quiet       = $args{-quiet} || 0;                                                                                 ## quiet mode suppresses normal feedback.
    my $module_path = $args{-module_path} || "/usr/lib/perl/";                                                            ## path where Excel module directory exists.

    my %cells = %$cell_ref if $cell_ref;
    
    my $oBook;
    if ( eval "require Spreadsheet::ParseExcel") { 
        $oBook = Spreadsheet::ParseExcel::SaveParser::Workbook->Parse("$template");   
    }
    elsif ( eval "require Spreadsheet::ParseXLSX") { 
        Message("Warning: code needs to be revised to use newer Excel modules");
        return
    }
    else {
        Message("Error: Excel module(s) not loaded during save");
        return;
    }
 
    ## <CONSTRUCTION> - allow option (if no template file) to write to a blank spreadsheet ?...

    my @worksheet_array = @{ $oBook->{Worksheet} };
    foreach my $key ( keys %cells ) {                                                                                     ## perform for every key in data hash...
        my ( $sheet, $row, $col ) = split ':', $key;                                                                      ## parse out sheet : row : col from key.
        my $value = $cells{$key};
        my $oCell = $worksheet_array[$sheet]->{Cells}[$row][$col];
        $worksheet_array[$sheet]->AddCell( $row, $col, $value, $oCell );                                                  ## populate this cell
    }

    my $saved = $oBook->SaveAs("$filename");
    if ($saved) {
        Message("Saved as $filename") unless $quiet;                                                                      ## tell user when file has been saved successfully.
    }
    else { Message("Error saving $filename ? ") }

    return $saved;
}

################
#
# Parse Excel spreadsheet to hash
#
# Input: filename
#2
# Output: hash (eg. { 'Col1'=>[1,2,4], 'Col2'=>['a','b','c'] }
#
################
sub parse_Excel {
################
    my %args = &filter_input( \@_, -args => 'filename', -mandatory => 'filename' );    ## input filter.
    my $filename = $args{-filename};   ## Filename to save result in
    my $dbc = $args{-dbc};                                                 

    my %cells;
    my $parser = load_Parser(-file=>$filename);
 
    my $oBook = $parser->parse("$filename");                                           ## open template file.
    ## <CONSTRUCTION> - allow option (if no template file) to write to a blank spreadsheet ?...
    my %hash;

    my @worksheet_array = @{ $oBook->{Worksheet} };
    foreach my $key ( keys %cells ) {                                                  ## perform for every key in data hash...
        my ( $sheet, $row, $col ) = split ':', $key;                                   ## parse out sheet : row : col from key.
        my $value = $cells{$key};
        print "$key -> $value.\n";
    }

    return \%hash;
}

return 1;
