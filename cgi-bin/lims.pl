#!/usr/local/bin/perl

use strict;
use warnings;

use FindBin;

print "Content-type: text/html\n\n";

use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";

use LampLite::Bootstrap;
my $BS = new Bootstrap();

##############
my $mode = 'DEV';

print "\n<!-- CSS Files -->\n";
print "<HEAD>\n";

my $root = "/SDB_rg";

print load_file("$root/css/bootstrap.min.css",1);
print load_file("$root/css/custom_bootstrap.css",1);

print "\n<!-- JS Files -->\n";
# print load_file("$root/js/jquery.v2.0.3.min.js",1);
print load_file("$root/js/jquery-1.11.2.min.js",1);

print "<script src='$root/js/bootstrap.min.js'><\/script>\n"; 

print load_file("$root/js/custom_bootstrap.js",1);

print "</HEAD>\n";

print $BS->open();


## Show top-positioned fixed header ... ##
my $name = "<center><B>A</B>utomated <B>L</B>aboratory <B>D</B>ata <B>E</B>ntry <B>N</B>' <B>T</B>racking <B>E</B>nvironment</center>";
$name = "<div style='text-align:center; padding-top:30px; padding-left:20px'>$name</div>";

my $contact = qq(

Email: <A href='mailto:info\@cosinesystems.org' style='padding-right:20px'>info\@cosinesystems.org</A> 

Phone: 604-877-6000 x5403 (Ran Guin)

If you are interested in finding out more about how we may be able to help your organization, feel free to contact us to discuss options.

If you are interested in getting involved, feel free to drop us a line and let us know what it is that you are most passionate about and how you would like to contribute.
);

print "<meta name='viewport' content='width=device-width, initial-scale=1.0'>\n";


my $header = qq(<div class='col-md-6'><IMG SRC='$root/images/png/alDente_brand.png' style='padding-left:15px; width:250px;'></IMG></div>\n);
$header .= "<div class='col-md-6'>$name</div>\n<P>";

print $header;

my $about_us;

$about_us .=<<ABOUTUS;
We are a group of software developers and engineers dedicated tot he creative design & implementation of free or low cost web applications.

Our design principles and goals reflect our firm belief in:
<UL>
<LI> Agile Development Model
<LI> Open Source Development Model
<LI> Collaboration / Cooperation
<LI> Maximum Functionality at Minimum Cost
<LI> Using technology to serve the community at large
</UL>

We are most interested (but not limited) to working for projects related to:
<UL>
<LI> Public Research
<LI> Environment
<LI> Education
<LI> Health
</UL>

ABOUTUS

$about_us = paragraph($about_us);

my $aldente = qq(
alDente was originally developed in-house for a world renowned cancer research lab to meet demanding needs for functionality and responsiveness that even extremely large expensive sytems were unable to deliver.  

It is a fully functional and powerful LIMS that has been tracking high throughput genomics data for over a decade.  

Regularly evolving to meet the ongoing challenges of a dynamic lab environment and adding functionality to maximize the efficiency of the lab, it has recently been upgraded to utilize some of the latest web standards for mobile applications making it highly versatile and expandable depending upon the needs of the user. 
);
    
my $barcode = "<h3>Navigational Aid</h3>"
. paragraph(qq(
Barcoding items in the lab greatly simplifies system navigation since for many activities, the action which the technician wishes to perform can be inferred simply from what it is they have scanned.  At the very least, it narrows the scope of possibilities to simplify navigation through the system.

For example, by scanning a set of tubes along with a target box, the system is able to guess that the use wishes to track the storage of these tubes in the designated box.  They are then prompted to confirm and complete this tracking process with the click of a button.  There is no need to find either the sample or the box, or to learn how to navigate through the system to perform such an action.

Similar shortcuts are available for many of the most common lab tasks.  If a user scans a set of samples alone, then there are many other options available, but they are presented with a content specific screen which makes ongoing navigation easier.
In this case, for example, they may have the option to:
<UL>
<LI>view detailed information about the samples they scanned, 
<LI>aliquot / transfer / extract sample from the scanned list of tubes/plates
<LI>save the set of samples that they have scanned and initiate a lab protocol
<LI>edit data associated with the samples scanned
<LI>regenerate barcodes for the samples scanned
</UL>

<h3>Reduced Data Entry Errors</h3>
Using barcode-labeled objects not only simplifies navigation, but more importantly it significantly reduces the chance of user error.  It is very easy for a user to mistype an id in a textfield, or to choose the wrong item from a dropdown list, however scanning a barcode is a virtually foolproof way of identifying the objects in the lab that are being used.  This is a crucial part of maintaining the integrity of the data that is maintained.
));

