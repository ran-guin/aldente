###############################################################################
# Barcoding.pm
#
# This module supports Standard Barcoding
#
#
################################################################################
package LampLite::Barcode;

use base RGTools::Barcode;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Barcoding.pm - These methods provide some basic functionality for barcoding options

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

Assumptions:

User settings defined:

PRINTER_GROUP

Database Tables installed:

Printer
Printer_Group
Printer_Assignment

=cut

##############################
# superclasses               #
##############################

use strict;

use RGTools::RGIO;
use Barcode::Code128;

####################
sub get_printer {
####################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $label_name  = $args{-label_type};                                                              ## type of label (name of specific label - from barcodes.dat file)
    my $skip_prompt = $args{-skip_prompt};
    my $debug       = $args{-debug};

    if ( $dbc->session->user_setting('PRINTER_GROUP') =~ /Disabled$/i ) {
        return ( 'Disabled', '' );
    }
    elsif ( $dbc->table_populated('Printer') ) {
        return ( 'Disabled', '' );
    }

    # First see if the label type is defined in the database and if so find the corresponding setting
    my ($label_format) = $dbc->Table_find( 'Barcode_Label,Label_Format', 'Label_Format_Name', "WHERE FK_Label_Format__ID=Label_Format_ID AND Barcode_Label_Name='$label_name'", -debug => $debug );

    my $printer = $dbc->session->user_setting($label_format) if ($label_format);                                          #$Sess->{printers}{$label_format};
    my $printer_id;

    if ($printer) {
        ($printer_id) = $dbc->Table_find( 'Printer', 'Printer_ID', "WHERE Printer_Name='$printer'", -debug => $debug );
    }
    else {
        my $printer_group_id;
        my $attribute     = 'printer_group_id';
        my $printer_group = $dbc->session->user_setting('PRINTER_GROUP');

        if ( $printer_group =~ /Disabled$/ ) { return ( 'Disabled', '' ) }

        if ( defined $dbc->session->{$attribute} ) { $printer_group_id = $dbc->session->{printer_group_id}; }
        else {
            if ($skip_prompt) {
                return;
            }
            else {
                return "Please set PRINTER_GROUP (under construction)";
#                my $cgi_app = new alDente::CGI_App( PARAMS => { dbc => $dbc } );
#                $cgi_app->update_session_info();
#                return $cgi_app->prompt_for_session_info($attribute);
            }
        }

        if ($printer_group_id) {
            my ( $assignedprinter, $assignedprinter_ID );
            my ($assignedprinterinfo) = $dbc->Table_find(
                'Printer,Printer_Assignment,Printer_Group,Label_Format,Barcode_Label',
                'Printer_Name,Printer_ID',
                "WHERE Printer_Assignment.FK_Printer__ID = Printer_ID AND Printer_Assignment.FK_Label_Format__ID = Label_Format_ID AND Label_Format_ID = Barcode_Label.FK_Label_Format__ID AND Barcode_Label_Name = '$label_name' AND Printer_Assignment.FK_Printer_Group__ID = '$printer_group_id'",
                -distinct => 1,
                -debug    => $debug
            );

            ( $assignedprinter, $assignedprinter_ID ) = split ',', $assignedprinterinfo;
            ( $printer, $printer_id ) = ( $assignedprinter, $assignedprinter_ID );
        }
        else { Message("No printer group assigned"); return; }
    }

    return ( $printer, $printer_id );
}

########################
sub get_printer_DPI {
########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $printer     = $args{-printer};
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $default_DPI = 200;

    # get the location of the printer
    if ($printer) {
        my ($res) = $dbc->Table_find( "Printer", "Printer_DPI", "WHERE Printer_Name='$printer'" );
        return $res;
    }
    else {
        return $default_DPI;
    }
}

