################################################################################
#
# This is a general module for the help.
#
################################################################################
################################################################################
# $Id: Help.pm,v 1.11 2004/09/08 23:31:48 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.11 $
#     CVS Date: $Date: 2004/09/08 23:31:48 $
################################################################################
package alDente::Help;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Help.pm - This is a general module for the help.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This is a general module for the help.<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

use CGI;

my $q = new CGI
##############################
    # system_variables           #
##############################
    require Exporter;
@EXPORT = qw(
    SDB_help
    Help_Links
    Online_help
    Online_help_search
    Online_help_search_results
);
@EXPORT_OK = qw(
    SDB_help
    Help_Links
    Login_Help
    Revision_2001_01_01_Help
    Revision_2002_02_18_Help
    Revision_2001_10_16_Help
    Revision_2001_09_24_Help
    Revision_2001_09_10_Help
    Revision_2001_08_13_Help
    Revision_2001_07_30_Help
    Revision_2001_07_16_Help
    Revision_2001_07_03_Help
    Revision_2001_06_18_Help
    Revision_2001_06_04_Help
    Revision_2001_05_21_Help
    Revision_2001_05_07_Help
    Revision_2001_04_23_Help
    Revision_2001_04_02_Help
    Revision_2001_03_19_Help
    Revision_2001_03_05_Help
    Revision_2001_02_12_Help
    Revision_2001_02_05_Help
    Revision_2001_01_22_Help
    Revision_Help
    Revision_Help_Old
    Summary_Help
    Warnings_Help
    Icons_Help
    Online_help
    Online_help_search
    Online_help_search_results
    OH_Main_Flow
    OH_Phred_Analysis
    OH_Solution_Flow
    OH_Rearray_definitions
    OH_Mixing_solutions
    OH_new_reagents
    OH_new_plates
    OH_new_libraries
    OH_new_projects
    OH_making_changes
    OH_deleting_mistakes
    OH_making_notes
    OH_Stock_Help
    OH_ReArray_Help
    OH_Scanner_Help
    OH_ReBooting
    OH_Protocols
    OH_Protocol_Formats
    OH_Manual_Analysis
    OH_Debugging_Errors
    OH_DB_Modules
    OH_Restoring_Database
    OH_Slow_Response_Time
    OH_Chemistry_Calculator
    OH_New_Sequencer
    OH_Sample_Sheets
    OH_Directories
    OH_Poor_Quality_Runs
    OH_Command_Line_Scripts
    OH_Module_Routines
);

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use DBI;

#use Frontier::Client;
use strict;

##############################
# custom_modules_ref         #
##############################
use alDente::SDB_Defaults;
use alDente::Summary;
use alDente::Form;

use RGTools::Views;
use RGTools::RGIO;
use RGTools::HTML_Table;
use SDB::HTML;
use SDB::CustomSettings;

##############################
# global_vars                #
##############################
use vars qw($homefile $SDB_web_dir $page $help_dir $URL_address);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $Huser = param('User') || '';
$Huser =~ s/ /+/g;
my $Hproject = param('Project') || '';
$Hproject =~ s/ /+/g;
my $Database       = param('Database');
my $Help_Image_dir = "/SDB/images/help_images";    # = "/images/help_images";
my $Image_dir      = "/SDB/images/png";
my $code_version   = $Configs{CODE_VERSION};

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