my $barcode_images = ''; #$BS->carousel(
#        -images => ["$root/images/png/gelpour_barcode_1D.png", "$root/images/png/ge_tube_barcode_2D.png", "$root/images/png/run_barcode_1D.png"],
#        -captions => ['Standard Barcodes', 'Small barcodes for sample trays', '2D barcodes'],
#    );

my @layers;
push @layers, { 
    'label' => 'Barcode Tracking', 
    'content' =>  $barcode . $barcode_images,
};

my $tracking = paragraph(qq(
One of the primary purposes of the LIMS is to track samples within the lab.  The nature of the samples may vary significantly from lab to lab, but certain functionality expectations are shared across a myriad of environments.

<h3>Sample Transfer / Extraction</h3>
Whether dealing with biological samples, chemical samples, or even mineral samples there is generally a need to transfer a portion of the original sample into a separate container - whether to simply store copies of the original, or to perform separate tests, the separated sample, while still a copy of the same original, needs to be tracked distinctly from its source.

There is also the option at this stage to classify the transfer as an extraction, in which the nature of the extracted material may vary from the original.  Examples of this may include:
<UL>
 <LI>Extracting red blood cells from whole blood</LI>
 <LI>Extracting RNA from DNA</LI>
 <LI>Extracting the distillate from a solution</LI>
 <LI>Extracting a resin sample from a piece of wood</LI> 
</UL>

<h3>Handling of samples by Equipment</h3>
Typically samples will be handled within a lab by pieces of equipment which may alter the sample in some way or extract data.  (eg Centrifuge, Sequencer, Mass Spectrometer)
Tracking which piece of equipment is used at each steps enables a detailed audit trail of sample handling, and if applicable, it enables downstream data to be retrieved and associated back to the samples being used.
(Using barcode navigation, this is initiated by simply scanning the applicable samples along with the equipment being used)

<h3>Application of Reagents to Samples</h3>
Typically reagents may be applied to samples during various phases of the sample handling.  Again, it is important to keep track of exactly which reagents were applied, when, and by whom.
(Using barcode navigation, this is initiated by simply scanning the applicable samples along with the reagent being used)

<h3>Location Tracking</h3>
It is often crucial to maintain detailed records of where samples are located, and a history of their movement.  This includes movement within the lab between freezers or storage sites as well as shipping details for samples that are received or exported from external collaborators.
(see section below for more details on Location Tracking)

<h3>Protocol Tracking</h3>
Very often standardized procedures will be established for handling samples, which may include a defined set of steps which lab staff should follow in handling multiple samples at one time.  Customized Lab protocols can be set up in this way to prompt users in a step by step fashion through these protocols, allowing for various input at each step.  Protocols may include a number of complex tasks including sample splitting, pooling, extraction (which automatically generate new sample barcodes).  Users can also supply custom input attributes to associate with samples at various steps in the protocol.

By separating protocols into carefully defined steps, it is easy to follow and track protocols easily using mobile devices for data entry using a very simple user interface. 
(see section below for more details on Protocol Tracking)

));

my $tracking_images = '';
#$BS->carousel(
#        -images => ["$root/images/png/barcode.png", "$root/images/png/barcode1.png", "$root/images/png/barcode2.png"],
#        -captions => ['Standard Barcodes', 'Small barcodes for sample trays', '2D barcodes'],
#    );

push @layers, { 
    'label' => 'Sample Tracking', 
    'content' =>  $tracking . $tracking_images,
};


my $protocols = paragraph(qq(
Administrators can define a detailed list of steps used for handling samples and save this as a lab protocol.  Any number of lab protocols can be defined and available for use by samples of different types.

Once defined and a user chooses a protocol to follow, they are prompted to follow a list of pre-defined steps, during which they may:<UL>
<LI>aliquot/extract/pool/split existing samples - generating new barcoded items</LI>
<LI>apply reagents</LI>
<LI>apply equipment</LI>
<LI>set sample attributes</LI>
<LI>store samples</LI>
</UL>
Included in the protocol tracking are also a variety of validation options to prevent users from applying data incorrectly
</LI>

Protocols can be followed in real time to maximize error reduction by making use of built in validation processes.
In some cases, it is more expedient for users to track the procedures done after the fact, in which case they can track the protocol execution in its entirety by simply selecting the steps performed and entering any required information in a single form.
));