#################################
# generate Code128 barcode image
#################################
sub generate_barcode_image {
#################################
    my $self = shift;
    my %args = filter_input(\@_);
    my $file   = $args{-file};            # (Scalar) Fully-qualified filename of the image to be generated
    my $value  = $args{-value};           # (Scalar) Value of the barcode
    my $scale  = $args{-scale} || 1;      # (Scalar)[Optional] The scale of the image. Default is 1.
    my $height = $args{-height} || 40;    # (Scalar)[Optional] The height of the image. Default is 30.

    my $object = new Barcode::Code128;
    $object->option( "scale",  $scale );
    $object->option( "height", $height );

    # Generate the barcode
    open( PNG, ">$file" ) or die "Can't write $file: $!\n";
    binmode(PNG);

    print PNG $object->png("$value");
    close(PNG);

    return $file;
}


#
# Return simple image of barcode
##
#####################
sub barcode_img {
#####################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'barcode');
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $barcode = $args{-barcode};
    my $class   = $args{-class} || $self->_get_value( 'class' );
    my $id      = $args{-id} || $self->_get_value( 'id' );

    my $link = 1;

    my $alias;
    my $img = "$class.$id." . timestamp() . '.png';

    my $page;
    if ( $class && $id ) {
        $self->generate_barcode_image( -file => $dbc->config('URL_temp_dir') . "/$img", -value => "$class$id" );
        $page = "$alias<BR><img src='/dynamic/tmp/$img'>";

        if ($link) {
            $page = Link_To( $dbc->config('homelink'), $page, "&Homepage=$class&ID=$id" );
        }
    }
    else {
        # $page = "class ($class) or id ($id) unidentified";
        # print $class, $id, HTML_Dump $barcode->{fields};
    }
    return $page;
}

##############################
sub reset_Printer_Group {
##############################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc         = $args{-dbc} || $self->{dbc};

    my $printer_group_id   = $args{-id};
    my $printer_group_name = $args{-name};
    my $scope              = $args{-scope};
    my $quiet              = $args{-quiet};
    my $User               = $args{-User};

    if ( !$printer_group_id && $dbc->session ) {
        $printer_group_id = $dbc->session->{printer_group_id};
    }
    
    my $set = 0;
    if ( defined $dbc->session ) {
        my $condition;
        if ($printer_group_id) {
            ($printer_group_name) = $dbc->Table_find( 'Printer_Group', 'Printer_Group_Name', "WHERE Printer_Group_ID = '$printer_group_id'" );
        }
        elsif ($printer_group_name) {
            ($printer_group_id) = $dbc->Table_find( 'Printer_Group', 'Printer_Group_ID', "WHERE Printer_Group_Name = '$printer_group_name'" );
        }

        $dbc->session->set( 'printer_group'    => $printer_group_name );
        $dbc->session->set( 'printer_group_id' => $printer_group_id );

        my ($site) = $dbc->Table_find( 'Printer_Group', 'FK_Site__ID', "WHERE Printer_Group_ID = '$printer_group_id'", -debug => 0 );
        my $site_name = $dbc->get_FK_info( 'FK_Site__ID', $site );

        #	$dbc->session->set(site => $site);
        $dbc->session->set( 'site_id'   => $site );
        $dbc->session->set( 'site_name' => $site_name );

        my %Printers;

        my $user = $dbc->config('user');
        if ( $printer_group_name =~ /Disabled/i) {
            ## skip printer assignment
#            if ( $user && $user ne 'Guest') { $dbc->warning("Printers Disabled") }   ## include printer group in header ... 
            $set = 1;
        }
        else {
            my $printer_group = $dbc->hash(
                'Printer_Group,Printer_Assignment,Printer', 
                [ 'Printer_Name', 'Printer_Type' ], 
                "WHERE FK_Printer_Group__ID = Printer_Group_ID and FK_Printer__ID=Printer_ID AND Printer_Group_ID = '$printer_group_id'",
            );
            
            if ( defined $printer_group->{'Printer_Name'}[0] && $site ) {

                #                $dbc->message("Retrieving Printer Group '$printer_group_name'");
                ## set printers hash to indicate printers to use ###
                my $index = 0;
                my @printers_set;
                while ( defined $printer_group->{'Printer_Type'}[$index] ) {
                    my $printer_type = $printer_group->{'Printer_Type'}[$index];
                    my $printer      = $printer_group->{'Printer_Name'}[$index];
                    $Printers{$printer_type} = $printer;
                    push @printers_set, "$printer_type -> $printer";
                    $dbc->session->user_setting( $printer_type, $printer );
                    $index++;
                }
                my $message = "Reset Printers for $site_name ($printer_group_name): " . Cast_List(-list=>\@printers_set, -to=>'UL');
                if (!$quiet) { $dbc->message( $message ) }                
            }
            else {
                $dbc->warning("Printers not defined for Printer Group '$printer_group_name'");
                return;
            }
        }

        $dbc->session->param( 'printer_group',    $printer_group_name, );
        $dbc->session->param( 'printer_group_id', $printer_group_id );
        $dbc->session->user_setting( 'PRINTER_GROUP', $printer_group_name );

        $User ||= new LampLite::User( -id => $dbc->get_local('user_id'), -dbc => $dbc );
        $User->save_Setting( -setting => 'printer_group', -value => $printer_group_name, -scope => $scope );

        $set = 1;

    }
    return $set;
}

