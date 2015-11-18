##################
# DB_Query_App.pm #
##################
#
# This module is used to monitor Goals for Library and Project objects.
#
package SDB::DB_Query_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::SDB_Defaults;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Benchmark %Settings $html_header);

my $dbc;
my $q;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'Home'      => 'home',
            'Run Query' => 'home',
        }
    );

    $dbc = $self->param('dbc');

    $self->{dbc} = $dbc;
    $q = $self->query();

    return $self;
}

#
# Home page for query tool.
#
##########
sub home {
##########
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $self->param('dbc');
    my $q        = $self->query();
    my $homelink = $dbc->homelink();

    my $page = '<H2>Query Tool</H2>';
    $page .= "<span class='smaller'>";

    my $timestamp = &timestamp();

    #my $homelink = 'query_tool.pl';
    my $keyword = join ',', $q->param('Keyword');
    my @keywords = split ',', $keyword;    ## allow comma-separated list of keywords

    my $driver = $q->param('DB_Driver') || 'mysql';
    my $host   = $q->param('Server')    || $Configs{mySQL_HOST};
    my $dbase  = $q->param('Database')  || $Configs{DATABASE};
    my $user   = $q->param('Username')  || 'viewer';
    my $pwd    = $q->param('Pwd')       || 'viewer';

    my $split         = $q->param('Split');
    my $toggle        = $q->param('Toggle');
    my $border        = $q->param('Border');
    my $width         = $q->param('Width') || '100%';
    my $file          = $q->param('File') || '';
    my $file_type     = $q->param('File_Type') || 'html';
    my $subdir        = $q->param('Subdirectory') || 'tmp';
    my $graph_options = $q->param('Graph Options');

    my $graph = ( $file_type =~ /gif/i );

    if ( $file =~ /^(.*)\.$file_type$/i ) { $file = $1 }    ## strip extension from file if it is redundant ##

    my $stamp = timestamp();
    if ( $file_type eq 'gif' && !$file ) { $file = $stamp }

    my $filename = "$Configs{URL_temp_dir}/$file.$file_type";
    if ($subdir) { $filename =~ s /\/tmp\//\/$subdir\// }

    my $output = '';

    my $hint
        = "<ul><li>Queries:"
        . "<ul><li>NO semicolons after the SQL statements."
        . "<li>Multiple SQL statments can be executed at the same time to generate multiple result sets."
        . "<li>Invididual SQL statements can be commented out by preceding the statements with '#'." . "</ul>"
        . "<li>Other features:"
        . "<ul><li>Highlight keyword: If entered then all occurence of the keyword in the result set will be highlighted for easier spotting."
        . "<li>Show column titles every X rows: If entered then every X rows in the result set will have the column titles displayed.",
        "<li>Show results in new window: If checked then the result set will be displayed in a new browser window." . "</ul>" . "</ul>";

    # $page .= create_tree(-tree=>{'Instructions' => $hint} );

    unless ( $q->param('NewWin') ) {

        #Toggle display result set in a new window or not.
        my $newwin = 0;
        if ( $q->param('ToggleNewWin') && ( $q->param('ToggleNewWin') eq 'true' ) ) {
            $newwin = 1;
        }

        if ($newwin) {
            $page .= alDente::Form::start_alDente_form( $dbc, 'new' );    # -action => $homelink, -method => 'post', -target => '_blank' );
        }
        else {
            $page .= alDente::Form::start_alDente_form( $dbc, 'new' );    # -a print start_form( -action => $homelink, -method => 'post' );
        }

        $page .= $q->hidden( -name => 'Query Tool',      -value => 1 );
        $page .= $q->hidden( -name => 'Session',         -value => $dbc->session->id );
        $page .= $q->hidden( -name => 'cgi_application', -value => 'SDB::DB_Query_App', -force => 1 );

        $page .= "DB Driver: " . $q->textfield( -name => 'DB_Driver', -default => $driver, -size => 8 ) . &hspace(5);
        $page .= "Server: " . $q->textfield( -name    => 'Server',    -default => $host,   -size => 12 ) . &hspace(5);
        $page .= "Database: " . $q->textfield( -name  => 'Database',  -default => $dbase,  -size => 12 ) . hspace(5);
        $page .= "Username: " . $q->textfield( -name  => 'Username',  -default => $user,   -size => 12 ) . hspace(5);
        $page .= "Password: " . $q->password_field( -name => 'Pwd', -default => $pwd, -size => 12, -force => 1 ) . '<br><br>';
        $page .= "Query: (" . &Link_To( "query_tool.pl", "Help", "?Help=1", 'blue', ['newwin'] ) . ")" . '<br>' . $q->textarea( -name => 'Query', -cols => '160', -rows => '10' ) . '<BR>';
        $page .= $q->submit( -name => 'rm', -value => 'Run Query', -class => 'Action' ) . hspace(5);
        $page .= "Highlight keyword(s): " . $q->textfield( -name     => 'Keyword',   -default => '',     -size => 15 ) . hspace(5);
        $page .= "Show column titles every: " . $q->textfield( -name => 'Title_Per', -default => '',     -size => '3' ) . " rows" . hspace(5);
        $page .= "Split Output on: " . $q->textfield( -name          => 'Split',     -default => '',     -size => 4 ) . &hspace(4);
        $page .= "Toggle Colour on: " . $q->textfield( -name         => 'Toggle',    -default => '',     -size => 4 ) . &hspace(4);
        $page .= "Width: " . $q->textfield( -name                    => 'Width',     -default => '100%', -size => 4 ) . hspace(4);

        ### new line ##
        $page .= vspace(5);

        $page
            .= "Save to File: "
            . Show_Tool_Tip( $q->textfield( -name => 'File', -default => '', -size => 20, -force => 1 ), "writes to:<BR>/opt/alDente/www/dynamic/$subdir/<BR>(no extension needed)", -tip_style => "left:-40em" )
            . $q->radio_group( -name => 'File_Type', -values => [ 'gif', 'xls', 'html', 'csv', 'view' ], -default => 'html' )
            . hspace(10)
            . $q->checkbox( -name => 'NewWin', -label => 'Show results in new window', -checked => $newwin, -onClick => "goTo('$homelink','?ToggleNewWin=' + this.checked);" )
            . &hspace(10)
            . $q->checkbox( -name => 'Border', -checked => 0 )
            . &hspace(20)
            . "<B>Write To ->"
            . $q->radio_group( -name => 'Subdirectory', -values => [ 'tmp', 'share' ], -default => 'tmp', -force => 1 )
            . &vspace(5)
            . 'Graphing options: '
            . Show_Tool_Tip( $q->textfield( -name => 'Graph Options', -size => 40 ), 'eg. bar_width=10, colour=blue, x_label_skip=1' )
            . "</form><hr>";
    }

    if ( $q->param('rm') eq 'Run Query' ) {
        my $query = $q->param('Query');
        $query =~ s/\s/ /g;    ## replace linefeeds with simple space
        my $title_per = $q->param('Title_Per');

        my $local_dbc = new SDB::DBIO( -host => $host, -dbase => $dbase, -user => $user, -password => $pwd, -connect => 1 );
        unless ( $local_dbc->{connected} ) { Message("Error: Connection failed for $user \@$host.$dbase (correct above)") }
        while ($query) {
            my $current_query;

            if ( $query =~ /\n+/ ) {
                $current_query = $`;
                $query         = $';
                if ( ( $current_query =~ /^\#/ ) || ( $current_query =~ /^\s$/ ) ) { next; }
            }
            else {
                $current_query = $query;
                $query         = '';
            }

            unless ( $current_query =~ /^\#/ ) {

                if ( $current_query =~ /^select|^desc|^show|^describe|^explain/i ) {    #The query will return a result set.
                    my $sth = $local_dbc->dbh()->prepare(qq{$current_query}) || _error("Prepare query fail: ");
                    $sth->execute() || _error("Execute query fail: ");

                    my $table = HTML_Table->new( -width => $width, -autosort => 1, -border => $border );
                    $table->Set_Class('small');
                    $table->Set_Headers( \@{ $sth->{NAME} } );
                    $table->Toggle_Colour_on_Column($toggle) if $toggle;

                    $page .= $q->h3( 'Results: ' . $sth->rows() . " records returned" );
                    $page .= "<font size=1>Query = $current_query</font><br>";

                    my $row;
                    my $rows            = 0;
                    my $title_per_count = 0;
                    my ( @x_values, @y_values );
                    while ( $row = $sth->fetchrow_arrayref ) {
                        my @record;

                        #See if we need to display column titles.
                        if ( ($title_per) && ( $title_per_count == $title_per ) ) {
                            $page .= $table->Printout( "$Configs{URL_temp_dir}/query.$timestamp.html", $html_header );
                            $page .= $table->Printout( "$Configs{URL_temp_dir}/query.$timestamp.xlsx", $html_header );
                            $page .= $table->Printout(0);

                            $table = HTML_Table->new( -autosort => 1, -border => $border );
                            $table->Set_Class('small');
                            $table->Set_Headers( \@{ $sth->{NAME} } );
                            $title_per_count = 0;
                        }

                        for ( my $i = 0; $i < @{$row}; $i++ ) {
                            my $col = $row->[$i];
                            if ( !defined $col ) {    #Check for NULL values
                                $col = 'undef';
                            }
                            $col = _format($col);
                            push( @record, $col );
                            if ( $i == 0 ) { push @x_values, $col }
                            if ( $i == 1 ) { push @y_values, $col + 0 }
                        }
                        $table->Set_Row( \@record );
                        if ( $file && ( $file_type !~ /html/i ) ) {
                            $output .= join "\t", @record;
                            $output .= "\n";
                        }
                        $title_per_count++;
                        $rows++;
                    }

                    $sth->finish();
                    my $URL_temp_dir = $dbc->config('tmp_dir') || '/tmp';


                    if ($file) {
                        $page .= "Link to new File: <A Href='/SDB/dynamic/$subdir/$file.$file_type'>$file.$file_type</A><BR>";
                        if ( $file_type =~ /html/i ) {
                            $output .= $table->Printout(0);    ## "$URL_temp_dir/$file.$file_type",$html_header);
                            $page   .= $table->Printout(0);
                        }
                        elsif ( $file_type =~ /xls/i) {
                            my $path = $dbc->config('tmp_dir');
#                            $output .= $table->Printout();    ## "$URL_temp_dir/$file.$file_type",$html_header);
                            $page   .= $table->Printout("$path/$file.$file_type");                           
                        }
                        elsif ( $file_type =~ /gif/i ) {
                            my %options;
                            if ($graph_options) {
                                while ( $graph_options =~ s /(\w+)=(\S+)// ) {
                                    $options{ -$1 } = $2;
                                }
                            }
                            require RGTools::Graph;
                            Graph::generate_graph( -x_data => \@x_values, -y_data => \@y_values, -output_file => $filename, %options );
                            $page .= "<IMG SRC='/dynamic/$subdir/$file.$file_type'/>";

                        }
                    }
                    my $extension = 'xls';
                    $page .= $table->Printout( "$URL_temp_dir/query.$timestamp.html", $html_header );
                    $page .= $table->Printout( "$URL_temp_dir/query.$timestamp.$extension", $html_header, -link_text=>'Excel File');
                    
                    $page .= "<br><b>$rows row(s) returned</b>";
                }
                else {    #The query will NOT return a result set.
                    my $rows = 0;
                    $page .= $q->br;
                    $rows = $local_dbc->dbh()->do(qq{$current_query}) || _error("Do query fail: ");

                    $page .= $q->h3("Results: $rows returned");
                    $page .= "<font size=1>Command = $current_query</font><br>";

                    if ( !$rows ) {
                        _error("Do query fail: ");
                    }
                    else {
                        $rows += 0;
                        $page .= "<br><b>$rows row(s) affected</b>";
                    }
                }

                $page .= $q->hr;
                if ( $file_type eq 'view' ) {
                    parse_to_view( $local_dbc, $file, $current_query );
                }
            }
        }
        $local_dbc->disconnect();
    }

    if ( $file && ( $file_type !~ /gif/ ) ) {
        open my $FILE, '>', $filename or $page .= "Error: Cannot open file: '$filename'\n";
        print {$FILE} $output;
        close $FILE;
        Message("Wrote to file : $filename");
    }

    return $page;
}

#################
# Format record
###############
sub _format {
#############
    my $value = shift;

    my @keywords;
    my $split;
    foreach my $keyword (@keywords) {    #Check to see if data contains keyword for highlights
        if ( $value =~ /$keyword/g ) { $value = "<font color='red'><b>$value</b></font>"; last; }
    }
    if ($split) {
        $value =~ s/$split/$split<BR>/g;
    }
    return $value;
}

sub _error {
    my $msg = shift;

    $page .= "<font color='red'>$msg$DBI::err ($DBI::errstr)</font>";
}
return 1;