my $protocol_images = $BS->carousel(
        -images => ["$root/images/help_images/plate_set_home_page.png", "$root/images/help_images/protocol_step.png"],
        -captions => ['Initiate by scanning set of samples', 'Follow pre-defined steps within protocol'],
    );

push @layers, { 
    'label' => 'Protocol Tracking', 
    'content' =>  $protocols . $protocol_images,
};


my $location = paragraph(qq(
Detailed tracking of location down to the slot level is easily accomplished using barcode labels.  Moving a group of samples is accomplished by simply scanning either a box or set of samples along with a target location barcode.

Detailed shipment tracking is also included which enables users to monitor detailed accounts of shipped samples along with detailed manifests.  This also makes inventory management very easy since freezer or shelf contents are readily available for monitoring.
));

my $location_images = $BS->carousel(
        -images => ["$root/images/help_images/Shipping_Manifest.png", "$root/images/help_images/Receive_Shipment.png",],
        -captions => ['Easily export samples and generate Shipment Manifest Reports', 'Track incoming shipments, and attach to uploaded data files'],
    );

push @layers, { 
    'label' => 'Location Tracking', 
    'content' =>  $location . $location_images,
};

my $reagents =  paragraph(qq(
Reagents and other stock items are tracked, allowing detailed stock inventory to be maintained.

Users can schedule and track equipment maintenance.

Lab administrators can define fairly complex standard formulas which can be automatically scaled to a target volume or target number of samples and used to automatically create recipes for regularly used solutions.
));

my $reagent_images = $BS->carousel(
        -images => ["$root/images/help_images/mobile_ss.png", "$root/images/help_images/mobile_prepare_ss copy.png"],
        -captions => ['Select Standardized Reagents', 'Volumes calculated automatically based upon predetermined formulae'],
    );

push @layers, { 
    'label' => 'Reagent Tracking', 
    'content' =>  $reagents . $reagent_images,
};

my $experiment = paragraph(qq(
Raw data generated from laboratory equipment is also easily integrated with the system and included for viewing and progress monitoring.

This is an advanced feature and requires some setup to customize how this data may be viewed and initialized, but the framework is in place to do this relatively easily.

The system is set up to spawn analysis and data acquisition scripts as required, though individual labs need to ensure such working scripts are available.
));

my $experiment_images = ''; #$BS->carousel(
 #       -images => [],
 #       -captions => ['Standard Barcodes', 'Small barcodes for sample trays', '2D barcodes'],
 #   );

push @layers, { 
    'label' => 'Experiment Tracking', 
    'content' =>  $experiment . $experiment_images,
};

my $mobile = paragraph(qq(
The system is also designed to be easily run on a mobile device enabling standard procedures to be accomplished in real time using a small mobile device to track lab protocols, move samples around, or create of standard laboratory solutions.
));

my $mobile_images = $BS->carousel(
        -images => [ "$root/images/help_images/mobile_home_search copy.png", "$root/images/help_images/mobile_prepare_ss copy.png",  "$root/images/help_images/protocol_step.png"],
        -captions => ['Simple mobile interface to scan barcodes / submit errors / search database', 'Prepare reagents according to pre-defined formula', 'Follow pre-defined lab protocols'],
    );

push @layers, { 
    'label' => 'Mobile Friendly', 
    'content' =>  $mobile . $mobile_images,
};

my $other =  paragraph(qq(
A number of other features provide valuable functionality to the alDente LIMS including:
<UL>
<LI><B>Controlled Vocabulary</B> for fields & attributes.  This means that most fields / attributes utilize dropdown menus for options rather than providing pure text.  Where appropriate new entry values may be added (based upon user permissions), but this is strongly encourages data standardization which is extremely benificial for both data sharing and data mining.
<LI><B>Automated monitoring</B>
A number of automated process are also accomplished regularly.  These include a wide variety of cases:
     <UL>
     <LI>basic system monitoring scripts to monitor the status of the backup systems.</LI>
     <LI>integrity checking scripts to look for standard or customized data which may require investigation.</LI>
     <LI>Sending out reminders to lab staff when reagents are set to expire.</LI>
     <LI>Sending out regular customized reports</LI>
     </UL>
    </LI>
    <LI><B>Access to customizable data upload templates</B></LI>
    <LI><B>Easily customizable views that can be made readily available to LIMS users</B></LI>
<UL>
));