########################################
#
#  Wrapper method for lprprint(), checks $URL_version to determine wheter to print or not
#
#
####################
sub print {
####################
    my $self = shift;
    my %args        = &filter_input( \@_, -args => 'bc,dpi' );
    my $label_name  = $self->get_attribute('type');                                                 ## <construction> - poor name ...
    my $printer     = $args{-printer};
    my $dpi         = $args{-dpi};
    my $noscale     = $args{-noscale};
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $skip_prompt = $args{-skip_prompt};
    my $filename    = $args{-filename};

    my $printer_id;


    my $mode = $dbc->mode();
    my $printing_off_message;
    if ( $mode !~ /production/i || !$dbc->session->printer_status() ) {    ## allow generic printing from test modes ## ( $dbc->test_mode() ) {
        $printing_off_message = " [Mode: <B>$mode</B>; DB: <B>$dbc->{dbase}</B>; printer_status: <B>" . $dbc->session->printer_status() . '</B>]';
    }
    
    my $field;
    foreach $field ( keys %{ $self->{fields} } ) {
        my $barcode_type  = $self->{fields}->{$field}->{"style"};
        my $barcode_value = $self->{fields}->{$field}->{"value"};

        if ( ( lc($barcode_type) eq "code128" || lc($barcode_type) eq "datamatrix" ) && ( $barcode_value eq '' ) ) {
            delete $self->{fields}->{$field};
            $dbc->message("Empty barcode detected. This label will skip the barcode portion.");
        }
    }

    if ( $label_name && !$printer ) {
        ( $printer, $printer_id ) = $self->get_printer( -dbc => $dbc, -label_type => $label_name, -label_height => $self->get_attribute('height'), -skip_prompt => $skip_prompt );
    }
    elsif ($printer) {
        $printer_id = $dbc->get_FK_ID( 'FK_Printer__ID', $printer );
    }

    if ( $printer =~ /Disabled$/ ) { $dbc->warning("Printing Disabled - $printing_off_message"); return; }

    unless ($printer_id) {
        if ( not defined $skip_prompt ) {
            if ($label_name !~/no_barcode/) { $dbc->warning("Could not identify $printer printer for $label_name label.") }
        }
        return 0;
    }

    my ($loc) = $dbc->Table_find_array( "Printer,Equipment,Location,Site", ["Concat(Location_Name, ' [', Site_Name, ']')"], "WHERE FK_Equipment__ID=Equipment_ID AND FK_Location__ID=Location_ID AND FK_Site__ID=Site_ID AND Printer_ID = $printer_id" );
    my ($output)       = $dbc->Table_find( "Printer", "Printer_Output", "WHERE Printer_ID = $printer_id" );
    my ($printer_name) = $dbc->Table_find( "Printer", "Printer_Name",   "WHERE Printer_ID=$printer_id" );

    if ( $dbc->get_local('user_name') eq 'Admin' ) {
        my $class = $self->_get_value( 'class' );
        my $id    = $self->_get_value( 'id' );

        my $barcode_img = $self->barcode_img( -class => $class, -id => $id );
        my $png = $filename || "$class.$id." . timestamp . 'png';

        $self->makepng( '', $dbc->config('URL_temp_dir') . "/$png" );

        $barcode_img .= hspace(5);
        $barcode_img .= "<IMG SRC=/dynamic/tmp/$png />";

        print create_tree( -tree => { 'Barcode Label' => $barcode_img } );
    }

    if ( $output =~ /off/i ) { $dbc->warning("Printing is turned off on $printer"); return 0; }

    if ($dbc->mobile()) {
        if ( defined $self->{fields}{barcode} ) {
            $dbc->message("Printed barcode for $self->{fields}{barcode}{value} set to printer $printer_name : '$loc'");
        }
        else {
            $dbc->message("Printed label for $self->{comment} : '$loc'");
        }
    }
    else {
        my $message = "$label_name label(s) sent to $printer_name : '$loc'";
        if ( defined $self->{fields}{barcode} ) {
#            $message = "[$self->{fields}{barcode}{value}] $message";   ## this results in multiple messages for multipe labels (turn off to make messaging more concise)
        }
        $dbc->message("$message $printing_off_message");
    }

    if ( $self->_get_value( 'id' ) ) {
        ## if barcodes are included (ie not just a text label) ##
        if ( $printing_off_message ) { 
             return 0;
        }
        else {
            $dpi ||= $self->get_printer_DPI( -dbc => $dbc, -printer => $printer_name );

            if ( $self->lprprint( -noscale => $noscale, -verbose => !$dbc->mobile(), -printer => $printer_name, -printer_DPI => $dpi ) ) {    ### can't tie message generated if problem...
                ## ok ##
            }
            else {
                $dbc->message("Error printing ($label_name) to $printer_name, please report an issue");
            }
            return 1;
        }
    }
    else {
        $dpi ||= $self->get_printer_DPI( -dbc => $dbc, -printer => $printer_name );

        if ( $self->lprprint( -noscale => $noscale, -verbose => !$dbc->mobile(), -printer => $printer_name, -printer_DPI => $dpi ) ) {        ### can't tie message generated if problem...
            ## ok ##
        }
        else {
            $dbc->message("Error printing ($label_name) to $printer_name, please report an issue");
        }
        return 1;
    }
}