##################
sub SDB_help {
##################
    my %args = filter_input( \@_, -args => 'topic' );
    my $topic    = $args{-topic} || "";
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();
    my $user_id  = $dbc->get_local('user_id');

    my $page = "$topic Help";

    my $full_list;
    my $primary_list;
    if (1) {    ## $topic) {   ### more recent help retrieval...(Mar/2002)

        my $help_link   = $homelink;
        my $manual_link = "$URL_address/../docs/";    ## "http://seqdb01/SDB/docs/";

        #	if ($homelink=~/(.*)\/barcode/) {
        unless ($help_link) {
            $help_link = "$1/help.pl?User=Auto";
        }
        print &vspace(10);
        print alDente::Form::start_alDente_form( $dbc, 'HelpForm', $help_link ) .
            $q->submit( -name => 'Search for Help', -style => "background-color:yellow" ) . ' on: ' . $q->textfield( -name => 'Help', -size => 20 ) . "</Form>" . "<HR>";
        print &Link_To( $manual_link . "out/index.html", 'alDente User Manual' ) . &hspace(5) . &Link_To( $manual_link . "manual/System_Description.pdf", 'System Description' );

        #print &hspace(5) . Link_To( $manual_link . 'manual/this_release', 'Release Changes');
        print &hspace(5) . Link_To( '', 'Release Changes', "http://www.bcgsc.ca/wiki/display/lims/Upgrade+Release+$code_version" );
        print "<HR>";

#print '<object id="scPlayer"  width="1020" height="577" type="application/x-shockwave-flash" data="http://limsdev02/SDB_rguin/docs/manual/login.swf" >  <param name="movie" value=http://limsdev02/SDB_rguin/docs/manual/login.swf />  <param name="quality" value="high" />  <param name="bgcolor" value="#FFFFFF" />   <param name="allowFullScreen" value="true" />  <param name="scale" value="showall" />  <param name="allowScriptAccess" value="always" />  Unable to display content. Adobe Flash is required. </object>';

        #print "<HR>";

        #	my @help_files = split "\n",try_system_command("ls $help_dir/*.html");

        Message("Warning: Help doc missing -> Please convert manual to local help dir: $help_dir/*.html") unless ( -e "$help_dir/" );

        my @help_files = <$help_dir/*.html>;
        my @files = grep /\/$topic.html$/i, @help_files;

        unless ( $files[0] ) {    ## if not exact, look for something similar...
            @files = grep /$topic/i, @help_files;
        }

        #	 if ($#files>=0) {
        #	     my %file;
        #	     foreach my $find (@files) {
        #		 if ($find=~/$help_dir\/(.*)\.html/) {
        #		     $file{$1} = 1;
        #		 }
        #	     }
        #	     my @keys = sort {$a <=> $b} keys %file;
        #
        #	     if (($#keys>=0) && !($files[0]=~/No such file/i))  {
        #		 $list = "<UL>";
        #		 foreach my $find (@keys) {
        #		     $list .= "<LI>".&Link_To($help_link,$find,"&Quick+Help=$find",'blue',['newwin']);
        #		 }
        #		 $list .= "</UL>";
        #	     }
        #	     else {$list = "Nothing Found";}
        #	 }
        #
        my $found_file    = 0;
        my $header_colour = 'blue';
        my @toggle_colour = ( 'lightgrey', 'lightyellow' );
        if ( $#files == 0 && ( $files[0] =~ /\/($topic\..*)/i ) ) {    ## exact name found...
            my $file = $1;
            print "<B>File found: $file</B><P>";
            $found_file = 1;
            my $help_txt = try_system_command("cat $help_dir/$file");

            ### replace some variables as required.. ####
            $help_txt =~ s/\$Help_Image_dir/$Help_Image_dir/g;
            $help_txt =~ s/\$homelink/$homelink/g;
            $help_txt =~ s/\$help_link/$help_link/g;
            $help_txt =~ s/\$user_id/$user_id/g;
            $help_txt =~ s/\$URL_address/$URL_address/g;

            my $headings;
            while ( $help_txt =~ s /<([hH]\d+)>(.*?)<(\/[hH]\d+)>/\.HEADING\./i ) {
                my $header     = $1;
                my $heading    = $2;
                my $sub        = "<$1>$2<$3>";
                my $sub_header = '';
                if ( $header =~ /h1/i ) {
                    $sub_header = &Views::Heading($heading);
                }
                elsif ( $header =~ /h2/i ) {
                    $sub_header = &Views::sub_Heading( "<B>$heading</B>", 1, 'class=lightbluebw' );
                }
                elsif ( $header =~ /h3/i ) {
                    $sub_header = &Views::sub_Heading( "<B>$heading</B>", 2, 'class=vlightbluebw' );
                }
                else {
                    $sub_header = "<P><B>$heading</B><P>";
                }
                $help_txt =~ s /\.HEADING\./$sub_header/g;
                $headings++;
            }
            my $index = 0;
            $help_txt =~ s/\$toggle_colour1/bgcolor=$toggle_colour[0]/g;
            $help_txt =~ s/\$toggle_colour2/bgcolor=$toggle_colour[1]/g;
            $help_txt =~ s/\$header_colour/bgcolor=$header_colour/g;
            print $help_txt;

            #		&main::leave('empty');
        }

        #	elsif ($#files < 0) {print "<B>Nothing found like $topic</B>";}

        ## continuing only if exact file not specified.. ##

        my @found = split "\n", try_system_command("grep -ni '$topic' $help_dir/*.html") || 'Nothing';
        my %file;

        my %Sections;
        my %Titles;
        foreach my $find (@found) {
            my $filename = '';
            if ( $find =~ /$help_dir\/(.*?)\.html/ ) {
                $filename = $1;
                $file{$filename} = 1;
            }
            while ( $find =~ s /<title>(.{0,100})<\/title>// ) {
                my $section = $1;
                push @{ $Sections{$filename} }, $section;
                if ( $section =~ /$topic/i ) {
                    push @{ $Titles{$filename} }, $section;
                }
            }
        }

        my @keys = sort { $Sections{$a}[0] <=> $Sections{$b}[0] } keys %Sections;
        if ( $#keys >= 0 ) {
            $full_list    = "<UL>\n";
            $primary_list = "<UL>\n";
            foreach my $filename (@keys) {
                unless ( $filename =~ /^\S+$/ ) { next; }
                if ( defined $Sections{$filename} ) {
                    foreach my $section ( @{ $Titles{$filename} } ) {
                        $primary_list .= "<LI> " . &Link_To( $manual_link . "out/", "$section", "$filename.html", undef, ['newwin'] ) . "\n";
                    }
                    $full_list .= "<LI> " . &Link_To( $manual_link . "out/", "$Sections{$filename}[0]", "$filename.html", undef, ['newwin'] ) . "\n";
                }
            }
            $primary_list .= "</UL>\n";
            $full_list    .= "</UL>\n";
        }
        else { $primary_list = "Nothing Found"; }

        unless ($found_file) {
            my $output = HTML_Table->new( -title => "Help files found on topic: '$topic'", -width => '100%', -border => 1 );
            $output->Set_Headers( [ "Sections with '$topic' in title", "Sections with '$topic' in content" ] );
            $output->Set_Row( [ $primary_list, $full_list ] );
            $output->Printout();
        }
        return $page;
    }

    #
    #    if (param('Banner+Off')) {$homelink .= "&Banner+Off=1";}
    #

    print "<Table><TR><TD bgcolor = yellow>";

    #    "<B>HELP: </B>",
    &Help_Links( "<img src='$Image_dir/Space.png' width=15 height=1>", -dbc => $dbc );
    print "</TD></TR></Table>";

    print alDente::Form::start_alDente_form( $dbc, 'help' ), $q->submit( -name => 'Search for Instructions', -style => "background-color:yellow" ), " on: ", $q->textfield( -name => 'Instruction String' ), end_form();

    print "<HR>";

    if    ( param('Login') )     { &Login_Help();            return 1; }
    elsif ( param('Revisions') ) { &Revision_Help('latest'); return 1; }
    elsif ( param('Revision') ) { &Revision_Help_Old( param('Revision'), -dbc => $dbc ); return 1; }
    elsif ( param('Summary') )  { &Summary_Help();  return 1; }
    elsif ( param('Warnings') ) { &Warnings_Help(); return 1; }
    elsif ( param('Icons') ) { &Icons_Help( -dbc => $dbc ); return 1; }

    ########### specific help is available through Online_help.pl routines

    elsif ( param('New Library') ) { print &OH_new_libraries(); return 1; }
    elsif ( param('ReArray') )     { print &OH_ReArray_Help();  return 1; }
    elsif ( param('Stock') )       { print &OH_Stock_Help();    return 1; }
    elsif ( param('Protocol') )    { print &OH_Protocols();     return 1; }
    elsif ( param('Scanner') )     { print &OH_Scanner_Help();  return 1; }

    elsif ( param('View Index Errors') ) { &Warnings_Help(); return 1; }

    print &Views::Heading("Sequencing Database Page Information");

    print "The Sequencing Database application is located at: <p ></p>", "<A Href = 'http://seq.bcgsc.bc.ca/cgi-bin/barcode'>http://seq.bcgsc.bc.ca/cgi-bin/barcode</A>", "<p ></p>", "a similar page (",
        "<A Href = 'http://seq.bcgsc.bc.ca/cgi-bin/scanner'>http://seq.bcgsc.bc.ca/cgi-bin/scanner</A>",
        ") is used for the barcode scanners.  This is used as an interface to the Sequencing Database, and provides functionality for tracking plates, solutions, equipment etc in the lab.", "<p ></p>";

    print "Further help is available in the following areas:<Br>";

    &Help_Links( -dbc => $dbc );

    print "<HR>More information on the database structure itself can be found at the Sequencing Database Page: ", "<A Href = '/sequencing.shtml'>http://rgweb.bcgsc.bc.ca/sequencing.shtml</A>", "<p ></p>", "<hr>",
        "... For more detailed information, see Ran Guin in BioInformatics";

    return 1;
}

###################
sub Help_Links {
###################
    my %args      = filter_input( \@_, -args => 'separator' );
    my $separator = $args{-separator};
    my $dbc       = $args{-dbc};
    my $homelink  = $dbc->homelink();

    $separator ||= "<BR>";

    print "<Nobr>", "<A Href = '$homelink&Help=1'>", "Home", "</A>", $separator, "<A Href = '$homelink&Help=1&Login=1'>", "Log In", "</A>", $separator, "<A Href = '$homelink&Help=1&Icons=1'>", "Icons", "</A>", $separator,
        "<A Href = '$homelink&Help=1&New+Library=1'>", "New Library", "</A>", $separator, "<A Href = '$homelink&Help=1&Summary=1'>", "Summary",  "</A>", $separator, "<A Href = '$homelink&Help=1&Warnings=1'>", "Warnings", "</A>", $separator,
        "<A Href = '$homelink&Help=1&Revisions=1'>",   "Changes*",    "</A>", $separator, "<A Href = '$homelink&Help=1&ReArray=1'>", "ReArrays", "</A>", $separator, "<A Href = '$homelink&Help=1&Stock=1'>",    "Stock",    "</A>", $separator,
        "<A Href = '$homelink&Help=1&Protocol=1'>",    "Protocols",   "</A>", $separator, "<A Href = '$homelink&Help=1&Scanner=1'>", "Scanner",  "</A>", "</Nobr>";

    return 1;
}

#####################
sub Login_Help {
#####################

    print &Views::Heading("Logging In:");
    my $Login = HTML_Table->new();
    $Login->Set_Line_Colour( 'white', 'white' );

    #    $Login->Set_Title('<H1>Logging In</H1>','white');
    $Login->Set_Row(
        [   "<H3>Logging In:</H3>To log in, simply select your name from the popdown menu and hit the LOGIN button.<BR>Note that important messages can now be found just below the login button on this page.<BR>If you wish there are a couple of additional options available...",
            "<Img src='$Help_Image_dir/Login.png'>"
        ]
    );

    $Login->Set_Row(
        [   "<HR><H3>Project:</H3>You may select one project, all active projects, or all projects.  The effect of selecting only one project is that only associated libraries and plates may appear on the pull-down menus, making the lists significantly smaller.<BR>(By default all active projects are selected.  To select a single project, choose one from the pop-down menu and DE-select the All Active Projects checkbox.<p ></p>(A list of Active projects is also displayed for your information.",
            "<Img src='$Help_Image_dir/Login_Project.png'>"
        ]
    );

    $Login->Set_Row(
        [   "<HR><H3>Database:</H3>This allows you to actually select a different database.  (This should generally never be used, but may be useful if you wish to try something without affecting the primary database).",
            "<Img src='$Help_Image_dir/Login_Database.png'>"
        ]
    );

    $Login->Set_Row( [ "<HR><H3>Banner:</H3>This allows you to turn off (or on) the GSC banners at the top/bottom of the page.  This may allow more of the screen to be usable.", "<Img src='$Help_Image_dir/Login_Banner.png'>" ] );

    $Login->Set_Row( [ "<HR><H3>Nav Bar:</H3>This allows you to turn off (or on) the Navigation Bar at the left side of the screen", "<Img src='$Help_Image_dir/Login_NavBar.png'>" ] );

    $Login->Printout();

    return 1;
}

###################################
sub Revision_2001_01_01_Help {
###################################
    #
    #
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

    print &Views::Heading("This is the Baseline Version"), "(lots of revisions were made in generating this version, but they are too many to list)", "<HR>";

    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2002_02_18_Help {
###################################
    # missing images:
    #    fkeys.png
    #    capData.png
    #    libHome.png
    #    openSol.png

    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

################## Feb 18th revisions ############################
    my $output = "Added Features:

\n<OL>
\n<LI>Hyperlinks will now be generally redirected to a new window to allow the original window to remain.  (Subsequent links will continue to be directed to the same new window so that only one additional window is generated).
\n
\n<LI>An extra field will show up on many views indicating other tables that reference a given record (a hyperlink will provide a link to this other table).
\n<BR><Img Src='$Help_Image_dir/fkeys.png'>
<BR>
eg. in this list of plates, the 'FKeys->' field indicates that these plates are referenced by the 'Plate_Set','Preparation' and 'Run' tables.<BR>(Mening that the plate has been defined in at least one plate set, has been associated with a Preparation step, and has been sequenced)<BR>
The records referencing this plate may be viewed by clicking on one of these table names.
<BR>
\n
<LI>Monitoring Capillary Status<BR>From the Summary page, there is a button allowing the user to see a graph illustrating average quality as well as the total number of reads by capillary.  Changing of capillaries should also be entered on the Maintenance page from now on.
<BR><Img Src='$Help_Image_dir/capData.png'>

\n<LI>Quick views for Project, Library, Primer info on the top of the 'Library' home page.
<BR><Img Src='$Help_Image_dir/libHome.png'>

\n<LI>More readable Dates (in 'Feb-28-2001' form rather than '2001-02-28')

\n<LI>Last 24 Hours page ordered by Library, Sequencer to make it easier to find specific runs.

\n<LI>Solutions & Reagents may be opened or finished with a specific date (defaults to current date) on Reagents page.
<BR><Img Src='$Help_Image_dir/openSol.png'>

\n<LI>A bit more information appears on the Run Views (including Plate information and the directory path for the chromat files)..
</OL>

\n<HR>\n
    
NOTE: A number of changes have been made in the background that should not change much for the lab user.  In the process of tidying up some of the code, however, it is possible that gaps have been created that will cause minor problems.
\n<BR>
\nIf anything of this sort is noted, please try to let us know as soon as possible.\n 
<BR> images in $Help_Image_dir<BR>
\n<HR>";

    print $output;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_10_16_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

#############  Oct 16th revisions ########################

    my $output = "\n

<H2>Integration with Orders Database</H2>
<P>
The sequence database is now re-structured to allow integration with the Orders database,<BR>
though there will inevitably be a transition period during which there
will remain gaps in this connection.  <P>
In accomplishing this, a number of fundamental changes have been made to 
the way in which some data is stored in the sequencing database. <P>
In the long run this will make things much cleaner, more flexible, and more robust, but a few unexpected glitches are bound to accompany these changes.<P>
I have tried to forsee as many of these as possible, but there are likely a few required adjustments that I have missed.<p ></p>
It will help a great deal in making this transistion as smooth as possible, if any problems are reported ASAP.<BR> 

<H2>DNA Quantitation Info, Clone Info</H2>
<P>
DNA Quantitation Info and Original Clone Info (if sent from External Source) can now be accessed when
other Plate Information appears by clicking on the appropriate buttons...<BR>
<Img Src='$Help_Image_dir/plateops.png'>

<H2>Aliquoting option in Protocols</H2>
There is now an option for specifying Aliquoting plates
in protocol steps...<BR>
Specific formats for Step Names are also supplied for the 
special cases of<UL>
<LI>Transfer 
<LI>Aliquot
<LI>Pre-Print  
</UL>
<P>
";

    print $output;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_09_24_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

#############  Sept 24th revisions ########################

    my $output = "\n

<H2>24 Hours View</H2>
<P>
Run Batches will now be grouped together in a larger image
showing each of the four quadrants together<BR>
(normally with a,b quadrants on the top and c,d quadrants on the bottom).
<P>
Note that this still keeps the original quadrants together, so that each 96-well plate section is viewed as one block.<BR>(The actual 384 well overlaps the plates in alternating wells)<BR>
To View the wells as they actually appear (interleaved) on the 384,<BR>
click on the 'I-leave' link to the right of the 4 plates.
<Img src='$Help_Image_dir/Interleaved.png'>
<H2>Library Page</H2>
<P>
There are now options available for viewing suggested Primers/Antibiotics for Libraries, as well as viewing/setting Project, Vector Information
<BR>
<Img src='$Help_Image_dir/LibHome.png'>
<H2>Summary Page</H2>
<P>
The Project Summary statistics now includes Phred20 rather than 'Quality Length', as well as totals calculated for each project (and overall if more than one Project selected).<BR>
<Img src='$Help_Image_dir/ProjStats.png'>

\n<HR>\n";

    print $output;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_09_10_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

#############  Sept 10th revisions ########################

    my $output = "\n

<H2>Test Plates</H2>
<P>
Plates can now be marked as 'Test' Plates.  This is available when you create the plates,<br>and may also be set on the 'Select No Grows' page.<BR>(There is an option at the bottom to specify 'Test' or 'Production' Plates<BR>- You may also specify to set past or future generation plates to a similar test status).
<P>
This is not yet used to extract 'Test Runs', allowing time for this change to be worked into everyone elses code, but soon the 'Test' Status for Runs will no longer be available, and 'Test Runs' will be determined by the Plate Test Status.

<H2>Session Tracking</H2>
<P>
Although invisible to users I am now able to track in detail all steps performed using the scanner (or barcode page).<BR>
This will allow me to debug problems more easily and monitor protocol tracking.<BR>
It also allows me to choose any point during your session and go directly to the same page.

<H2>Error Notification</H2>
<P>
You can now notify me of errors by simply pressing a button at the bottom of the page.<BR>
You may optionally type in a note if desired as well.<BR>
This will tell me the time of the error so that I can examine in detail the session that you were in, and all of the steps that were followed (and all barcodes scanned).
<Img Src='$Help_Image_dir/Errors.png'>

<H2>Solution Components Displayed</H2>
<P>
When you scan a solution, if there is no catalog number associated with it (for Reagents),
the list of reagents used to make up the solution will be displayed at the bottom of the screen.<BR>
(This will appear on the scanners as well).
<Img Src='$Help_Image_dir/reagents.png'>

<P> 
<H2>Minor Changes</H2>
<UL>
<LI>
Chemistry Calculator calculations have been adjusted once again.
<LI> 
You may now generate sample sheets for more than one 384 well plate at one time.
<LI>There is now an automatic chemistry calculator for NH4OAc.
</UL>
\n<HR>\n";

    print $output;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_08_13_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## Aug 13th revisions ########################

    my $output = "\n

<H2>Diagnostics Page</H2>
<P>
Poor Quality Warnings will now be sent (to Duane) - indicating possible factors in poor quality sequence runs.<BR>The detailed Diagnostics summary now contains a colour legend at the right.<BR>
Poor Quality Runs (phred20 < 400) are highlighted in red.
<Img Src='$Help_Image_dir/diagbuffer.png'>
<P>
Primers should now link automatically to plates during sample sheet generation.<BR>
(All original reagents used in making up solutions are correlated with all plate ancestors)
<P>
<H2>Minor Changes:</H2>
<P>
<UL>
<LI>Mirrored Data files are automatically compressed (and originals removed) after 1 month.
<LI>Database backup files are also automatically compressed after they are a couple of days old.
<LI>There is space in the database for Miscellaneous Items and Batches of Miscellaneous Items.  (used to monitor Stock supplies etc.)
</UL>
<H2>Minor Fixes:</H2>
<P>
<UL>
<LI>70% Ethanol chemistry calculator is now working for the scanner.
</UL>

\n<HR>\n";

    print $output;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_07_30_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## July 30th revisions ########################

    my $output = "\n

<H2>Last 24 Hours Page</H2>
<P>
A number of features are now visible on the 24 Hours Page including:
<UL>
<LI>Comments for runs are displayed on the far right.
<LI>Test Runs have comments on a light red background
<LI>Production Runs have comments on a light green background
<LI>384 Well runs are indicated by a 'N/384' in the Wells column
<LI>Library names appear more prominently.
<LI>Primers are indicated in red with the Chemistry Code.
</UL>
<Img Src='$Help_Image_dir/New24Hours.png'>

<H2>Diagnostics Page</H2>
<P>
This page allows overall equipment/solution variables to be correlated against
Run Read Quality, providing easy to view graphs depicting quality variations for a variety of process and conditions.
<Img Src='$Help_Image_dir/DiagEx.png'>

<H2>Comparing Plate Histories</H2>
<P>
The detailed preparation procedures can be compared for two plates by simply scanning the two plates at the home page and selecting 'Compare Plate Histories'.
<P>
A plate history will then be generated for both plates highlighting the differences between the two.

<H2>Selecting Slow Grows/No Grows/Unused Wells</H2>
<P>
It is now quicker to select slow grows, no grows and Unused wells.
<P>
by clicking on a button at the bottom, the display will automatically toggle between Slow Grow / No Grow / or Unused Well entries.
<Img Src='$Help_Image_dir/NewGrowth.png'>

<H2>Chemistry Calculator</H2>
<P>
The chemistry calculator is now set up for 70% EtOH Solutions as well as 4 and 10ul Big Dye Brew mixes.
<P>
For Brew Mixes, the scanner offers a pulldown menu to choose ET Brew Mix, 4ul Big Dye Brew Mix or 10ul Big Dye Brew Mix.
<P>
On the computer screen, a single button appears for the Big Dye brew mix. <P>
You can then adjust the number of plates or toggle between 4ul and 10ul choices by simply pressing a button.<P>
The calculations will then be automatically done on the fly.

<H2>Units Specifications</H2>
<P>
In some instances, ul of volume are easier to enter, though the database generally tracks volumes in mils.<P>
Quantities can now be entered with a 'u' suffix to indicate ul. <P>
(Defaults already make use of this nomenclature to make small quantities more readable)

<H2>Protocols</H2>
<P>
A few changes to the options available when defining protocols include the ability to specify a Name format required for Solutions,
and an Equipment Type format for Equipment used during plate preparation procedures.

<H2>Sample Sheets</H2>
<P>
Users will be forced to enter '96 well' or '384 well' on the Sample Sheet generation page, to ensure that this is correctly set.<P>
(as opposed to simply forgetting to set it, and having the resulting plate size be incorrect).
<P>
Users will also be forced to enter 'Production' or 'Test' for runs, 
similarly ensuring that runs are not labelled Production simply because someone forgot to mark it as Test.
<P>
Test runs will soon be associated with plates rather than sequencing runs, and this step will be required when generating new plates.

\n<HR>\n";

    print $output;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_07_16_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## July 16th revisions ########################

    my $output = "\n

<H2>Error Checking</H2>
<P>
You can now specify Solution_Name Requirements for Protocols and for standard Solutions, as well as Equipment Types required for Protocols.
<P>
This means that if you scan in 'ET Premix' where 'BD Premix' is expected, an error will appear to the user indicating that the required solution was not of the expected type...
<P>
Similarly if a Hydra is scanned where a Centrifuge is expected, an error will appear to the user indicating that a Centrifuge should be scanned.
<P>
<H2>Transferring Plates</H2>
<P>
You may quickly transfer multiple plates to a specified format after scanning a group of plates from the home page.
<BR>
<img src='$Help_Image_dir/transfer_plates.png'>
<P>
<H2>Adding Comments to Sequence Runs</H2>
<P>
You may select a number of runs to annotate at one time from the Run page.<BR>
<img src='$Help_Image_dir/sequence_comments.png'>
<P>
<H2>Orders Page being Tested</H2>
<img src='$Help_Image_dir/box.png'>
<P>
There is now a direct link to the Orders home page.
(Note: The data in the Orders database is not up to date, and is available for test purposes only until
it is fully integrated.)
<P>
<H2>Minor Changes</H2>
    <UL>
    <LI>
    There is now a place to record Transposon Antibiotic Markers where appropriate.<BR>
    (You may be prompted for this when specifying a new Transposon).
    <LI>
    Solution Names are automatically changed from 10X to 1X when dilution with water is chosen.<BR>
    (This is set up since this dilution is particularly common)
    <LI>
    Chemistry Calculator has been updated.
    </UL>
<P>
\n<HR>\n";

    print $output;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_07_03_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## July 3rd revisions ########################

    my $output = "\n
<H2>Beginning to Integrate Administrative Orders Database</H2>
<P>
This will lead to the ability to track detailed costs within the lab, by connecting the Administrative database (which records unit costs for individual orders) with the Laboratory database for Equipment, Reagents etc.)
<P>
(This is not yet fully functional, but hopefully will soon be on line..)
<Img Src='$Help_Image_dir/Stock.png'>
\n<HR>\n
\n";

    print $output;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_06_18_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## June 18th revisions ########################

    my $output = "\n

<H2>Slightly new home page</H2>
<P>
Actually there isn't much different here.  <BR>
I just thought it looked a little boring so I added a small bar with a few interesting quotes to distract users, and an option that allows users to search for help on various topics (such as 'Adding Plates', 'Adding Libraries' etc.)
<P>
(It will search through all of the text under each topic for the string that you enter, and list the possible help topics)
<P>
Please give me suggestions for 'Help' topics that would be of value and I can try to include them.
<P>
<Img Src='$Help_Image_dir/new_home.png'>
<p ></p>
<H2>Multi_Plate Barcodes</H2><P>
Multi-Plate Barcodes are now generated via the 384 Well Protocol. The barcodes will generally look like: <BR><B>1111.1112.1113.1114    TL001-003  2001-06-05   ALP  A</B><BR>
<P>
(<B>Note:</B> The Library, Date, Initials and Quadrant values are extracted from the first 96-well plate in the list)<P>
To generate this barcode, you should define the plate set, and utilize the 384 well protocol.  During the 'Transfer to 384 Well' step, the multi_plate barcodes should automatically be generated.  You may transfer any multiple of 4 plates at one time.<br>eg. If you define a plate set of 12 plates, it will automatically assign the first 4 to one multi-plate barcode, the following 4 to another multi-plate barcode etc.
<P>
To re-print the same barcode, simply scan the original at the homepage, and press the 'Re-Print Multiple Plate Barcode' at the top of the page.<BR>
NOTE: This prints an identical barcode to the previous (indistinguishable).  To make note of differences in preparations, notes should be added to the respective Sequence Runs as required.
<H2>Cost Tracking</H2><P>
I have begun to track costs for Reagents in the database, providing with particularly detailed costing information for processes involved in Sequencing.<BR>
This should provide costing as well for plasticware and Sequencing runs, based on the costs of the buffers/matrices etc.
<P>
For all mixtures that are made from now on, the value of the final mixture is calculated based upon the costs of the reagents used. <BR>
This of course is dependant upon the original costs being input into the database when they are recieved - something that is NOT yet up-to-date.
<P>
This is still in its early stages, and feedback is crucial to make this useful.  Once costs (primarily those of Reagents) are up-to-date, a Library costing summary should be available that would show information such as the following:
<P>
(NOTE: this is an example and does NOT reflect actual costs):<BR>
<Img src='$Help_Image_dir/consumables.png'>
<P>
<H2>Minor Changes</H2>
<UL><LI>Specify Dye Set as 'D' on Sample Sheets for chemistry Version 3.
<LI>You may now create more than one NEW plate for a library at one time...
</UL>
\n<HR>\n";

    print $output;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_06_04_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## June 4th revisions ########################
    my $Table = HTML_Table->new();
    $Table->Set_Line_Colour('white');

    $Table->Set_Row(
        [   "<H2>Re-Array Status:</H2>The ReArray Status page has been modified slightly.  A few of the changes include<UL><LI>Lighter background for printouts<LI>Re-arrange info ordered for easier use<LI>Group Previously Assigned requests together by Source Plate (showing number of wells re-arrayed for each)</UL>"
        ]
    );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/rearray_image.png'>"] );

    $Table->Set_Row( ["<H2>More Flexible Criteria for 'Last 24 Hours' Page:</H2>The revising search criteria now allows easier selection of:<UL><LI>Any Date (checkbox)<LI>Specifying a Plate Number for a Library<LI>Specifying individual Run IDs.</UL>"] );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/revise_search.png'>"] );

    $Table->Set_Row(
        [   "<H2>Run Page:</H2><UL><LI>Add link from Prep Summary to Sequencing Run Details<LI>Include visual display of quality across sequence on individual Run Page<LI>Allow direct link to trace view from wells on individual Run Page (ie. click on Well for trace view)</UL>"
        ]
    );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/well_line.png'>"] );

    $Table->Set_Row(
        [   "<H2>MUL Barcodes:</H2>Barcodes now exist for the 384 well plates.  (The barcode actually is only code which gets converted to a list of the plates originally used to form the 384 well plate).  This barcode can be scanned however to generate a sample sheet.<BR>The barcode is generated automatically during the 384 well protocol.<BR>eg. 'Mul00001' is equivalent to 'Pla8228Pla8229Pla8230Pla8231'"
        ]
    );

    $Table->Set_Row(
        [   "<H2>Minor Changes:</H2><UL><LI>Chemistry Version is now an option for Sample Sheets.  This replaces the mobility version which is now determined by the Chemistry Version.<LI>You can check comments for a Run by clicking on the Run_ID hyperlink (from the Last 24 Hours page)"
        ]
    );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/chem_version.png'>"] );

    $Table->Printout();
    print hr;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_05_21_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## May 21st revisions ########################
    my $Table = HTML_Table->new();
    $Table->Set_Line_Colour('white');

    $Table->Set_Row(
        [   "<H2>Check for Repeating Run</H2>During the Phred Analysis, sequence strings are now checked for repeating sequences of up to 4 characters in length.  (If found, a note is made indicating the repeating sequence).  This was done after noticing that phred was found to produce a repeating 'tc' string throughout the quality portion of the sequence where a poly T was expected."
        ]
    );

    $Table->Set_Row( ["<H2>A Few More Graphs</H2>A few more histograms have been included on the main summary page.<BR>Click on 'Sequencer Status' or 'Project Status' at the bottom."] );
    $Table->Set_Row( ["<H2>For Equipment:</H2>(Histogram colours correspond to Run Map colours, though they currently use Quality_Length which is subtly different from Phred20)"] );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/equip_stats.png'>"] );

    $Table->Set_Row( ["<H2>For Projects:</H2>(Numbers included are for Average 'Quality_Length', Average Run Length, and Total Number of Reads)<BR><Img src='$Help_Image_dir/proj_stats.png'>"] );
    $Table->Set_Row(
        [   "<H2>Minor Changes:</H2><UL><LI>Reduced size of bin histograms<LI>Print Equipment Name, Model on Equipment barcodes<LI>Allow users to delete 384-well format Sample Sheets<LI>Wait for 384 files before analyzing 384-well format Sequencing Runs<LI>Include hyperlinks on scanners for general info on plates, equipment, solutions etc.<LI>The back button is now functional on the scanners (as is the refresh button)<LI>The Generate Sample Sheet page has been compressed (hopefully to allow processing without scrolling down (unless defaults need to be changed)</UL>"
        ]
    );

    $Table->Set_Row( ["<H2>Minor Fixes:</H2><UL><LI>A glitch in recording some maintenance procedures has been eliminated.<LI>Solution Types (Primer/Buffer/Matrix) are carried over from dilution mixtures</UL>"] );
    $Table->Printout();
    print hr;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_05_07_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## May 7th revisions ########################
    my $Table = HTML_Table->new();
    $Table->Set_Line_Colour('white');

    $Table->Set_Row(
        [   "<H2><U>Elimination of multiple Plate/Equipment fields</U></H2>In an effort to reduce the size of the screen needed for scanner use, lab tracking in which single plates are matched up with specific equipment has been adjusted to allow the use of only 1 or 2 textfields.  This vastly reduces the screen (particularly in cases when 12 or more plates are being used at one time - previously creating 12 pairs of 'Plate'/'Equipment' text fields.<BR>You may now omit the scanning of plates altogether.  If the number of plates is a multiple of the number of pieces of equipment scanned, it will be assumed that they are distributed evenly and IN ORDER.  Thus if you have 20 plates and are transferring them on 4 Hydras, you only have to scan the 4 Hydras in the Equipment field.  It will then be assumed that the first 5 plates are applied to the first Hydra scanned, the next 5 plates applied to the second Hydra scanned etc.<BR>The only time this requires a lot of scanning is if you are using a number of plates that is not a multiple of the pieces of equipment (ie 7 plates on 2 Hydras) (you should then scan 7 barcodes into the single 'Equipment' field) - or if you wish to alter the order of the plates applied (in which case you can simply scan all of the plates in a new order into the 'Plates' field)."
        ]
    );

    #    $Table->Set_Row(["<Img src='$Help_Image_dir/standard_solutions.png'>"]);
    $Table->Set_sub_header("<HR><H2><U>Minor Changes:</U></H2><UL><LI>The order of the histogram has been reversed to show higher quality scores to the right.<LI>A Cumulative Histogram now appears beside the histogram for Phred20 values.</Ul>");
    $Table->Set_Row( ["<Img src='$Help_Image_dir/new_hists.png'>"] );
    $Table->Set_Row( [ &vspace(5) ] );
    $Table->Set_sub_header(
        "<UL><LI>Solution I and Solution II volumes are calculated per plate (rather than per '2 plates' as originally specified).<LI>Preparation procedures are monitored by 'actions' as well as by 'plate'.  (ie. to see if a Big Dye sequencing reaction has been done, a plate is checked for 'Thermal Cycle'ing.  Previously, it was tracked by looking for the existence of 'MicroAmp' plates).</Ul>"
    );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/tracked.png'>"] );
    $Table->Set_Row( [ &vspace(5) ] );
    $Table->Set_sub_header(
        "<UL><LI>Multiple Equipment may be scanned together allowing users to perform multiple Maintenance Procedures at once (or look at maintenance history for a specified list of machines at one time).<LI>You can record instances of communication between the GSC and outside contacts.  (via 'Contacts' page)</Ul>"
    );

    $Table->Printout();
    print hr;
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_04_23_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## April 23rd revisions ########################
    my $Table = HTML_Table->new();
    $Table->Set_Line_Colour('white');

    $Table->Set_Row( ["<H2><U>More Standard Solutions</U></H2>More standard solutions have been added to the Reagent home page, including ET and Big Dye Brew Mixes.  These also appear on the home page of the scanners."] );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/standard_solutions.png'>"] );

    $Table->Set_Row(
        [   "<H2><U>Easier Stock Handling</U></H2>The latest version of scanner makes it easier to enter new stock reagents into the database, by allowing the user to begin by simply scanning a previously barcoded bottle, or simply scanning the catalog number of a new one.  The screen will then automatically retrieve the data for this item (if available), and pre-fill in all of the fields for a new record.  Only the new lot number needs to be filled in (and possibly the number in the batch), for a new item to be added to the database and barcoded.  Alternatively, after scanning a reagent, buttons are provided to empty the bottle, or to check stock supplies of similar reagents."
        ]
    );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/main_solution.png'>"] );

    $Table->Set_Row(
        [   "<H2><U>Scanning Shortcuts</U></H2>To speed and ease the use of the scanners a number of shortcuts have been set up to avoid having to move from page to page to perform some standard actions.  Some of these shortcuts include:<UL><LI>Scanning Equipment at the same time as a number of plates, automatically takes you to the Sample Sheet page, and pre-sets the Matrix and Buffer (retrieves this info from the database).  The primer is also extracted from the database if possible (this will only be found if the primer has been associated with the plates through plate tracking procedures.  If no primer can be found it will prompt for it - alternatively you may scan the primer when you scan the equipment and plates to pre-set the primer as well)<LI>Scanning a single solution or reagent will provide options for checking Stock, Emptying bottles, or adding a similar reagent to the database.<LI>By scanning more than one reagent, a page will automatically be set up to mix the reagents together to form a new solution.</UL>"
        ]
    );
    $Table->Set_Row(
        [   "As such <B>please use the following procedures with the scanner</B>:<UL><LI><B>Mixing Reagents</B>: Except when mixing standard solutions, simply scan all of the solutions into the text field on the home page, and press 'Scan'.  This should set up a page showing the solutions used, and prompting the user for amounts.<LI><B>Sample Sheets</B>: scan the equipment, all plates, and the primer at the same time into the text field, and press SCAN.  This should set the samplesheet parameters, and display a reduced sample sheet page.<LI><B>Adding new Reagents</B>: Scan the catalog number into the text field, or the solution number of an old (already scanned) bottle.  This should retrieve a similar item from the database, which can be added after the new lot  and number of bottles is updated.  (Scanning just the catalog number will obviously only work IF this catalog number is already in the database for an existing reagent.)<BR><Span class=small>(Commas separating barcodes is allowed for clarity, but is not required)</Span>"
        ]
    );

    $Table->Set_Row(
        [   "<H2><U>Clearer History Pages</U></H2>Much of the information (such as Prep History and Maintenance History) has been made available by simply dumping database data to the screen.  As a consequence it is (by default) not formatted, and may not be as clear as it could be.  If you use any of these pages frequently, please feel free to suggest ways in which you would like them formatted to make it easier to view.  I have made such adjustments to the Prep History page, and the Maintenance History Pages so far, and can adjust the look of other pages to make them as easy to use as possible.  Please let me know of other pages where this would be helpful."
        ]
    );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/prep_history.png'>"] );

    $Table->Set_sub_header(
        "<HR><H2><U>Minor Changes:</U></H2><UL><LI>Recently made Solutions (if not used) can now be deleted by the person who made them.  Go to 'Check My Recent Solutions' near the bottom.  It (as for plates) allows users to select any number of solutions that they have made within the last 7 days for deletion .<LI>Name Searching and auto-setting of Type (Matrix/Buffer) is set up on the 'Mix Reagents' page.<LI>A visible histogram now appears along with the Phred20 summaries (for both Libraries and Runs)<LI>No Grows are now being excluded from this information.  (Note that previously, unless otherwise specified, No Grow values would be included in averages).</Ul>"
    );

    $Table->Set_sub_header(
        "<HR><H2><U>Minor Fixes:</U></H2><UL><LI>Some Phred 20 Numbers may have been off for a few wells on the Run_Test_Status page.  This has been corrected.<LI>Some of the general info was not always appearing (such as Library Info).  This has been improved.</Ul><HR>"
    );
    $Table->Printout();
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_04_02_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## April 2nd revisions ########################
    my $Table = HTML_Table->new();
    $Table->Set_Line_Colour( 'white', 'white' );

    $Table->Set_Row(
        [   "<H2><U>Four sample sheets at once</U></H2>The Sample Sheet generator now allows you to generate four sample sheets at one time (on a single machine).  Simply scan the machine at the home page, and scan all 4 plates before hitting the 'Prepare Sample Sheets' button.  This will preset the plates for you.  In the future, once the preparation procedures are being diligently tracked, you will not have to enter the Buffer/Matrix, or Primer, since this information should already exist somewhere.  Until this info is consistently being tracked, however, you will still have to scan these in.  To create a sample sheet for a 384-well run, simply select that option below the 'Generate Sample Sheet' button, and a single 384-well format sample sheet will be produced rather than four 96-well format sample sheets."
        ]
    );

    $Table->Set_Row( ["<H2><U>Search Criteria on 'Last 24 Hours' Page</U></H2>This allows the user to specify Library or Sequencer as well as a Date Range for looking at a number of Sequence Runs at one time."] );
    $Table->Set_Row( ["<Img Src = '$Help_Image_dir/criteria.png'>"] );

    $Table->Set_Row(
        [   "<H2><U>Hyperlinked Table info pages</U></H2>Many of the pages now have hyperlinks to general info associated with Runs, Plates, Reagents, Employees, Equipment etc.  Each Info page has in turn a hyperlink to all other referenced tables.  From these pages, options are also available to update, edit or search the applicable table in the database.  The screen below may appear upon clicking on '2925' (the Run ID) listed on the 'Last 24 Hours' page."
        ]
    );
    $Table->Set_Row( ["<Img Src = '$Help_Image_dir/general_info.png'>"] );

    $Table->Set_Row(
        [   "<H2><U>Throw Away Plates</U></H2>Plates that are no longer being used should now be thrown away.  To do this scan any number of plates into the scan field on the home page and press 'SCAN'.  There is now a button at the bottom of the page to Throw these plates away.  (Their location will be changed to 'Garbage', and will be visible on information pages (including the Ancestry pages).  "
        ]
    );
    $Table->Set_Row( ["<Img Src = '$Help_Image_dir/plate_home.png'>"] );

    $Table->Set_sub_header(
        "<HR><H2><U>Minor Changes:</U></H2><UL><LI>The option buttons for Plates/Solutions appear slightly different as the buttons were updated and redundant ones removed.  Please take a second to look them over if you can't find what you are looking for at first.  <LI>Easier input procedure for setting up sample sheets<LI>Vector Information is now available on the 'Library' Page.<LI>You can now fill Re-Array Plates by Column or by Row<LI>Set Button Colours<UL><LI>Red indicates that pressing a button will affect the Database<LI>Yellow indicates buttons generally used to search or display information<LI>Lightblue is used for general lab function buttons<LI>Violet will be used for buttons that take you back or start over</UL><LI>Auto-searching for Plates (from Pop-down menu) takes too long, and has been disabled (currently 6000 plates)<LI>Unused wells now appear as black SQUARES on Run Map (to differentiate between failed) - See below</Ul>"
    );

    $Table->Set_Row( ["<Img Src = '$Help_Image_dir/unused.png'>"] );

    $Table->Set_sub_header(
        "<HR><H2><U>Minor Fixes:</U></H2><UL><LI>'Dispense' Solution is now functional<LI>Re-Printing Multiple Barcodes should now work<LI>Some problems with using scanner for making Sample sheets have been resolved (related to leading zeros in barcode)</Ul><HR>"
    );
    $Table->Printout();
    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_03_19_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## March 19th revisions ########################
    my $Table = HTML_Table->new();
    $Table->Set_Line_Colour( 'white', 'white' );

    $Table->Set_Row(
        [   "<h2>Removed Left Navigation Bar:</H2>The most visible change may be that I have changed the default to hide the left navigation bar.  This allows a lot more room on the page for all other operations.  Most of the links should be available through the Icons, or through current links on your computer.  (If you are still a bit unsure about the icons, please take a look at the <A Href = '$homelink&Help=1&Icons=1'>'Icons'</A> information at the <A Href = '$homelink&Help=1'>Help Page</A>.  If you are not happy with this change, you can bring the left frame back up by deselecting the 'Nav Bar' checkbox when you log in.  I have only reset the default for now."
        ]
    );

    $Table->Set_sub_header(
        "<h2>Added Menu Searching:</H2>In some fields you can type in a string to search a popdown menu.  A list of elements in the menu that match your entry will appear.  (if only one match is found it will automatically select it, (clearing the textfield in case you wish to search again).  If you wish to force a new entry (eg. you wish to name something 'Agarose' even though 'Gold Agarose' is one of the choices), simply select 'New' instead of 'Search' to the right of the textfield (only available in some cases).  In some cases the pulldown menu will be reduced to only those options that match your search.  This makes it much easier to select from a very long list.  When a Plate Number as well as a Library choice is available, the possible Plate Numbers is also automatically updated when you change the Library field."
    );
    $Table->Set_sub_header("<Img src='$Help_Image_dir/ForceSearch.png'>");

    $Table->Set_sub_header(
        "<h2>Improved ease of ReArraying Plates:</H2>Re-Arraying Plate options are available from the main Plate Home Page.  To ReArray a new plate (requested by Yaron), select Re-Array 'Requested' - or Re-Array 'Assigned' to repeat a previously Re-Arrayed assignment.  In either case, you will be shown a list of Re-Array Requests.  When a specific Request is chosen, the Source Plate will automatically appear in a textfield, allowing you to change it if required.  When the 'Create Plate' button is pressed, a new plate will be created, barcoded, and all unused wells recorded automatically.  If you are repeating a Re-Array assignment, it will be recorded as a new 'Request_Number' with the status 'Re-Assigned'.  This may sound a bit confusing, but with a bit of practice, hopefully it will make much more sense - all of the possibilities involved make it a bit tricky to simplify this process much more."
    );

    $Table->Set_sub_header(
        "<h2>384-well Sequencing</H2>You should now be able to easily perform 384-well sequencing with a minimum of changes.  In the background, 4 separate Sequence Runs will be recorded (taking place simultaneously) - one for each 96-well plate.  Only one sample sheet, however will be made.  The quadrant label for these runs will be set to 'x' to indicate that it is a 384-well sample sheet.  A copy of the same sample sheet will be saved for each 96-well plate (although only one is actually used)"
    );

    $Table->Set_sub_header(
        "<HR><H2>Minor Changes:</H2><UL><LI>adjusted default Run Module for 3700-2<LI><UL>Summary Pages:<LI>Added No Grow, Slow Grow Summary to Library 'Prep Summary'.<LI>added clickable display of Latest No Grows, Slow Grows<LI>added Phred 20 count summary for library<LI>allow Phred threshold adjustment at Colour Run Map<LI>Provide Link to Martins scorecard and histogram page from Run Info page<LI>Provide link to trace data from Run Info Page...</Ul>"
    );
    $Table->Set_sub_header("<HR><H2>Minor Fixes:</H2><UL><LI>Minor Bug fix to Ancestry Page</Ul><HR>");
    $Table->Set_sub_header(
        "<h2>Changes to Run Info Page</H2><UL><LI>added Phred 20 count summary<LI>allow Phred threshold adjustment at Colour Run Map<LI>Provide Link to Martins scorecard and histogram page from Run Info page<LI>Provide link to trace data from Run Info Page...<BR><Img src='$Help_Image_dir/RunInfo.png'>"
    );

    $Table->Set_sub_header(
        "<hr><h2>Changes to Prep Summary Page</H2><UL><LI>Added No Grow, Slow Grow Summary to Library 'Prep Summary'.<LI>added clickable display of Latest No Grows, Slow Grows<LI>added Phred 20 count summary for library<Img src='$Help_Image_dir/PrepSummary.png'>"
    );
    $Table->Printout();

    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_03_05_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

############## March 5th revisions ########################
    my $Table = HTML_Table->new();
    $Table->Set_Line_Colour( 'white', 'white' );

    $Table->Set_Row(
        [   "<h2>ReArraying Plates:</H2>The code has been set up to automatically set all non-ReArrayed Wells to Unused by default when a plate is rearrayed either manually or by 'Request'.  (A checkbox appears that can optionally de-select this option).  Users can also specify a plate, and view the ReArray requirements for that plate only - showing Target and Source Plate IDs, Wells, and the Primer Name.  (See ReArray Help for a bit more info).",
            "<Img src='$Help_Image_dir/ReArray_Printout.png'>"
        ]
    );

    $Table->Set_sub_header(
        "<HR><H2>Minor Changes:</H2><UL><LI>Allow entry of range (D5-H22) when selecting wells.<LI>Added configuration details for D3700-5.<LI>Allow Date Specification for Quick Run Views (from 'Last 24 Hours').<LI>Add some help info regarding Protocol Maintenance and Plate Tracking.</Ul>"
    );
    $Table->Set_sub_header(
        "<HR><H2>Minor Fixes:</H2><UL><LI>'Make Solution I' button set up with Solution I defaults.<LI>'Completed' Steps recorded during Preparation Tracking.<LI>Adjusted calculations in Chemistry Calculator.<LI>Slight improvement to interface for adding equipment.</Ul><HR>"
    );
    $Table->Printout();

    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

###################################
sub Revision_2001_02_12_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

    print
        "As I will be away until the 27th, I am releasing a new version of the barcode page this week (otherwise it would have been a month before these changes were implemented).  There are only a couple of changes, but they may prove useful and/or timesaving.  Also check out the previous revisions if you have not already done so.<p ></p>",

        "As per usual, please let me know before I leave if there is anything that is not running smoothly.  Thanks.",

        "<p ></p>";

    my $Table = HTML_Table->new();
    $Table->Set_Line_Colour( 'white', 'white' );

    $Table->Set_Row(
        [   "<h2>New Colour Map Icons:</H2>To allow Duane to look at the success of recent runs more easily, I have adjusted the 'Last 24 Hours' and 'Get Run Info' (from Prep Summary Page) links to work <B>faster</B>, and to show small images of the colour maps that display Phred 20 distribution over the plates.  It also groups together (by colour) Runs from the same 384-well Plate"
        ]
    );

    $Table->Set_Row( ["<Img src='$Help_Image_dir/New_Summary.png'><HR>"] );

    $Table->Set_Row(
        [   "<h2>Creating Standard Solutions:</H2>To facilitate standard Mixing of Solution I and Solution II, a quick link is provided from the Reagents/Solutions page, calculating amounts required based on the number of 96-well blocks, and requiring users to only scan/enter the appropriate solution barcodes used.."
        ]
    );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/Std_Solutions.png'><HR>"] );

    $Table->Set_Row(
        [   "<h2>Setting up ReArray Requests:</H2>When a ReArray Request is available a message should appear on the front of the login page.  If the Oligo is available, you should generate a new plate to 'ReArray' onto.  At this time, go to the main Plate page and View ReArray Requests for 'Requested'.  Simply check off every source plate that you wish to ReArray and enter the new plate number.  This will then record all of the rearray allocations to the database and update the ReArray Request Status to 'Assigned'."
        ]
    );
    $Table->Set_Row( ["<Img src='$Help_Image_dir/Auto_Assign.png'><HR>"] );

    $Table->Set_Row(
        [   "<h2>Minor Fixes:</H2><UL><LI>Automatically resets appropriate quadrant wells to used/unused if avail quadrants is reset (for 384 well plates)<LI>Reset Path of D3700-4 to F drive<LI>Ensure Foil Piercing is set Off/On regardless of setting in template file.<LI>Enable editing of Plate or Solution info directly by clicking on Name (after scanning)<LI>Corrected minor problems with Ed's Protocol Administration page<LI>An error message is generated if Primer/Matrix/Buffers are not chosen for a Sequence Run.  (to enforce choosing them)</UL><HR>"
        ]
    );

    $Table->Printout();

    &Revision_Help_Old( 'list', -dbc => $dbc );

    return 1;

}

############## February 5th revisions ########################

###################################
sub Revision_2001_02_05_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

    print "In the most recent version, there are a number of new changes.  Help Links with new information are indicated with an asterisk.<p ></p>",

        "If anything does not work as expected or unwanted messages show up, don't hesitate to tell me.  If it slows down your work at all let me know right away; otherwise, send me an e-mail, add something to the suggestion box, or drop by at your convenience.  Also, let me know if there is something you would like to see more 'Help' on.  Thanks.",

        "<p ></p>";

    my $Table = HTML_Table->new();
    $Table->Set_Line_Colour( 'white', 'white' );

    $Table->Set_sub_title(
        "<A Href = '$homelink&Help=1&ReArray=1'><h2>ReArraying and Importing Plates:</H2></A>This allows users to:<BR><UL><LI>manually specify clones to ReArray from one plate to another<LI>View/Print ReArray Requests (generated by Yaron)<LI>View/Print ReArrays which have been manually assigned<LI>Import Plates from an external source (eg the IRAL 9 plate)<BR><A Href = '$homelink&Help=1&ReArray=1'>(click here for more info)<BR><HR>",
        2
    );

    $Table->Set_Row(
        [   "<A Href = '$homelink&Help=1&Stock=1'><h2>Monitoring Reagent/Chemical Supplies:</H2></A>We are now able to keep track of Supplies of Various Reagents/Chemicals, based upon their Catalog Number, and a specified number of Unopened Bottles that should be in Stock.  This can be used to notify administrators when stock supplies run low.<BR><A Href = '$homelink&Help=1&Stock=1'>(click here for more info)<BR>",
            "<Img src='$Help_Image_dir/Notice.png'><HR>",
        ]
    );

    $Table->Set_Row(
        [   "<H2>Message Board:</H2>This will display messages on the login page.  This can be used to display status information or to indicate when Re-Pooling is ready to proceed.<BR>This is meant as a way to send request or notices to the lab from the BioInformatics side",
            "<Img src='$Help_Image_dir/Message.png'><HR>",
        ]
    );

    $Table->Set_Row(
        [   "<H2>Plate View:</H2>A Plate View now appears above other run data.  This is accessed from either the 'Last 24 Hours' Page (by clicking on a run), or from the 'Get Run Info' Page accessible through the Prep Summary Page.  (In the future, I would like to provide a small icon of this image map on these pages so that numerous Plate views (dozens) can be visualized at one time on a singe page.)",
            "<Img src='$Help_Image_dir/Mapview.png'><HR>",
        ]
    );

    $Table->Set_sub_header(
        "<H2>Minor Changes:</H2>Some additional minor changes include:<UL><LI>Activating the 'Dispense' into ... Button (after mixing solutions)<LI>adjusting the interface for adding solutions slightly as per suggestions by Letticia/Steve<LI>allow viewing/appending of Funding information - available through the Contacts Page<LI>allow multiple machines to be entered into a single field during Protocol Procedures<LI>slight adjustments made to Ed's Protocol page to facilitate Protocol editing<LI>Back and Forward buttons at the top of the page<LI>Help Page for ReArraying Plates<LI>You can now turn OFF the Left Navigation Bar from the Login Page<LI>The Suggestions are now being stored in more detail, and are listed in reverse chronological order<LI>A colour plateview map of runs is shown above the Run Data (accessible from 'Last 24 Hours' page or the 'Get Run Info' page generated from the Prep Summary)<LI>There is a direct link to Yarons Transposon Library Status Page from the Main Summary Page<LI>Links to Edit pages now appear after scanning Plates or Reagents"
    );

    $Table->Set_sub_header(
        "<H2>Fixes:</H2>There are also a few fixes that were suggested that have been implemented:<UL><LI>a small bug has been removed from the Search/Edit Plate page<LI>printing solution barcodes after scanning them should now work<LI>Popup menus now show up for Format, Size when editing plates"
    );
    $Table->Printout();

    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;

}

################## January 22nd revisions ############################
###################################
sub Revision_2001_01_22_Help {
###################################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

    print "In the most recent version, there are a number of new changes.<p ></p>",

        "If anything does not work as expected or unwanted messages show up, don't hesitate to tell me.  If it slows down your work at all let me know right away; otherwise, send me an e-mail, add something to the suggestion box, or drop by at your convenience.  Also, let me know if there is something you would like to see more 'Help' on.  Thanks.",

        "<p ></p>", h3("Login Page:"),

        "This allows users to login as before but allows options for:", ul("limiting the libraries/plates that show up in popup windows to a single Project"), ul("Specifying the database on which to work"), ul("Turn the top and bottom bars on or off"),

        "<p ></p>", h3("Icons at the top of the Page:"), "These Icons are meant to provide an easier way to quickly go to various pages.  A couple are new pages, such as the: ", ul("'Bugs/Suggestions'"), ul("'Last 24 hours' page"), ul("'Help'"),
        ul("'Latest Revisions'"), "I hope these are of some help.<BR>",

        "<A Href = '$homelink&Help=1&Icons=1'>(More details on Icons)</A><BR>";

    print h3("Fixes:"), "There are also a few fixes that were suggested that have been implemented:<p ></p>", ul("row/column references appear on the right and bottom of plates as well as the top and left"),
        ul("Default values for the 3700s have been modified slightly (1.5uL DNA)"), ul("Popup menus now show up for Format, Size when editing plates"), "<HR>";

    &Revision_Help_Old( 'list', -dbc => $dbc );
    return 1;
}

#########################
sub Revision_Help {
#########################

    #
    # To add a revision:
    #
    #  1. Create a News Item object in http://gin.bcgsc.bc.ca
    #  2. In the 'metadata', highlight the Subject "Sequencing" and also add the keyword "Revision"
    #  3. Edit your text.
    #  4. Publish your News Item
    #
    my %args      = filter_input( \@_, -args => 'dbc' );
    my $dbc       = $args{-dbc};
    my $server    = Frontier::Client->new( url => "http://gin.bcgsc.bc.ca/services/" );
    my $news_aref = $server->call( "getNews", "Sequencing" );
    my $flag      = 0;
    foreach my $item ( @{$news_aref} ) {
        foreach ( @{ $$item{'categories'} } ) {
            if ( $_ eq 'Revision' ) { $flag = 1 }
        }
        if ($flag) {
            print Views::Heading( $$item{'title'} );
            print "<p ></p>Posted by <a href='http://gin.bcgsc.bc.ca/Members/" . $$item{'creator'} . "/'>" . $$item{'creator'} . "</a>";
            print " on " . $$item{'date'} . "</p>\n";
            print "<blockquote><p ></p>" . $$item{'description'} . "</p></blockquote>\n";
            print "<p ></p>" . $$item{'body'} . "</p>\n";
            $flag = 0;
        }
    }
    print "&nbsp;<br>\n";
    print "&nbsp;<br>\n";

    ## TO DO:
    ## Display older revisions in the new format
    ## This could be a GIN link: http://gin/search?Subject:list=Sequencing&Subject:list=Revision etc. etc.

    Revision_Help_Old( 'latest', -dbc => $dbc );
    return 1;
}

#########################
sub Revision_Help_Old {
#########################
    #
    # older revisions method:
    #
##
    # To add revisions:
    #    add to front of @revisions array
    #    add 'elsif' loop at end of this subroutine
    #    add 'Revision_...' subroutine as req'd.
    #

    my %args     = filter_input( \@_, -args => 'revision' );
    my $revision = $args{-revision};
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

    my @revisions = (
        '2002_02_18', '2001_10_16', '2001_09_24', '2001_09_10', '2001_08_13', '2001_07_30', '2001_07_16', '2001_07_03', '2001_06_18', '2001_06_04',
        '2001_05_21', '2001_05_07', '2001_04_23', '2001_04_02', '2001_03_19', '2001_03_05', '2001_02_12', '2001_02_05', '2001_01_22', '2001_01_01'
    );

    if ( $revision =~ /latest/i ) {
        $revision = $revisions[0];
    }
    elsif ( $revision =~ /list/i ) {
        print &Views::Heading("History of Revisions");
        foreach my $this_revision (@revisions) {
            print "<br><A Href = '$homelink&Help=1&Revision=$this_revision'><span class = small><B>$this_revision</B></Span></A><BR>";
        }
        return 1;
    }

    print &Views::Heading("Revisions made $revision");

    if ( $revision =~ /2001_01_01/ ) { &Revision_2001_01_01_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2002_02_18/ ) { &Revision_2002_02_18_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_10_16/ ) { &Revision_2001_10_16_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_09_24/ ) { &Revision_2001_09_24_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_09_10/ ) { &Revision_2001_09_10_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_08_13/ ) { &Revision_2001_08_13_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_07_30/ ) { &Revision_2001_07_30_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_07_16/ ) { &Revision_2001_07_16_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_07_03/ ) { &Revision_2001_07_03_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_06_18/ ) { &Revision_2001_06_18_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_06_04/ ) { &Revision_2001_06_04_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_05_21/ ) { &Revision_2001_05_21_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_05_07/ ) { &Revision_2001_05_07_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_04_23/ ) { &Revision_2001_04_23_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_04_02/ ) { &Revision_2001_04_02_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_03_19/ ) { &Revision_2001_03_19_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_03_05/ ) { &Revision_2001_03_05_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_02_12/ ) { &Revision_2001_02_12_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_02_05/ ) { &Revision_2001_02_05_Help( -dbc => $dbc ); }
    elsif ( $revision =~ /2001_01_22/ ) { &Revision_2001_01_22_Help( -dbc => $dbc ); }
    else                                { print "This revision ($revision) not found"; }

    return;
}

##########################################################
###### DELETE BELOW - move to help directory (text files)  ... do up to ## DONE ##
##########################################################

#
# DONE
########################
sub Summary_Help {
########################'
    print p;
    my $Summary = HTML_Table->new();
    $Summary->Set_Line_Colour( 'white', 'white' );
    $Summary->Set_Title(
        "<H2>Summary Page Options:</H2>A few options exist on the main Summary Page to monitor the Sequencing Status.  These are complemented in more detail by the full Sequencing Summary Pages developed by Martin, Yaron, and Scott.  On the barcode page itself you have the option to look at...<p ></p>",
        class => 'vlightbluebw'
    );

    $Summary->Set_Column(
        [   "<h2>Reads Summary</h2> - From the Summary page, you may get a summary of Reads (showing the total number of reads, No Grows, Slow Grows, and Warnings), for Libraries or for Machines.  This can be used to view all data, data over the last two weeks (separately), or the last two days.",
            "<Img src='$Help_Image_dir/R_Status.png'><HR>",
            "<h2>Prep Summary</h2> - You may also generate a list of plates created in the last couple of weeks as well as a detailed list of the types (and number) of plates created for each Plate Number from a given library.  It also shows the number of Sequencing runs completed with each expected primer, highlighting runs that have yet to be analyzed.  This is useful in quickly determining which plates still need to be Sequenced or prepared for sequencing",
            "<Img src='$Help_Image_dir/Prep.png'><HR>",
            "<H2>Project Update</H2> - This provides a quick summary of the number of runs and reads generated for each project.",
            "<Img src='$Help_Image_dir/Project.png'><HR>",
            "<H2>Sequencer Status</H2> - This provides a quick rundown of the total number of reads generated by each sequencer.",
            "<Img src='$Help_Image_dir/M_Status.png'><HR>",
            "<H2>Regenerate Menus</H2> - This option allows you to re-generate the Library pull-down menu to make it easier to select a choice.  If you choose a specific project and press the regenerate menus button, the only libraries that will appear in the pull-down menu will be ones associated with that Project (or Project Type if it is specified)<p ></p>Some <B>TERMS</B> that may be used include:<p ></p><UL><LI><B>Quality Length</B> - This is the length of the region determined by Phred to be of good quality.  It generally will correspond with phred 20 values, but it determines a region which may include some values below phred 20, and exclude other short sections with phred values of greater than 20<LI><B>Quality Vector</b> - This refers to the number of base pairs identified as Vector within the 'Quality' region determined by Phred (see above)<LI><B>Phred 20</B> - The number of base pairs with a phred 20 score or higher"
        ]
    );

    $Summary->Printout();

    return 1;
}

#
# DONE
########################
sub Icons_Help {
########################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

    print &Views::Heading("Icons");

    print "The Icons provide quick links to common pages such as:<p ></p>",

        "<Table cellpadding = 10><TR><TD width=50>", "<A Href=$homelink><Img src='$Help_Image_dir/Home.png' alt = 'Home' align = top border=0 height=32 width=32></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Home</B></TD><TD>This returns the user to the Home page",

        "</TD></TR><TR><TD>", "\n<A Href='$homelink&Bugs=1'><Img src='$Help_Image_dir/bugs.png' alt = 'Bugs/Suggestions' align = top border=0 height=32 width=32></A><img src='$Image_dir/Space.png' width=10 height=1>", "</TD><TD>",
        "<B>Bugs/Suggestions</b></TD><TD>This takes the user to a page where they can enter suggestions or bug comments.  Please Use!!!",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Change+User=1><Img src='$Help_Image_dir/enter2.png' alt = 'Re-Login' align=top border=0 height=32 width=32></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Re-Login</B></TD><TD>Returns user to login page where they can redefine the User/Database/Project or turn off/on the top & bottom banners (freeing up at the same time some space on the sides of the screen)",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Last+24+Hours=1><Img src='$Help_Image_dir/Hourglass.png' alt = 'Last 24 Hours' align = top border=0 height=32></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Last 24 Hours</B></TD><TD>This displays the current status (including Avg Read Length, Phred 20 values, Good Wells, # of Mirrored Files, Machine) for Sequences Requested (or Run) in the last 24 hours.",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Sample+Sheets=1><Img src='$Help_Image_dir/Ssheet.png' alt = 'Sample Sheets' align = top border=0 height=32 width=32></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Sample Sheets</B></TD><TD>This directs the user to the Sample Sheet main page where they can generate a sample sheet, or delete a recently made sample sheet",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Standard+Page=Solution><Img src='$Help_Image_dir/bottle.png' alt = 'Reagents/Chemicals/Solutions' align = top border=0 height=32 width=32></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Reagents/Chemicals/Solutions</B></TD><TD>This sends the user to the Reagent/Chemical/Solution home page where they can Create/List/Edit/Delete Reagents (including Primers or 'Vector/Primer' direction information)",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Standard+Page=Equipment><Img src='$Help_Image_dir/equipment.png' alt = 'Equipment' align = top border=0 height=32 width=32></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Equipment</B></TD><TD>This sends the user to the Equipment home page where they can List/Edit/Add Equipment or Maintenance procedures",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Standard+Page=Plate><Img src='$Help_Image_dir/plates.png' alt = 'Plates' align = top border=0 height=32 width=32></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Plates</B></TD><TD>This sends the user to the Plates home page where they can Create/Edit/Delete Plates (& New Libraries if needed).  Re-Arrayed Plates can also be set up or viewed from this page.",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Sequencing+Status=1><Img src='$Help_Image_dir/data.png' alt = 'Sequencing Summary' align = top border=0 height=32 width=32></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Summary</B></TD><TD>This sends user to the Summary Page which can list Read Summaries or Prep Status for Libraries or Projects",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Standard+Page=Library><Img src='$Help_Image_dir/Library.png' alt = 'Libraries' align = top border=0 height=36 width=36></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Libraries</B></TD><TD>This directs the user to the Library home page where they can Create/Edit/View Libraries",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Standard+Page=Contact><Img src='$Help_Image_dir/contacts.gif' alt = 'Contacts' align = top border=0 height=32 width=32></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Contacts</B></TD><TD>This sends the user to the Contacts home page where they can View/Edit/Add Contact or Organization information",

        "</TD></TR><TR><TD>", "\n<A href='http://rgweb.bcgsc.bc.ca/cgi-bin/Chemistry'><Img src='$Help_Image_dir/anim_arrow.gif' alt = 'Links' align = top border=0></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Links</B></TD><TD>This directs user to other pages such as Protocol administration, Martin's Sequencing Summary Page, Scott's SAGEdb page, or the Mirroring page.",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Help=1><Img src='$Help_Image_dir/Help-button.png' alt = 'Help' align = top border=0></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>Help</B></TD><TD>This allows users to access on-line help for the barcode page",

        "</TD></TR><TR><TD>", "\n<A Href=$homelink&Help=1&Revisions=1><Img src='$Help_Image_dir/new.png' alt = 'New Changes' align = top border=0 height=32 width=70></A><img src='$Image_dir/Space.png' width=10 height=1>",
        "</TD><TD><B>New Changes</B></TD><TD>This describes briefly the latest changes that have been made to the barcode pages as new versions are released.  An archive is also available at the bottom of the page linking to a history of changes made to each release.",
        "</TD></TR></Table>",

        "<HR>";

    return 1;
}

#######################
sub Online_help {
#######################
    #
    # This routine returns a message text generated depending upon the help topic requested.
    #
    #
    my $help_topic = shift;

    if    ( $help_topic =~ /ReArray Definitions/i )           { return OH_Rearray_definitions(); }
    elsif ( $help_topic =~ /Mixing Solutions/i )              { return OH_Mixing_solutions(); }
    elsif ( $help_topic =~ /New Reagents/i )                  { return OH_new_reagents(); }
    elsif ( $help_topic =~ /New Plates/i )                    { return OH_new_plates(); }
    elsif ( $help_topic =~ /New Libraries/i )                 { return OH_new_libraries(); }
    elsif ( $help_topic =~ /New Projects/i )                  { return OH_new_projects(); }
    elsif ( $help_topic =~ /Editing Entries/i )               { return OH_making_changes(); }
    elsif ( $help_topic =~ /Deleting Mistakes/i )             { return OH_deleting_mistakes(); }
    elsif ( $help_topic =~ /Adding Notes/i )                  { return OH_making_notes(); }
    elsif ( $help_topic =~ /ReArraying Plates/ )              { return OH_ReArray_Help(); }
    elsif ( $help_topic =~ /Monitoring Stock/ )               { return OH_Stock_Help(); }
    elsif ( $help_topic =~ /Barcode Scanner/ )                { return OH_Scanner_Help(); }
    elsif ( $help_topic =~ /ReBooting Protocol/ )             { return OH_ReBooting(); }
    elsif ( $help_topic =~ /Laboratory Protocols/ )           { return OH_Protocols(); }
    elsif ( $help_topic =~ /Primary Database Interactions/i ) { return OH_Main_Flow(); }
    elsif ( $help_topic =~ /Phred Analysis/i )                { return OH_Phred_Analysis(); }
    elsif ( $help_topic =~ /Solutions in the Database/i )     { return OH_Solution_Flow(); }
    elsif ( $help_topic =~ /Protocol Formats/i )              { return OH_Protocol_Formats(); }
    elsif ( $help_topic =~ /Debugging Errors/i )              { return OH_Debugging_Errors(); }
    elsif ( $help_topic =~ /DB Modules/i )                    { return OH_DB_Modules(); }
    elsif ( $help_topic =~ /Restoring Database/i )            { return OH_Restoring_Database(); }
    elsif ( $help_topic =~ /Slow Response Time/i )            { return OH_Slow_Response_Time(); }
    elsif ( $help_topic =~ /Chemistry Calculator/i )          { return OH_Chemistry_Calculator(); }
    elsif ( $help_topic =~ /Adding a New Sequencer/i )        { return OH_New_Sequencer(); }
    elsif ( $help_topic =~ /Sample Sheets/i )                 { return OH_Sample_Sheets(); }
    elsif ( $help_topic =~ /Directories/i )                   { return OH_Directories(); }
    elsif ( $help_topic =~ /Poor Quality Runs/i )             { return OH_Poor_Quality_Runs(); }
    elsif ( $help_topic =~ /Command Line Scripts/i )          { return OH_Command_Line_Scripts(); }
    else                                                      { return h2("Sorry... No help found for $help_topic"); }
}

############################
sub Online_help_search {
############################
    my %args = filter_input( \@_, -args => 'link' );
    my $link     = $args{ -link } || "";
    my $dbc      = $args{-dbc};
    my $homelink = $dbc->homelink();

    my $help_link = $homelink;
    if ( $homelink =~ /(.*)\/barcode/ ) { $help_link = "$1/help.pl"; }

    print alDente::Form::start_alDente_form( $dbc, 'HelpForm', $help_link ) .

        submit( -name => 'Search for Help', -style => "background-color:yellow" ) . &vspace(10) . "on: " . textfield( -name => 'Help', -size => 20 ) . "</Form>";

    #    print submit(-name=>'Search for Instructions',-style=>"background-color:yellow"),&vspace(10),
    #    " on: ", textfield(-name=>'Instruction String',-size=>20),br;
    return;
}

#####################################
sub Online_help_search_results {
#####################################
    #
    # This routine prints out the help topics that contain the string given,
    # (Providing a hyperlink to a page displaying each topic in full.
    #
    my %args = filter_input( \@_, -args => 'string,dbc' );

    my $string = $args{-string};
    my $dbc    = $args{-dbc};

    my @topics = (
        'ReArray Definitions',
        'Mixing Solutions',
        'New Reagents',
        'New Plates',
        'New Libraries',
        'New Projects',
        'Editing Entries',
        'Deleting Mistakes',
        'Adding Notes',
        'ReArraying Plates',
        'Monitoring Stock',
        'Barcode Scanner',
        'ReBooting Protocol',
        'Laboratory Protocols',
        'Primary Database Interactions',
        'Phred Analysis',
        'Solutions in the Database',
        'Protocol Formats',
        'Debugging Errors',
        'DB Modules',
        'Restoring Database',
        'Slow Response Time',
        'Chemistry Calculator',
        'Adding a New Sequencer',
        'Sample Sheets',
        'Directories',
        'Poor Quality Runs',
        'Command Line Scripts'
    );

    my $found = 0;
    print "<UL>";
    foreach my $topic (@topics) {
        if ( &Online_help($topic) =~ /$string/i ) {    ### search all help info for string
            $found++;
            my $padded_topic = $topic;
            $padded_topic =~ s /\s/+/g;                ###### pad topic with + for URL
            print "<LI>";
            print &Link_To( $dbc->config('homelink'), "<B>$topic</B>", "&Online+Help=$padded_topic", undef, ['newwin'] );

            #	    print h2("<A Href='$homelink&Online+Help=$padded_topic'>$topic</A>");
            #	    print hr;
        }
    }
    print "</UL>";
    if   ($found) { print "<HR>$found topics found containing '$string'"; }
    else          { print "No instructions found containing '$string'"; }
    ##### look for string in help topics ######
    return 1;
}

#
# DONE
#
####################
sub OH_Main_Flow {
####################
    #
    # Describe main laboratory procedures and their interaction with the database...
    #
    #

    my $output = h2("Database Interactions During Standard Laboratory Procedures");

    my $Flow = HTML_Table->new();
    $Flow->Set_Width('100%');

    #    $Flow->Set_Class('small');
    $Flow->Set_Headers( [ 'Step', 'Database Changes' ] );

    $Flow->Set_Row(
        [ '<B>make Project</B>', '<B>Project</B> (new)<UL><LI>Name<LI>Description<LI>Initiated <LI>Source<LI>Type <LI>Obtained Date<LI>Host Cells<LI>Vector<LI>Organism<LI>Sex<LI>Tissue<LI>Strain<LI>Notes<LI>5,3 Prime Cloning Sites<LI>Comments</ul>' ] );

    $Flow->Set_Row(
        [   '<B>make Library</B>',
            '<B>Library</B> (new)<UL><LI>Name (5 characters)<LI>Full Name<LI>Description<LI>Project<LI>Source<LI>Type <LI>Obtained Date<LI>Host Cells<LI>Vector<LI>Organism<LI>Sex<LI>Tissue<LI>Strain<LI>Notes<LI>5,3 Prime Cloning Sites<LI>Comments</ul>'
        ]
    );

    $Flow->Set_Row( [ '<B>make Plate</B>', "<B>Plate</B> (new)<UL><LI>Size<LI>Format<LI>Creation Date<LI>Employee<LI>Number<LI>Quadrant<LI>Parent Plate (if applic)<LI>Status = 'Active'<LI>Comments</ul>" ] );

    $Flow->Set_Row( [ '<B>record No/Slow Grows</B>', '<B>Plate</B> (update)<UL><LI>No_Grows<LI>Slow_Grows<LI>Unused_Wells</UL>' ] );

    $Flow->Set_Row(
        [   '<B>Full Mech Prep /<BR>Sequencing Reaction<BR>...<BR>(for each step)</B>',
            "<B>Preparation</B> (new)<UL><LI>Employee<Li>Time<Li>Equipment(if applic)<LI>Solution_ID(if applic)<LI>Conditions<LI>Comments</Ul><HR><B>Solution</B> (update)<UL><LI>Quantity_Used</UL>"
        ]
    );

    $Flow->Set_Row(
        [   '<B>Run</B>',
            "<B>Run</B> (new)<UL><LI>Plate<LI>Employee<LI>Equipment<LI>Time = (time of request)<Li>Chemistry<li>Matrix<Li>Buffer<Li>Primer<Li>Configuration Parameters eg:<UL><LI>Foil Piercing<Li>Run Voltage<LI>Injection Voltage<LI>...</UL><LI>Run State = 'In Process'<LI>Comments</UL>"
        ]
    );

    $Flow->Set_Row(
        [   '<B>Auto-analysis</B>',
            "<B>Clone Run</B> (~96 new)<UL><LI>Run ID<LI>Well<LI>Run<LI>Run Scores (packed)<Li>Run Length<LI>Quality Length<LI>Vector Portion<LI>Phred Histogram (packed)<LI>Quality Histogram (packed)<LI>Growth Status<Li>Notes</UL><B>Run</B> (update)<UL><LI>Run_Status = 'Analyzed'<LI>Time = (timestamp on datafiles)</UL>"
        ]
    );

    $Flow->Set_Row( [ '<B>Throw Away Plate</B>', '<B>Plate</B> (update)<UL><LI>Plate_Status<LI>Plate_Location</UL>' ] );

    $output .= $Flow->Printout(0);
    return $output;
}

#
# DONE
####################
sub OH_Phred_Analysis {
####################
    #
    # Describe standard phred analysis ..

    my $output = h2("Phred Analysis of Sequencing Runs");

    $output .= "When a sequence is requested, the 'Run_Status' is defined as 'In Process' meaning that the data is not yet available.<P>
The following steps take place in the creation of sequencing Data:<P>
<UL>
<LI>Generate Sample Sheet - (Run_Status = 'In Process')
<LI>data collection on Sequencer (stores files on local machine on completion)
<LI>Sequencers are mirrored regularly (on request as well as daily via a cron job)<BR>
(This entails copying all of the Data Trace files (and raw data) into the appropriate subdirectories in the /home/aldente/public/mirror/ directory)
<LI><B>update_sequence.pl -A all</B> is run as a cronjob<BR>(for info on this script type '/home/rguin/public/update_sequence.pl' from the command line.)<P>This program generates a list of all sequence runs which are still 'In Process'.<BR>For each of these runs, it then runs the script <B>'post_sequence.pl'</B> on each of them, passing this script values relating to the details of the run (machine, employee, plate, chemistry, primer ...etc.).<P>This script in turn performs the following operations for each sequence run:<OL>
    <LI>generates the appropriate directories in /home/aldente/public/Projects/\$proj/\$lib/AnalyzedData/
    <LI>creates symbolic links to all of the chromat directories in the mirror directory (placing them in chromat_dir/)
    <LI>runs 'phred' on the chromat_dir (This results in a number of statistical files which include phred scores for each nucleatide generated), placing the resultant files in the directory phd_dir.
    <LI>extracts information from these 'phred' files and places the appropriate information in the Clone_Sequence table (as well as some subsidiary information such as the well growth status ('OK','No Grow' or 'Slow Grow'), warnings (poor quality, lack of data, vector only, recurring string etc.)
	<LI>Generates a colour map gif file of the 96-well plate (done separately for each of the sub-plates of a 384-well plate) - and placing a copy in the directory /www/htdocs/intranet/SDB/RunMaps/. 
    <LI>Re-sets the 'Run_Status' of the Run to 'Analyzed'
</OL>
</UL>";

    $output .= &Views::Heading('Special Cases');

    $output .= "<B>Mis-named Files:</B><P>
If files have the incorrect name, the names of the files should 
be changed in the mirror directory.  The names should follow the 
standard naming convention (check other valid filenames if you are unsure).<P>
										<B>Reverse-Oriented Files:</B><P>
If files are reverse oriented, the script update_sequence.pl should be run
directly using the '-R' option (type 'update_sequence.pl' for a description on the usage of this script).
<P>\n";
    return $output;
}

#
# DONE
#
####################
sub OH_Solution_Flow {
####################
    #
    # Describe main laboratory procedures and their interaction with the database...
    #
    #

    my $output = h2("Database Interactions During Standard Laboratory Procedures");

    my $Flow = HTML_Table->new();

    #   $Flow->Set_Class('small');
    $Flow->Set_Headers( [ 'Step', 'Database Changes' ] );
    $Flow->Set_Width('100%');

    $Flow->Set_Row(
        [   '<B>Recieve new Reagent</B>',
            "<B>Solution</B> (new)<UL><LI>Name<LI>Recieved Date<LI>Quantity<LI>Supplier<Li>Lot Number<LI>Catalog Number<LI>Type (if Primer/Buffer/Matrix)<LI>Status = 'Unopened'<LI>Cost<LI>Expiry Date<Li>Bottle Number<LI>Quantity Used = 0<LI>Location (Rack)</UL>"
        ]
    );

    $Flow->Set_Row(
        [   '<B>Mix Solutions</B><BR>eg. A & B',
            "<B>Solution</B> (new)<UL><LI>(similar to above except:)<LI>Recieved Date = NULL<LI>Start Date = (current)<LI>Supplier = 'GSC' (in house)<LI>Cost = (calculated)</UL><BR><B>Mixture</B> (new)<UL><LI>Solution Made<LI>Solution Used (A)</UL><BR><B>Mixture</B> (new)<UL><LI>Solution Made<LI>Solution Used (B)</UL><BR><B>Solution</B> (update A)<UL><LI>Quantity Used += ?<LI>Status = 'Open' (if not already)</UL><BR><B>Solution</B> (update B)<UL><LI>Quantity Used += ?<LI>Status = 'Open' (if not already)</UL><BR>..."
        ]
    );

    $Flow->Set_Row( [ '<B>Use Solutions</B>', "<B>Preparation</B> (new)<UL><LI>Employee<Li>Time<Li>Equipment(if applic)<Li>Solution_ID(if applic)<Li>Conditions<Li>Comments</Ul><B>Solution</B> (update)<BR><UL><LI>Quantity_Used += ?</UL>" ] );

    $Flow->Set_Row( [ '<B>Empty Solution</B>', "<B>Solution</B> (new)<UL><LI>Status = 'Finished'<Li>Finished Date = (current)</UL>" ] );

    $output .= $Flow->Printout(0);
    return $output;
}

#
# DONE
################################
sub OH_Rearray_definitions {
################################
    my $output = h2("Basic Re-Array Types (Definitions)");
    $output .= "<UL><LI><H3>On Order</H3> - This is a list of plates that are expected to be rearrayed, but the primers are not yet in.<P>";
    $output
        .= "<LI><H3>Reserved</H3> - This is a list of plates that are requested (via bioinformatics) for re-arraying.<Br>The primers in these cases should be available and ready for re-arraying.<BR>Target plates in this case have ALREADY been assigned and also have a 'Reserved' Status which will be set to 'Active' once the ReArray is specified as complete.<BR><B>Assignment of these ReArrays does NOT create a new plate (it is already assigned)</B><P>";
    $output
        .= "<LI><H3>Requested</H3> - This is a list of plates that are requested (via bioinformatics) for re-arraying.<Br>The primers in these cases should be available and ready for re-arraying.<BR>Target plates, however, are NOT yet defined since they have yet to be 'Assigned'.<BR><B>Assignment of these ReArrays CREATES a new plate</B><P>";
    $output .= "<LI><H3>Assigned</H3> - This is a list of plates that were previously 'Requested', and have now been assigned to a plate.<Br>Target plate information should now be available for these.<P>";
    $output .= "<LI><H3>Re-Assigned</H3> - This is a list of plates that were previously assigned, but have been assigned again.<P>";
    $output .= "<LI><H3>Manually Applied</H3> - This is a list of plates that were Re-Arrayed manually.<Br>ie. the plate to plate mapping was specified by the user for the entire plate.<BR><B>Assignment of these ReArrays CREATES a new plate</B><P>";
    $output .= "<LI><H3>Completed</H3> - This is a list of plates that were Re-Arrayed, and have been processed (data analysis available).<P>";
    $output
        .= "<LI><H3>Aborted</H3> - This is a list of plates that were initially specified to be re-arrayed, but which are no longer to be completed.<BR>This may be because either the primers did not come in or some other reason further down the pipe.<P>";
    $output .= "</UL>";

    $output .= h2("Re-Arraying instructions");
    $output .= "To Re-Array a plate there are two standard methods:";
    $output .= "<UL><LI>Manually setting up a re-array from another plate";
    $output .= "<LI>Setting up a re-array based on a specified assignment</UL>";

    $output .= "(more help to be included...)\n";
    return $output;
}

#
# DONE
#
#########################
sub OH_Mixing_solutions {
#########################
    my $output = h2("Mixing Solutions");
    $output .= &Views::Heading("Using the scanner");
    $output .= h3("From the scanner choose a standard solution or select any number of solutions to mix together from the main page");
    $output .= "<Img src='$Help_Image_dir/standard_solutions.png'><P>";

    $output .= &Views::Heading("From the web page");
    $output
        .= h3(
        "The easiest way to make solutions from the home page is to simply scan the solutions that you wish to mix into the main textfield box on the home page.  You will then be directed to a page that will prompt you for the respective quantities of each reagent:"
        );

    $output .= "<Img src='$Help_Image_dir/Std_Solutions.png'><p ></p>";
    $output .= "This page will dynamically calculate the total volume of the final product, as well as its calculated value.<BR>At the bottom of the page you should also indicate the location in which the solution will be stored.";

    return $output;
}

#
# DONE
######################
sub OH_new_reagents {
######################
    my $output = h2("Entering New Reagents into the Database");
    $output .= &Views::Heading("Using the scanner");
    $output .= h3("Due to the amount of information that should be added, this will not yet be available via the barcode scanners.  Information should be added through a standard keyboard.");

    $output .= &Views::Heading("From the web page");
    $output
        .= "In the future, new items will be entered by clicking on a record from the Orders Database,<BR>but for the time being, please add Reagents (as well as Boxes or Kits) from the 'Reagents' Home page.<BR>(click on the Reagents icon at the top of the page).<P>
    After selecting 'New Reagent', you will be directed to a standard page which allows you to fill in appropriate information for the 'Stock' Table.  This records general information for a batch of items of any type (including Solutions, Reagents, Boxes, Kits, Equipment, Service Contracts, or anything else (Misc_Item).<P>When the 'New Reagent' option is selected the 'Stock_Type' should automatically be set to 'Reagent' (It would be set to 'Kit' if 'New Kit' is selected).<P>The Stock_Source indicates whether this batch of items is the result of:<UL><LI>an 'Order'<LI>something that has been taken from an existing barcoded Box<LI>making something 'in House' (eg Solutions).</UL>
<Img Src = '$Help_Image_dir/Adding_Stock.png'>
<P>
After entering the appropriate information (which will be common for all units in the same batch), a record will be saved and for every unit indicated as received (The number of bottles in the case of Reagents), an individual record will be added to the 'Solutions/Reagents' database as well.<P>At this time, the screen will show a summary of the information recorded for the batch<BR>
(which may be edited if required by clicking on the 'Edit' button below the batch information)<BR>
<Img Src = '$Help_Image_dir/New_Stock.png'>
<BR>..as well as a line by line list of the resultant Reagents that have been added to the database. (ie. if you have indicated that 5 bottles were received, there would be 5 records created - one for each barcoded bottle.<BR>At this time, any changes to individual Reagents may be made, though normally, there should be no need to make changes. (On this form, for instances, specific values may be set for Serial Numbers if applicable, or Expiry dates or 'Open/Unopened' status for Solutions/Reagents.
<Img Src = '$Help_Image_dir/New_Reagents.png'>
<P>From here, you may go to another page by clicking another icon, or scan another item in front of the 'Scan' field at the bottom of the page\n";

    return $output;
}

#
#   DONE  (redundant)
######################
sub OH_new_plates {
######################
    my $output = h2("Entering New Plates into the Database");

    $output .= &Views::Heading("From the web page");
    $output .= "\n
Go to the 'Plates' icon.
<p ></p>
From here you should choose whether you are transferring it from another plate, creating a new original or re-pooling from another library.
<P>
Select the library that you wish the plate to be associated with and click on the 'Create Plate' button.
<P>
A new barcode will be printed out at this point as well.
\n";

    $output .= &Views::Heading("Transferring Plates");
    $output .= "\n
Normally plate transferring is tracked when you follow normal laboratory procedures using the barcode scanner.  This is generally preferable, though you may transfer plates manually from the 'Plate' homepage as well.
\n";
    return $output;
}

##
# DONE
######################
sub OH_new_libraries {
######################
    my $output = h2("Entering New Libraries into the Database");

    $output .= &Views::Heading("From the web page");

    $output .= "\n
There is quite a bit of information that we would like to store for each library, so it would be helpful if you were able to acquire this information before attempting to create it.  This will remove the necessity of returning at a later date and adding the information (which can quite easily be neglected).  In a pinch however, it is possible to create a library with a minimum of information, if there is a need to generate Plates/Sample Sheets before further information is available.
<P>
<p ></p>The following information is generally required for the library <Font color=red>(Mandatory Fields shown in red)</Font>: 
<p ></p>
    <Ul><LI><B><Font color=red>Name</Font></B> - This MUST be 5 alpha-numeric characters.  Though it is nice to keep this name somewhat meaningful, this is an Identification field, and is not meant to act as a human-readable reference to a library.  In theory, this could be simply a 5 digit number which, though meaningless to a user, provides the database with an index to this particular library.  Often the format will be simply two letters followed by an incrementing number.  (such as 'CN001','CN002' for the first two Cryptococus Neoformans libraries), though if it is useful, the positions of numbers and letters is flexible (ie. spgpW or P2001)
    <LI><B><Font color=red>FullName</Font></B> -This is usually set to a brief, but more meaningful name for the library
    <LI><B><Font color=red>Type</Font></B> -This is usually set to indicate whether the library is an EST,cDNA or SAGE Library
    <LI><B>Organism</B> - This indicates the organism from which the library is created
    <LI><B>Source</B> - This indicates where the library originated (eg Jim Kronstad, UBC)
    <LI><B>Source Name</B> - This is the name given the library by the original source listed above
    <LI><B>5Prime_Cloning_Site</B> - This indicates the name of the Restriction Enzyme if appropriate
    <LI><B>5Prime_Cloning_Sequence</B> - This indicates the actual sequence of the Restriction Enzyme
    <LI><B>3Prime_Cloning_Site</B> - This indicates the name of the Restriction Enzyme if appropriate in the 3' direction
    <LI><B>3Prime_Cloning_Sequence</B> - This indicates the actual sequence of the 3' Restriction Enzyme
    <LI><B>Host</B> - This indicates the Host Cells (eg. SOLR or DH20B)
    <LI><B>Sex</B>
    <LI><B>Strain</B>
    <LI><B>Tissue</B>
    <LI><B>Description</B> - a more lengthy description of what the library is composed of
    <LI><B><Font color=red>Vector</Font></B> - This indicates the vector that is used.  If this vector is already in the database, no further info is required.  However, there is information that is also required for the Vector if it a new one.  If no Vector exists for a given library, use the Vector Name: 'Test'
    <HR>
<H2>When you are ready...</H2>
Select the 'Libraries' icon from the top of the page.
<P>
If you are creating a new library with many similar fields to one that is already in use, it is probably quicker to first search for this library using the 'Search' button, and entering the library name in the Library_Name field.  After making any changes, you should then press the 'Save as New Record' button at the bottom of the page to select this as a NEW library.  (If you simply press 'Save Changes', it will EDIT the current library rather than making a new one).
<P>
Note: You can also get to this page by clicking on any library hyperlink (such as on the 'Last 24 hours' page), and then pressing 'Edit Table' to make a new library with similar data, or 'Append Table' to enter all new data
\n";
    return $output;
}

#
# Done
######################
sub OH_new_projects {
######################
    my $output = h2("Entering New Projects into the Database");

    $output .= &Views::Heading("From the web page");

    $output .= "\n
Generally new projects should be entered with the assistance of the database administrator, but it is possible to add new projects to the database via the web page.
<p ></p>
    To do this, you should go to a hyperlink which includes the Project in it (such as the hyperlink to a Library on the 'Last 24 Hours' page), and then click on the Project (it doesn't matter which one it is).  
<p ></p>
Once the project information is displayed,there should be an option at the bottom of the page to 'Append this Table'.  This allows you to add a new Project to the database.
\n";
    return $output;
}

#
#
# DONE
#########################
sub OH_making_changes {
#######################
    my $output = h2("Making Changes to (Editing) Database Entries");
    $output .= "\n
 To make changes to entries, you may utilize any of the hyperlinks that point to database info.
 <p ></p>
 From most of these pages there are options below to Edit the entry,  <br>
 (or search the database for another entry) <br>
 <p ></p>
 There are also more direct routes to search/edit provided via the 'Plates', 'Libraries' and 'Sample Sheets' pages for editing the Plate, Library or Run (Run info) records respectively. 
  <p ></p>
  When making changes, note the following:

 <UL>
 <LI>use 'Save Changes' to <B>CHANGE</B> current values.
 <LI>Use 'Save Changes as New Record' to add a <B>NEW</B> record.
 </UL>

 Note when Saving changes as a new record:
 <UL><LI>Sometimes UNIQUE fields are shown (eg. Run ID). <br> 
 In these cases, the value must be erased (ID's will automatically generated), <br>
 or changed (such as Run_Directory which must also be unique)

\n";
    return $output;
}

#
# DONE
########################
sub OH_deleting_mistakes {
########################
    my $output = h2("Annotating records with notes");
    $output .= "\n
Sometimes mistakes are made during laboratory procedures that cause errant records to be placed in the 
database.  These can often be removed from the database.
<p ></p>
<B>Removing invalid plates:</B><BR>
Plates can be removed by going to the 'Plates' page icon and then selecting the <B>Check Recent Plates</B> Button.  This will bring up plates made by the same user within the last 7 days. 
<p ></p>
From here users can select any number of plates for deletion <BR>
(you may instead mark plates as failed, or annotate any number of plates with a common note)
<P>
Note: If any other data points to a plate, you will NOT be able to delete it.<br>
(if for example a sequence run uses a plate - then you will not be able to delete that plate).<BR>
<P>
<B>Removing Run Requests (sample sheets):</B><BR>
Requests for Sequence Runs can be erased in a similar fashion by going to the 'Sample Sheets' page and selecting 'Remove Run Requests'.  Again the user will be given a list of all requests that they have made that have not yet been analyzed.
<P>
<B>Removing Solutions (or Reagents):</B><BR>
Solutions can be deleted in a similar fashion.  By clicking on 'Check my Recent Solutions', the user may select any number of recently made solutions for deletion (as long as they have not been used in the meantime).  The same page allows users to reprint a number of barcodes at the same time.
<P>

\n";

    return $output;
}

#
# DONE
#
########################
sub OH_making_notes {
########################
    my $output = h2("Adding comments or notes");
    $output .= "\n
Sometimes plates or sequence runs will be failed or annotated with a comment.  This can be done on a group of plates or sequence runs together by going to the same page used to delete entries for plates, or to the 'Check Runs Already Analyzed' for Sequence Runs which have already been analyzed.  An option at the bottom of the page is available for annotating (or marking as failed), the Plates or Runs selected.
<p ></p>
\n";

    return $output;
}

#
# DONE
#
#######################
sub OH_Stock_Help {
#######################
    my $output = &Views::Heading("Keeping Track of Chemicals & Reagents");

    my $Stock = HTML_Table->new();
    $Stock->Set_Line_Colour( 'white', 'white' );

    #    $Stock->Set_Title("<H1>Keeping Track of Chemicals & Reagents</H1>",'white');
    $Stock->Set_Alignment( 'center', 2 );
    $Stock->Set_Row( [] );
    $Stock->Set_Row(
        [   "To ensure that stock supplies remain conservative, when a new catalog number is entered into the database, administrators have the option of specifying a 'minimum number of units' for this item.  If stock falls below this value, notification will be sent to indicate that this item needs to be resupplied",
            "<Img src='$Help_Image_dir/Notice.png'>"
        ]
    );
    $Stock->Set_Row( [] );
    $Stock->Set_Row( [ "In addition, when new chemicals/reagents are added, the user will be shown the current stock supply of that item (showing the number of Unopened, Open and Finished Bottles)", "<Img src='$Help_Image_dir/Status.png'>" ] );
    $Stock->Set_Row( [] );
    $Stock->Set_Row(
        [   "This allows stocks of Reagents & Chemicals to be monitored regularly.  If a particular item is low on stock, an e-mail notification is sent to re-supply the item, showing the current available bottles in stock",
            "<Img src='$Help_Image_dir/Email.png'>"
        ]
    );
    $output .= $Stock->Printout(0);
    return $output;
}

#
# DONE
#
#######################
sub OH_ReArray_Help {
#######################
    my $output = &Views::Heading("ReArraying and Importing Plates");

    my $ReArray = HTML_Table->new();
    $ReArray->Set_Line_Colour( 'white', 'white' );

    #    $ReArray->Set_Title("<H1>ReArraying and Importing Plates</H1>",'white');
    $ReArray->Set_Line_Colour( 'white', 'white' );
    $ReArray->Set_Row( [] );
    $ReArray->Set_Row(
        [   "<B>Viewing ReArray Requests:</B> When ReArray requests are made by Yaron, they can be viewed by selecting the 'View ReArray Requests' button from the Plates home page.  From here, you can print out the Well assignments, and/or assign these Requests to an actual Plate.<P><B>Note:</B><BR><B>'Requested'</b> ReArrays will be assigned to a new plate (and a new barcode generated).<BR><B>'Reserved'</B> ReArrays will be assigned to a plate whose barcode has already been reserved.  (A new plate will not be generated, but a barcode will be reprinted, and the plate status changed from 'Reserved' to 'Active').",
            "<Img src='$Help_Image_dir/Auto_Assign.png'><HR>",
        ]
    );

    $ReArray->Set_Row( [] );
    $ReArray->Set_Row(
        [   "<B>Importing Plates:</B> When creating a new Plate you are now given the additional option of 'Importing' a plate.  In this case, you can create a plate that you expect to import from another source, giving it a specific name.  This will create a blank entry in the Clone table, indicating to BioInformatics (Yaron) that data for these Clones should be collected and fed into the 'Clone' table as required.",
            "<Img src='$Help_Image_dir/Import.png'><HR>",
        ]
    );
    $ReArray->Set_Row( [] );
    $ReArray->Set_Row(
        [   "<B>Set Up ReArray Plate:</B> This will allow a user to enter any number of plates and wells that are to be re-arrayed onto another plate, specifying the primer as well as the target and source well positions.  This will create a barcode for the new plate and keep track of where each well in the new plate originated",
            "<Img src='$Help_Image_dir/ReArrayed.png'><HR>"
        ]
    );
    $output .= $ReArray->Printout(0);

    return $output;
}

#
# DONE
#
######################
sub OH_Scanner_Help {
    ######################
    my $output = &Views::Heading("Using the Scanner");

    $output .= "<Img src='$Help_Image_dir/Scanner.png'> <BR>

    For the time being there are a couple of limitations on the scanner that will hopefully be resolved in the future.
<UL><LI>There is no back button (don't try to use it - or you will lose your place)
<LI>You need to currently use the pen. <BR>
(Again, it is hoped that we can set it up to work without the pen, but this will take a bit longer to set up)

<H3>To access the barcode website:</H3><UL>
    <LI>Turn on the scanner (red key at bottom left)
    <LI>click on Internet Explorer (drop down menu at top left of screen)
    <LI>click on the folder ('Favorites')icon at the bottom of the screen
    <LI>click on the file 'scanner' (while it loads the explorer icon should be visible at the top right of the screen)
    <LI>Identify yourself and press the 'Login' button</UL>
    
    
<HR><H3>Using the Application Buttons</H3>
    
<Img src='$Help_Image_dir/Scanner_bottom.png'><BR>
    
Application buttons allow you to quickly go to particular applications.<BR>
The scanners should be set up to provide the following quick links 
(accessed by simply pressing the appropriate application button):
    
<H3>Application Buttons</H3>
<UL><LI>A1 - Internet Explorer
    <LI>A2 - File Explorer (to run scanner initialization if necessary)
    <LI>A3 - Calculator
    <LI>A4 - Signal Checking Routine ...</UL><HR>
\n";

    $output .= &Views::Heading("Some Other Useful Keys to Know ...");

    my $Scanner = HTML_Table->new();
    $Scanner->Set_Width('100%');
    $Scanner->Set_Headers( [ 'Options', 'Keys to Press' ] );
    $Scanner->Set_Row( [ 'Internet Explorer',    'A1' ] );
    $Scanner->Set_Row( [ 'File Explorer',        'A2' ] );
    $Scanner->Set_Row( [ 'Calculator',           'A3' ] );
    $Scanner->Set_Row( [ 'Signal Checking',      'A4' ] );
    $Scanner->Set_Row( [ 'Keyboard Toggle',      'A5 (top)' ] );
    $Scanner->Set_Row( [ 'Turn on Backlighting', 'Function + any App Button' ] );
    $Scanner->Set_Row( [ 'Back Button',          '(Not available)' ] );
    $Scanner->Set_Row( [ 'Warm Re Boot',         'Scroll + A4' ] );
    $Scanner->Set_Row( [ 'Adjust Font Size',     "'View' (bottom left)... 'Text Size'..." ] );

    $output .= $Scanner->Printout(0);

    $output .= hr . &Views::Heading("If the laser doesn't operate when you press the scan button");
    $output .= "
<UL>
    <LI>Go to 'File Explorer' (from drop-down menu at top left)
    <LI>select 'ScanWedge' from list of files (this should initialize the scanner)
    press A1 (or return to Internet Explorer via the drop-down menu at the top left) and continue</UL>
\n";

    $output .= &Views::Heading("Warm Booting");
    $output .= "
<H3>If the system is really hung up badly, try a Warm Re-Boot<BR>
(press the A4 and Scroll Button at the same time).<BR>
If this still does not work, a cold boot may be necessary <BR>
- See Below (though you should probably check with admin first)</H3>";

    $output .= &Views::Heading("Cold Booting");
    $output .= "
<Img src='$Help_Image_dir/coldboot.png'>
<p ></p>
<h2>Re-Initializing after a Re-Boot</h2>
 If you need to perform a full cold reboot, the configuration settings may have to be reset.<bR>
The following procedure should set the unit back up to operate properly:

<OL>
<LI>Start | Settings | Connections | Network
<LI>Select Spectrum24 Wireless LAN PC Card
   <UL><LI>enter the IP address from the sticker on the back <BR>
(e.g. 10.1.1.152 for ppt02) - NOT the IP address from the bridge (10.1.1.150)
    <LI>subnet mask is 255.255.255.0
    <LI>default gateway is 10.1.1.1
    <LI>hit OK in top right of screen
    </UL>
<LI>Select NE2000 Compatible Ethernet Driver
    <UL><LI>enter the IP address from the sticker on the back
        <LI>subnet mask is 255.255.255.0
        <LI>default gateway is 10.1.1.1
        <LI>select the Name Servers tab
        <LI>enter 10.1.1.8 in the DNS field - leave other fields blank
        <LI>hit OK in top right of screen
</UL>
RF:

<PRE>

1. Start | Programs
2. Run NICTT
3. Select the 'General' tab
4. Enter 102 in the ESSID field. This is the network ID for the bridge

TURN UNIT OFF
TURN UNIT ON

1. Start | Programs
2. Run NICTT
3. Select the 'Signal' tab
    - the signal quality should be 'Excellent'
    - the network status should be 'In range'
    - if the unit is not networked - CHECK WITH SYS SUPPORT
4. Select the 'Transmission' tab
5. Enter 10.1.1.8 in the Host Address box
6. Hit 'Start Test'
    - this will begin pinging the file server to test the unit's networking
    - it should proceed without trouble giving an average return time of 200-400 ms.
    - if you get any other significantly different results CHECK WITH SYS SUPPORT

Checking Status From A Workstation (optional)

1. open a console
2. ping the pocket pc you just set up
    - ping IP where IP is the address assigned previously (e.g. ping 10.1.1.152 for ppt02)
    - the standard values for the return times should be around 200-400ms.

This unit responds SLOWLY
    - if you get any other significantly different results CHECK WITH SYS SUPPORT

</PRE>
<HR>
\n";
    return $output;
}

#
# DONE
#
###################
sub OH_ReBooting {
###################

    my $output = &Views::Heading("Using the Scanner");

    $output .= "<Img src='$Help_Image_dir/Scanner.png'> <BR>";
    $output .= &Views::Heading('Warm Booting');
    $output .= "
<H3>If the system is really hung up badly, try a Warm Re-Boot<BR>
(press the A4 and Scroll Button at the same time).<BR>
If this still does not work, a cold boot may be necessary <BR>
- See Below (though you should probably check with admin first)</H3>";

    $output .= &Views::Heading('Cold Booting');
    $output .= "
<Img src='$Help_Image_dir/coldboot.png'>
<p ></p>
<h2>Re-Initializing after a Re-Boot</h2>
 If you need to perform a full cold reboot, the configuration settings may have to be reset.<bR>
The following procedure should set the unit back up to operate properly:

<OL>
<LI>Start | Settings | Connections | Network
<LI>Select Spectrum24 Wireless LAN PC Card
   <UL><LI>enter the IP address from the sticker on the back <BR>
(e.g. 10.1.1.152 for ppt02) - NOT the IP address from the bridge (10.1.1.150)
    <LI>subnet mask is 255.255.255.0
    <LI>default gateway is 10.1.1.1
    <LI>hit OK in top right of screen
    </UL>
<LI>Select NE2000 Compatible Ethernet Driver
    <UL><LI>enter the IP address from the sticker on the back
        <LI>subnet mask is 255.255.255.0
        <LI>default gateway is 10.1.1.1
        <LI>select the Name Servers tab
        <LI>enter 10.1.1.8 in the DNS field - leave other fields blank
        <LI>hit OK in top right of screen
</UL>
RF:

<PRE>

1. Start | Programs
2. Run NICTT
3. Select the 'General' tab
4. Enter 102 in the ESSID field. This is the network ID for the bridge

TURN UNIT OFF
TURN UNIT ON

1. Start | Programs
2. Run NICTT
3. Select the 'Signal' tab
    - the signal quality should be 'Excellent'
    - the network status should be 'In range'
    - if the unit is not networked - CHECK WITH SYS SUPPORT
4. Select the 'Transmission' tab
5. Enter 10.1.1.8 in the Host Address box
6. Hit 'Start Test'
    - this will begin pinging the file server to test the unit's networking
    - it should proceed without trouble giving an average return time of 200-400 ms.
    - if you get any other significantly different results CHECK WITH SYS SUPPORT

Checking Status From A Workstation (optional)

1. open a console
2. ping the pocket pc you just set up
    - ping IP where IP is the address assigned previously (e.g. ping 10.1.1.152 for ppt02)
    - the standard values for the return times should be around 200-400ms.

This unit responds SLOWLY
    - if you get any other significantly different results CHECK WITH SYS SUPPORT

</PRE>
<HR>
<h2>After Rebooting</H2>";

    $output .= &Views::Heading('Re-Initializing the scanner');
    $output .= "<UL>
<LI>Go to File Explorer (Button 2) <BR>
- (if you cannot find File Explorer, first 'Reset Buttons' - see below)
<LI>Click on the Scan Wedge Program<BR>
- (if you cannot find the Scan Wedge Program, first 'Download Programs' - see below)
</UL>";

    $output .= &Views::Heading('Re-Setting the Buttons');
    $output .= "Sometimes the Buttons will require resetting.<BR>
(The buttons at the bottom of the panel should allow quick access to IE, File Explorer etc)
<UL>
<LI>Start..Settings...
<LI>Click on the 'Buttons' Icon at the top left
<LI>Click on Button 1<BR>
<LI>Select 'Internet Explorer' from the drop-down menu<BR>
(This sets button 1 as a quick link to IE)
<LI>Similarly set Button 2 to 'File Explorer'
<LI>Set Button 3 to 'Calculator'
<LI>Set Button 4 to 'Notes'
<LI>Set Button 5 to '<Input Panel>'<BR>
(Button 5 is the one at the top right of the device)
</UL>";

    $output .= &Views::Heading('Downloading Programs');
    $output .= "Sometimes the programs on the device will have to be downloaded again from the NT.
<UL>
<LI>Click on the ActiveSync icon on the right side of the desktop (bioinformatics NT)
<LI>Choose:  'File'..'Get Connected'<BR>
(The handheld must first be in the cradle behind the computer)<BR>
(Sometimes you may have to try this a second time)
<LI>Once connected, choose:  'File'..'Explore'<BR>
(This should open up a directory window)
<LI>Open up the 'Sync Files' folder (on the right side of the desktop)
<LI>Copy the 'ScanWedge' file into the 'Mobile Device' folder<BR>
(You should now find the ScanWedge Program in File Explorer)
<LI>Go to the My Pocket PC/Windows/Favourites/ directory in the 'Mobile Device' folder.
<LI>Copy the 'scanner', and 'scanner_test' files into the 'Favourites' directory<BR>
(You should now find these options available from Internet explorer)
</UL>

\n";
}

#
# DONE
#
#########################
sub OH_Protocols {
########################
    my $output = &Views::Heading("Plate Tracking");

    my $Prep = HTML_Table->new();
    $Prep->Set_Width('75%');
    $Prep->Set_Table_Alignment('Center');
    $Prep->Toggle_Colour(0);

    #$Prep->Set_Title("<H1>Plate Tracking</H1>");
    $Prep->Set_sub_title( 'Defining the Protocol', 2, 'lightgreenbw' );
    $Prep->Set_sub_header(
        "Before tracking can take place, a detailed protocol is written up and stored in the database, including in the definitions of each step the inputs that are required (or available), default values, instructions, and whether or not the step is to require feedback from the scanner.  This is administered through the Protocol Administration program.<BR><Img Src='$Help_Image_dir/protocol_define.png'>",
        'white'
    );
    $Prep->Set_sub_header( 'Monitoring the Protocol',                                                                                                            'lightgreenbw' );
    $Prep->Set_sub_header( "The protocol may be monitored and edited to ensure that it is always up to date.<BR><Img Src='$Help_Image_dir/Protocol_admin.png'>", 'white' );

    $Prep->Set_sub_header( 'Scanner Home Page', 'lightgreenbw' );
    $Prep->Set_Row(
        [   "At the home page of the scanner, the user is given a number of options including:<UL><LI>Scanning any barcoded item to get a description of it<LI>Scanning a group of plates to define as a plate set<LI>Making up a standard batch of Solution I<LI>Making up a standard batch of Solution II<LI>Retrieving a plate set immediately by entering the plate set number</UL>",
            "<Img Src='$Help_Image_dir/scanner_home.png'>"
        ],
        'white'
    );
    $Prep->Set_sub_header( 'Selecting a Protocol', 'lightgreenbw' );
    $Prep->Set_Row(
        [   "The user then selects the Protocol they wish to use from a popdown menu.<BR>Alternatively the user can Display a plate history (showing all preparation done for the current plate or plate set)", "<Img Src='$Help_Image_dir/plateset_home.png'>"
        ],
        'white'
    );
    $Prep->Set_sub_header( 'Stepping through the Protocol', 'lightgreenbw' );
    $Prep->Set_Row(
        [ "Through each step of the protocol, the user scans appropriate Equipment, Reagent etc. as required.  Fields for input are automatically generated based on the protocol step definitions.", "<Img Src='$Help_Image_dir/protocol_step.png'>" ],
        'white' );
    $Prep->Set_sub_header( 'Viewing a plate history', 'lightgreenbw' );
    $Prep->Set_Row(
        [   "A history of what has been done for a plate or plate set is available as well to monitor what has already been tracked showing<UL><LI>The Plate Set Number<LI>The Plate (if a step relates each plate with a unique piece of equipment)<LI>The Protocol Name<LI>The Protocol Step Name<LI>The time the procedure was performed<LI>The user who performed the procedure</UL>",
            "<Img Src='$Help_Image_dir/plate_history.png'>"
        ],
        'white'
    );
    $output .= $Prep->Printout(0);
    return $output;
}

#
# DONE
#
##########################
sub OH_Protocol_Formats {
##########################
    my $output = &Views::Heading("Protocol Formats");

    $output .= "\n
Some of the Protocol Names should be in a specific format so
that they may be handled automatically, such as:
<UL>
<LI>
<B>Transfer to NUNC</B><BR>
This indicates that plates are to be transferred to another format.<BR>
The format should exactly match the format name for the new format.<BR>
eg.  'Transfer to NUNC' or 'Transfer to Robbins - 96ET'
<LI><B>Transfer to *</B><BR>
This indicates that a popup menu should prompt the user for
the Plate Format type...
<LI><B>..Antibiotic..</B><BR>
Anything with the string 'Antibiotic' in the Step Name will check for valid
antibiotic depending upon Vector associated with Plate Libraries.<BR>
The Solution_Name must contain the Antibiotic Specified.<BR>
<LI><B>'Thermocycle' or '384 Well Thermocycle'</B><BR>
This name format will be used to look for Thermocycled Plates,
used for tracking plate processes.
</UL>\n<P>";

    $output .= &Views::Heading("Database structure info");

    $output .= "\n
The structure of the Protocol Table includes the following specially formatted fields:<BR>
(The values in these fields are <B>colon delimited </B>and should be <B>consistent in number & order</B>)
<UL>
<LI>Input - input fields available on form (eg. 'FK_Equipment__ID,FK_Solution__ID,Solution_Quantity')
<LI>Protocol_Defaults - default values if applicable (eg. '::0.5')<BR>
(In this case the Equipment, Solution have no defaults, but the Solution_Quality defaults to 0.5)
<LI>Input_Format - validation requirements (eg. 'Hydra:BD:')<BR>
(In this case the Equipment must be of type 'Hydra' and the Solution_Name must contain the string 'BD')
</UL>
(These checks are made in the 'Check_Formats' routine in the 'Process.pm' module) <P>
There is also a field 'Scanner' which indicates whether this step is to be tracked.<BR>
(Some steps are part of the protocol, but are not tracked with the scanner).<P>
There is also a table containing a list of protocols ('Protocol_List').<BR>
It contains a list of all protocol names, the author, as well as the state of the protocol (Old, Inactive, or Active), and an optional description.  Only those set as 'Active' will appear as options.

\n";

    return $output;
}

#
# DONE
#
##########################
sub OH_Manual_Analysis {
##########################
    my $output = &Views::Heading("Running Analysis from the Command Line");

    $output .= "\n
Phred Analysis may periodically be run from the command line for purposes of time, or to specify particular options (such as the reversal of plate orientation), or to re-analyze a run that was originally misnamed etc.
<P>
Generally the format for accomplishing this is:
<B>/home/rguin/public/update_sequence.pl -A all -S (RunID) (options)</B> <BR>(Where the RunID and options are entered by the user)<BR>
Some of the available options include:<UL>
<LI>-R Reverse orientation of plate...
</UL>
\n";

    return $output;
}

######################### Code Specific Help ###############################

#
#  DONE
#
##########################
sub OH_Debugging_Errors {
##########################
    my $output = &Views::Heading("Debugging_Errors");

    $output .= "\n
For Debugging problems in the lab, I am tracking the Sessions for each user, monitoring all parameters sent each time a button is pressed.
When a user hits the 'Error Notification' button, a message is sent to the administrator, indicating that an error occurred.<BR>
Both the user and the time of the error is indicated, as is a link to the session page.<BR>
The session page displays all parameters passed through each execution of a web page link.  The administrator may then observe exactly what processes were being completed, and may retrieve the session by clicking on the appropriate time stamp button.
<P>
If an 'Error Notification' button is seen in the parameter list, generally the administrator should retrieve the PREVIOUS page to avoid re-executing a command that may affect the database...
\n";

    $output .= &Views::Heading("Database Access Errors");
    $output .= "Sometimes the mysql database will get locked up, disabling people from interacting with it (or with specific tables within it).  This is a partial list of some possible problems that have occurred in the past, and solutions:<UL>
<LI>Table handling error (28 ?) - this has been caused in the past by the tmp directory on SQL server filling up.  If this is the case, it needs to be cleared out.
<LI>A runaway process - If anyone has run SQL queries, (even if they cancel the query with ctrl-c), their process may still be running.  Have them log into mysql and type 'showprocesslist'.  This will display current running commands.  You may kill the process from here by typing kill \$idNumber.  Most users can only see or kill their own processes, but Martin can see all running processes and kill any of them if necessary.  Processes should be killed to see if this is the problem before assuming the data is corrupt.  If, however, after killing processes, the system continues to hang up when one tries to access tables through simple commands, it could be a problem with corrupt data. 
<LI>Corrupt data - you should then restore the affected tables within the database (see note on Restoring Database).
<LI>Generally slow response... Take a look to make sure no large jobs are running on either SQL server or on the web server (if access is slow via the web).  For scanners, check memory usage, and ensure that Netscape pages are not being cached.
\n";

    return $output;
}

###################
sub OH_DB_Modules {
#####################
    my $output = &Views::Heading("Database Module routines");

    $output .= "\n
There are a number of useful routines that are available through 
the Database modules in /Production/SeqDB/SDB/<P>
See the info on the Table.pm and Views.pm modules on the Sequencing Info Page
(<A Href='http://rgweb.bcgsc.bc.ca/index.shtml'>rgweb.bcgcs.bc.ca</A>)
<UL>
<LI>Table_retrieve   - retrieves specified fields from a list of tables (as hash)
<LI>Table_find_array - retrieves specified fields from a list of tables (as array of comma-joined values)
<LITable_append_array - adds records into specified table
<LI>delete_records - allows deletion of specified records

</UL>
<P>
Each of the above routines ensures that users have permission for editing/deleting and that foreign key values are valid.

There are also a number of standard forms used for visualizing data including:
<UL>
<LI>view_records
<LI>edit_records
<LI>mark_records 
<LI>Table_retrieve_display 
</UL>

There are also numerous other routines used to extract enumeration lists, foreign key possibilities, field lists for tables etc.  To search for any of these, try searching under a key word on Sequencing info page.
\n";

    return $output;
}

################################
sub OH_Restoring_Database {
################################
    my $output = &Views::Heading("Restoring the Database");

    $output .= "\n
If Data becomes fatally corrupted for some reason, it may be necessary to restore at least a portion of the database. <BR>
There are a couple of methods of restoring a table:<BR>
Example restoring 'Solution' Table:
<UL>
<LI>Simplest method: (quick way of restoring most recent version of database without losing any information)
<OL>
   <LI>set web page to construction mode to prevent users from editing database
   <LI>check indexes on problem table (eg: mysql>show index from Solution) so that they can be restored afterwards.
   <LI>copy database table to another database temporarily:<BR>
eg:<ul><LI>mysql>use seqtest<LI>mysql>drop table Solution<LI>mysql>create table Solution select * from sequence.Solution</ul>
   <LI>check to make sure table is fully up to date in other database (check last record)
   <LI>copy database table back to original...<BR>
eg:<ul><LI>mysql>use sequence<LI>mysql>drop table Solution<LI>create table Solution select * from seqtest.Solution</ul>
   <LI>Restore indexes that are lost through this process (ESPECIALLY Primary, Auto_increment keys)
eg:<ul><LI>mysql>alter table Solution modify Solution_ID int not null auto_increment primary key
   <LI>mysql>create index type on Solution (Solution_Type)</ul>
</OL>
<BR>Note:  it has happened that dropping the database table did NOT solve the corruption issue right away.<BR>
The one time that this was the case, restoring the database the next morning was able to solve the problem<BR>
(This may point to the caching of some data which maintains corruption for a period of time ?) 

<LI>Command line method: (this allows restoring of previous versions (backed up every 10 minutes)
<OL>
<LI>use backup_DB to backup the most recent version of the table
<BR>eg. >backup_DB -D sequence -T Solution<BR>
<LI>use restore_DB program to restore from previous version (type 'restore_DB' for help) - in /home/rguin/public/
<BR>eg. >restore_DB -D sequence -R -T Solution <BR>
(The -R switch indicates that the table should be Regenerated from scratch.) 
</UL>
\n";

    return $output;
}

############################
sub OH_Slow_Response_Time {
################################
    my $output = &Views::Heading("Handling Slow Response Times");

    $output .= "\n
An effort has been made to reduce instances of very slow response times for either the scanners or the barcode page.<P>
Below are a list of some of the causes in the past, and possible remedies:

<Table border=1><TR bgcolor=lightgreen><TD>
Cause</TD><TD>How to Check</TD><TD>What to do</TD></TR><TR>

<TD bgcolor=lightblue>Memory Issues with Scanners</TD><TD>
Check Memory by going to Start..Settings..System(option at bottom of page)..Memory<P>This should show whether the memory is being overly taxed.<BR>There should be lots of available memory in both Storage and Process locations.
</TD><TD>
If memory is a problem, you should use IE Tools to remove cache and direct Netscape to NOT store pages in cache.  (See IE Tools)
</TD></TR><TR>

<TD bgcolor=lightblue>Problems on Athena</TD><TD>
Try rlogging into SQL server, and see if there are any lengthy processes running.<BR>type 'top' to see a list of CPU draining processes.<BR>Also try checking processes on the SQL server (see Martin) to ensure that the data is not corrupted.
<P>A Table handling error has also occurred in the past which was caused by the tmp directory on SQL server filling up.
</TD><TD>
If data is corrupted, you may need to restore the Database (see Restoring Database)
</TD></TR><TR>

<TD bgcolor=lightblue>Problems on the Web Server</TD><TD>
Check the bottom of the screen to see which machine is your web server (only available on computer screen)<P>
Go onto that machine (rlogin) and see if there are any processes clogging things up.
</TD><TD>
If there are programs running:  if they are runaway processes, have them killed.  Otherwise, try switching machines by re-entering the login page, and hoping for another faster one...
</TD></TR></Table>

\n";

    return $output;
}

#################################
sub OH_Chemistry_Calculator {
################################
    my $output = &Views::Heading("Adjusting the Chemistry Calculator");

    $output .= "\n
Adjusting the Chemistry Calculator requires changing information in TWO files.<BR>
Both working files are located in '/home/rguin/Production/SeqDB/'<BR>
with alpha-version copies in '/home/rguin/cvs/SeqDB/'<BR>
(One is the general chemistry calculator, and one runs the javascript version)<P>
The following changes should be made...:
<UL>
<LI>Volumes (ul/well) are specified as the first elements of the arrays in 'SDB.js' in the function 'BrewCalc'
<LI>Volumes (ul/well) are specified in 'SDB/Chemistry.pm' as *premix, *buffer, *primer, *prep, *total_volume<BR>
    where names are prefixed by the specific chemistry - (see 'original amounts ul/well')<BR>
(ie. BD or ET; BD 4ul reactions have a '4' suffix eg. BD_premix4)<BR>
<LI>calculation parameters are saved as the last couple of elements as described in the function 'BrewCalc' (in 'SDB.js')
<LI>calculation parameters are described as comments in 'SDB/Chemistry.pm' (see 'BrewMix Calculations')
</UL>
<P>
Generally the calculations are something like...<BR>
<PRE>
 Let A = ul/well (see original volumes below...) 
 Let B = Plate Correction (*plate_adjustment)
 Let C = Extra Brew 2 (*_overload_extra)

 Let P = no. of plates.
 Let ov = overload threshold (*_overload)
 
 ... Then Volume = A*(P + B)*96) 

 AND   if (P > ov) {Volume = Volume + C*(P-ov)
</Pre>
<P>
A hard copy description of the calculations should be annotated,<BR>
with new copies labelled 'Latest' accompanied by the date.<P>
Previous 'Latest' versions should have this label crossed out and the
date of the change indicated.
<P>
<B>Sometimes default values for sample sheet generation may also have to be changed</B><BR>
(Ask Duane or Jeff to see if they are ok...)<P>
(To change the defaults, change the values in the preparess subroutine in SDB/Run.pm)
\n";

    return $output;
}

################################

################################

################################

################################
sub OH_New_Sequencer {
################################
    my $output = &Views::Heading("Adding a New Sequencer");

    $output .= "\n
To add a new Sequencer, you should be able to simply specify the directory information supplied in the file 'SDB_Defaults.pm' for each individual sequencer.<BR>
(there should be about 5 lines of codes specifying various information such as Host name, shared drive name, samplesheet directory path etc.)
<P>
You should also specify the module and mobility files in the script: 'genss.pl'
<P>
If a new type entirely is added (ie. neither a Megabace or a 3700), a number of changes will have to be made to the genss.pl file which is used to generate custom sample sheets, as well as in 'post_sequence.pl' and 'update_sequence.pl' - the programs used to analyze data automatically from trace files.
<P>
    \n\n";
    return $output;
}

################################

################################

################################

################################
sub OH_Sample_Sheets {
################################
    my $output = &Views::Heading("Sample Sheets for Sequencers");

    $output .= "\n
Various Sample sheet files are required by the sequencers to indicate various configuration information enabling them to commence the sequencing process.  These files are generated automatically when a user indicates that a certain plate (or group of plates) is to be sequenced.  After generating the file, a cron job runs which copies the generated files over to the sequencing machines (martin has this running on a regular basis).<P>  
Generally there are two main formats: 
<UL>
<LI>Megabaces - psd files
<LI>3700s     - plt files
</UL>
Templates for these formats exist in the directory: /home/alente/templates/<P>
The naming convention for the sample sheets follows the 'Run_Directory' naming convention. <BR>(eg.  'CC0015a.B7.2' for library 'CC001', plate 5a, 'B7' Chemistry, version 2 with a .psd or .plt extension)<P>
The version number is automatically determined by looking for the latest version number in the current Sample Sheet directory and incrementing it by 1 (original versions have no version number).<P>
Note there are subtle differences between the template files of different machines of the same type.  The 'genss.pl' script which generates the sample sheets makes these adjustments as required.<BR> These differences are generally related to references to various 'MODULE' files.<P>The sample sheets also include comments in the header indicating the plate(s) used, and contain appropriate configuration information such as foil piercing status, run voltage, temperatures etc.<P>
Scripts responsible for generating sample sheets include:
<UL>
<LI>genss.pl - script used to generate sample sheets.  (type genss.pl for info)
<LI>SDB/Run.pm module - this generates the web form used by users to specify that a sample sheet is to be generated (this calls the genss.pl script).  It also finds and links the appropriate Primer, Matrix by examining Plate, Equipment histories.
</UL>
(Scripts are located in '/home/rguin/Production/SeqDB/')
    \n\n";
    return $output;
}
################################

################################

################################

################################
sub OH_Directories {
################################
    my $output = &Views::Heading("Directories");

    $output .= '\n
Data for Sequencing is stored in a number of directories as follows:
<UL>
<LI>Trace Data:     /home/aldente/public/Projects/$ProjectName/$Library/AnalyzedData/$Run_Directory/chromat_dir
<LI>Phred Data:     /home/aldente/public/Projects/$ProjectName/$Library/AnalyzedData/$Run_Directory/phd_dir
<LI>Backups:        /home/aldente/private/Dumps/$database_$date/$database_$date_$time/$Table.bin
<LI>Vector Run Files: /home/aldente/public/VECTOR/
<LI>Log files:       /home/aldente/private/logs/
<LI>Sessions:              /home/sequence/SessionInfo/
<LI>Statistics:            /home/sequence/StoreStats/
<LI>Sample Sheet template files: /home/sequence/templates/
<LI>Protocol info (Ed Dere)      /home/sequence/Protocols/*/

    \n\n';
    return $output;
}

################################

################################

################################

################################
sub OH_Poor_Quality_Runs {
################################
    my $output = &Views::Heading("Poor Quality Run Diagnostics");

    $output .= "\n
On a regular basis, the average phred 20 values for runs in the past month are correlated against a number of variables.<P> Included in this list of variables are Sequencer, Matrix, Buffer as well as more detailed variables such as Solutions applied to Plates, Centrifuges, Hydras etc. - basically, anything that is tracked during the preparation of plates can be correlated with resulting Run Quality.<P>
When the results of such a correlation show that the average Phred20 length is less than 400 for any variable, this variable is flagged, and these values displayed at the top of the Diagnostics page.<BR>
<Img Src='$Help_Image_dir/Diagnostics.png'>
<P>
If you click on the Variable name (eg. Thermocycle), you will be taken to a table showing Run quality for various thermocyclers.  This may allow you to see if there is one in particular leading to poorer quality runs.<BR>
<Img Src='$Help_Image_dir/Diag_Var.png'>
<P>
The legend at the top gives you a quick view of the variation, while the average phred20 values are displayed for each thermocycler used.  Possible problematic ones are highlighted in Red.
<P>
If you click on the 'Runs' value at the right of this table (or the table at the top of the page), you will be taken to a page listing the details for all of the runs in question.<P>
For example if you click on the '6' beside the Base3 Thermal Cycler above, you will be taken to the following page, showing that the poor results are likely caused by a few particularly poor runs.<BR>
<Img Src='$Help_Image_dir/Bad_Runs.png'>
    \n\n";
    return $output;
}

##############################

##############################

##############################

##############################
sub OH_Command_Line_Scripts {
##############################

    my $output = &Views::Heading("Command Line Scripts");

    $output .= "Generally the command line scripts are available through the 
directory /home/rguin/public/...<BR>Generally descriptions for usage may be seen by simply typing the file name without any options.
<BR>Many of these scripts require execution by 'sequence'

<UL>
<LI>fasta.pl - Generates fasta files for Library or Run (options for clipping quality, vector)
<LI>update_sequence.pl - manually run phred analysis script (various options)
<LI>restore_DB - restore a database (lab users may restore seqtest database only)
<LI>backup_DB - save the current database Tables specified
<LI>decompress.pl - decompresses data more than one month old for specified libraries
<LI>searchDB - a simple, though unsophisticated command line viewer, allowing quick extraction of Phred_Scores or other data from the database.
<LI>parse_table.pl - a script that will parse a text file into the database.
<LI>post_sequence.pl - a script (used by update_sequence.pl) that may be used to perform a more step by step analysis of sequencing data.  (may be used for debugging if there are problems with auto-generation of results).
</UL>

\n";

    return $output;
}
## DONE ##

###########################

## DONE ##

###########################

## DONE ##

###########################

## DONE ##

###########################
sub Warnings_Help {
###########################
    my $warning = shift;
    my $limit   = shift;
    my $dbc     = $Connection;

    print &Views::Heading("Description of Warnings");
    my @libs = $dbc->Table_find( 'Library', 'Library_Name' );
    my @notes = $dbc->Table_find( 'Note', 'Note_Text,Note_Description', 'Order by Note_Text' );    #### order should agree with SDB_Status

    print
        "The following warnings may show up for a given Sequencing Run.  Most indicate that essentially no information was generated due to poor or missing trace data, or the fact that the read was identified as entirely vector... Index Warnings are more complicated and indicate an unexpected vector fragment within the 'Quality' section of the read.  This may be otherwise very good data, but should be looked at.  (a link to the exact indexing error encountered and a broader description is available from the Reads Summary Page.<p ></p>";

    my $Warnings = HTML_Table->new();

    my @Title;
    my @Desc;

    my $Note_num = 0;
    foreach my $note (@notes) {
        ( my $Note_title, my $Note_Description ) = split ',', $note;
        if ( $Note_title =~ /\w/ ) {
            push( @Title, $Note_title );
            push( @Desc,  $Note_Description );
            $Note_num++;
        }
    }

    $Warnings->Set_Title("<B>Sequencing Warnings</B>");
    my @headers = ( 'Warning', 'Explanation' );
    $Warnings->Set_Headers( \@headers );

    foreach my $index ( 1 .. $Note_num ) {
        my @fields = ( "$Title[$index-1]", "$Desc[$index-1]" );
        if ( $index == $warning ) {
            $Warnings->Set_Row( \@fields, 'lightredbw' );
        }
        else {
            $Warnings->Set_Row( \@fields );
        }
    }
    $Warnings->Printout();

    print "<HR>";

    $limit ||= 20;
    if (1) {
        my $lib = param('Library') || 'CN001';
        &index_warnings( $lib, $limit );
    }
    return 1;
}

########################

########################

########################

########################
sub OH_Module_Routines {
########################
}

return 1;

return 1;

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Help.pm,v 1.11 2004/09/08 23:31:48 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