my $other_images = ''; #$BS->carousel(
 #       -images => ["$root/images/png/barcode.png", "$root/images/png/barcode1.png", "$root/images/png/barcode2.png"],
 #       -captions => ['Standard Barcodes', 'Small barcodes for sample trays', '2D barcodes'],
 #   );

push @layers, { 
    'label' => 'Other Features', 
    'content' =>  $other . $other_images,
};

$aldente = table($aldente);
$aldente .= $BS->accordion(-layers=>\@layers);


my $links = qq(
<A href="http://cosinesystems.org/cgi-bin/cosine.pl">  
<B>C</B>ommunity <B>O</B>riented <B>S</B>oftware <B>I</B>nnovation <B>Ne</B>twork
</A>

<P>This is a network of professionals dedicated to the creative design & implementation of free or low cost web applications.</P>

    <A href="http://cosinesystems.org/cgi-bin/stash.pl">  
    Data STASH</B> - <B>Data S</B>et <B>T</B>racking, <B>A</B>ccess & <B>S</B>torage <B>H</B>ub
    </A>
);

$links .= Cast_List(-list=>[
'Develop data resources across a broad range of users & stakeholders in a wide variety of contexts',
'Develop robust & reusable tools to amalgamate and visualize large data sets',
'Working with users & stakeholders to establish controlled vocabulary & standardized data elements',
'Use standardized data to ease sharing & mining of data',
'Encourage transparency and accessibility of public information',
'Encourage accountability and auditability of data sets',
], -to=>'UL');

my $layers = [
{ 'label' => 'About Us',  'content' => table($about_us) },
{ 'label' => 'alDente', 'content' => $aldente },
{ 'label' => 'Other Projects', 'content' => $links },
{ 'label' => 'Contact Us', 'content' => table($contact)},
];

print "<div class = 'col-md-12'>\n";

print $BS->layer($layers, -layer_type=>'menu', -active=>'alDente', -style=>'background-color:#ddd; ');

print "</div> <!-- end of layer section -->\n";

print "</body>\n";
print "</html>\n";

exit;

###########
sub table {
###########
    my $content = shift;
    
    my $table = "<Table><TR><TD style='padding:30px; '>";
    $table .= paragraph($content);
    $table .= "</TD></TR></Table>\n";
    
    return $table;
    
}
################
sub paragraph {
################
    my $content = shift;
    $content =~s/\n/<BR>/g;

    return "\n<P>\n$content\n</P>\n";
}

######################
sub section {
######################
    my $heading = shift;
    my $level = shift || 2;
   
    return "<h$level>$heading</h$level>\n";
}

######################
sub subsection {
######################
    my $heading = shift;
    my $level = shift || 3;
    my $add = shift;
    
    return section($heading, $level, $add);
}

################
sub Cast_List {
################
    my %args = @_;
    my $list = $args{-list};
    my $to = $args{-to};
    
    my $block = "<UL>\n";
    foreach my $item (@$list) {
        $block .= "\t<LI>$item</LI>\n";
    }
    $block .= "</UL>";

    return $block;
}

################
sub load_file {
################
    my $file = shift;
    my $link = shift;

    my $block = "\n";

    ## deterimine file type ##
    my $type; 
    if ($file =~/\.js$/) { $type = 'js' }
    else { $type = 'css' }

    ### load link if applicable ##
    if ($link) { 
        if ($type eq 'js') { 
            $block .= "<script src='$file'></script>\n";
        }
        else {
            $block .= "<LINK rel='stylesheet' type='text/css' href='$file'>\n";
        }
        return $block;
    }

    if ($type eq 'js') {
        $block .= "<!-- JS File $file -->\n";
        $block .= "<script>";
    }
    else {
        $block .= "<!-- CSS File $file -->\n";
        $block .= "<style>";
        
    }
    
    $block .= `cat $file`;
    
    if ($type eq 'js') { $block .= "</script>\n"; }
    else { $block .= "</style>\n" }
    
    return $block;
    
}