#######################
sub reprint_option {
#######################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'table,id,type' );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $table       = $args{-table};
    my $id          = $args{-id};
    my $type        = $args{-type};
    my $return_html = $args{-return_html};

    my $barcode_option = $dbc->get_db_value(-table=>'Barcode_Label', -field=>'Count(*)', -condition => "Barcode_Label_Type like '$table'");
    if (!$barcode_option) { return }

    my $html;
    if ( $table && $id ) {
        my $reprint_table = $table;
        if ( $table eq 'Plate' ) { $reprint_table = 'Container' }

        require LampLite::CGI;
        require LampLite::HTML;
        my $q = new CGI;
        my $Form = new LampLite::Form(-dbc=>$dbc);
        my $hidden = $q->hidden( -name => "$table ID", -value => $id, -force => 1 )
            . $q->hidden( -name => $table . "_ID", -value => $id, -force => 1 );
        
        my $choose;
        if ($type) { 
            # get applicable barcode label types
            my @valid_labels = $dbc->Table_find( "Barcode_Label", "Label_Descriptive_Name", "WHERE Barcode_Label_Type like '$type' AND Barcode_Label_Status='Active'" );
            if (int(@valid_labels) == 1) {
                $choose = $valid_labels[0];
                $hidden .= $q->hidden(-name=>'Barcode Name', -value=> $choose);
            }
            else {
                unshift( @valid_labels, '-- Select Type --' );            
                $choose = $q->popup_menu( -name => "Barcode Name", -values => \@valid_labels );
            }
            $hidden .= LampLite::HTML::set_validator(-name=>'Barcode Name', -mandatory=>1);
        }
        
        $Form->append( $q->submit( -name => 'Barcode_Event', -value => "Re-Print $reprint_table Barcode", -class => "Std btn", -onclick=>'return validateForm(this.form);' ), $choose );
        
        $html = $Form->generate(-include=>$hidden, -wrap=>1);
        
        if ( !$return_html ) {
            print $html;
        }
    }
    if ($return_html) { return $html }
    
    return 1;
}


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

$Id: Barcoding.pm,v 1.96 2004/12/01 18:28:54 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
