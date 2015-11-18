package SDB::Form;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Form.pm - This object is the superclass of alDente database objects.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This object is the superclass of alDente database objects.<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;

use CGI qw(:standard);

##############################
# custom_modules_ref         #
##############################
use RGTools::Object;
use RGTools::HTML_Table;
use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Template;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

my $q = new CGI;
##############################
# constructor                #
##############################

##################
sub new {
##################
    my $this = shift;

    my %args   = @_;
    my $dbc    = $args{-dbc};
    my $frozen = $args{-frozen} || 0;    # Reference to frozen object if there is any. [Object]

    my $self = $this->Object::new( -frozen => $frozen );
    my $class = ref($this) || $this;
    bless $self, $class;
    $self->{dbc} = $dbc;                 # Database handle [ObjectRef]

    my $external;

    return $self;
}

##############################
# public_methods             #
##############################
##############################
# Config Structure:
#
#
#
#
##############################

####################
sub load {
####################
    my $self          = shift;
    my %args          = &filter_input( \@_, -mandatory => 'template_file' );
    my $table         = $args{-table};
    my $template_file = $args{-template_file};                                 ## yml file
    my $data_file     = $args{-data_file};                                     ## xml file
    my $submission_id = $args{-submission_id};

    unless ($data_file) {
        $data_file = $self->get_Data_file( -template => $template_file, -submission_id => $submission_id );
    }

    $self->load_configs( -file => $template_file );

    if ( -e $data_file ) {
        $self->load_input( -file => $data_file );
    }

    $self->load_options();

    $self->{template}      = $template_file;
    $self->{loaded}        = 1;
    $self->{submission_id} = $submission_id;
    $self->{external}      = 1;                ### temp

    return;
}

##################
#
#
#
####################
sub get_Data_file {
    my $self          = shift;
    my $dbc           = $self->{dbc};
    my %args          = &filter_input( \@_, -mandatory => 'template,submission_id' );
    my $template      = $args{-template};
    my $submission_id = $args{-submission_id};

    require SDB::Submission;
    my $path = SDB::Submission::get_Path( -sid => $submission_id, -dbc => $dbc );
    my $file_name = $self->strip_File_Name($template);

    my @files       = glob("$path/${file_name}*.xml");
    my $max_filenum = 1;

    # error check - if there are no files, return
    if ( int(@files) > 0 ) {
        foreach my $fullpath (@files) {
            my ( $dir, $file ) = &Resolve_Path($fullpath);
            my ($num) = $file =~ /sub_\d+.(\d+).xml/;
            if ( $num > $max_filenum ) {
                $max_filenum = $num;
            }
        }

        # increment max_filenum
        $max_filenum++;
    }

    my $file = "$path/${file_name}.${max_filenum}.xml";
    return $file;

}

##################
#
#
#
####################
sub strip_File_Name {
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'file' );
    my $file = $args{-file};
    $file =~ s/.+\///g;
    $file =~ s/\..+//g;
    return $file;
}

##################
#
#
#
####################
sub load_slots {
####################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $max_row = $args{-max_row};
    my $max_col = $args{-max_col};
    my $order   = $args{-order} || 'row';    ## ENUM col/row
    my %slots;
    my @chars = ( 'a' .. 'z' );

    #    if ( $self->{slots} ) {return $self->{slots}}

    my $record;
    if ( $order =~ /row/ ) {
        for my $col ( 1 .. $max_col ) {
            for my $row ( 1 .. $max_row ) {
                $record++;
                $slots{$record} = $chars[ $col - 1 ] . $row;
            }
        }
    }
    else {
        for my $row ( 1 .. $max_row ) {
            for my $col ( 1 .. $max_col ) {
                $record++;
                $slots{$record} = $chars[ $col - 1 ] . $row;
            }
        }
    }

    #    $self->{slots} = \%slots;

    return \%slots;
}

##################
#  This looks up database DBField and Attribute to setup options, header and type if not already set
#
#
####################
sub load_options {
####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->{dbc};

    my @entries = keys %{ $self->{configs} };
    my @fields;
    my @attributes;

    for my $entry (@entries) {
        if   ( $entry =~ /(.+)\_Attribute\.(.+)/i ) { push @attributes, $1 . '.' . $2 }
        else                                        { push @fields,     $entry }
    }

    my $field_list = Cast_List( -list => \@fields, -to => 'string', -autoquote => 1 );
    my %db_info = $dbc->Table_retrieve( 'DBField', [ 'Field_Table', 'Field_Name', 'Prompt', 'Field_Options', 'Field_Type', 'Field_Default' ], " WHERE  Concat(Field_Table,'.',Field_Name) IN ($field_list)" ) if $field_list;
    my $field_count = @fields;

    for my $index ( 0 .. $field_count - 1 ) {
        unless ( $db_info{Field_Name}[$index] ) {next}

        my $temp_name = $db_info{Field_Table}[$index] . '.' . $db_info{Field_Name}[$index];

        if ( $db_info{Field_Type}[$index] =~ /^enum/i ) {
            $self->{configs}{$temp_name}{type} = 'enum';
            if ( $self->{configs}{$temp_name}{limit_options} ) {
                $self->{configs}{$temp_name}{options} = $self->{configs}{$temp_name}{limit_options};
            }
            else {
                my @temp_options = $dbc->get_enum_list( $db_info{Field_Table}[$index], $db_info{Field_Name}[$index] );
                $self->{configs}{$temp_name}{options} = \@temp_options;
            }
        }
        elsif ( $db_info{Field_Type}[$index] =~ /^set/i ) {
            $self->{configs}{$temp_name}{type} = 'set';
            if ( $self->{configs}{$temp_name}{limit_options} ) {
                $self->{configs}{$temp_name}{options} = $self->{configs}{$temp_name}{limit_options};
            }
            else {
                my @temp_options = $dbc->get_enum_list( $db_info{Field_Table}[$index], $db_info{Field_Name}[$index] );
                $self->{configs}{$temp_name}{options} = \@temp_options;
            }
        }
        elsif ( $db_info{Field_Type}[$index] =~ /^datetime/i ) {
            $self->{configs}{$temp_name}{type} = 'datetime';
        }
        elsif ( $db_info{Field_Type}[$index] =~ /^date/i ) {
            $self->{configs}{$temp_name}{type} = 'date';
        }
        elsif ( $db_info{Field_Type}[$index] ) {
            if ( $db_info{Field_Options}[$index] =~ /internal/ ) {
                $self->{configs}{$temp_name}{type} = 'text';

            }
            elsif ( $db_info{Field_Name}[$index] =~ /^FK.+\_/ ) {
                if ( $db_info{Field_Options}[$index] =~ /fixed/ ) {
                    ## This means you cannot add values to lookuptable and need to select one of those options
                    $self->{configs}{$temp_name}{type} = 'fixed foreign key';
                }
                else {
                    $self->{configs}{$temp_name}{type} = 'foreign key';
                }

                if ( $self->{configs}{$temp_name}{limit_options} ) {
                    $self->{configs}{$temp_name}{options} = $self->{configs}{$temp_name}{limit_options};
                }
                else {
                    my @temp_options = $dbc->get_FK_info_list($temp_name);
                    $self->{configs}{$temp_name}{options} = \@temp_options;
                }
            }
            else {
                $self->{configs}{$temp_name}{type} = 'text';
            }
        }
        else {
            $dbc->error("Failure!!! No options for $temp_name");
        }

        unless ( $self->{configs}{$temp_name}{header} ) {
            $self->{configs}{$temp_name}{header} = $db_info{Prompt}[$index];
        }
    }

    my $attribute_list = Cast_List( -list => \@attributes, -to => 'string', -autoquote => 1 );
    my %att_info = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Access', 'Attribute_Name', 'Attribute_Format', 'Attribute_Type', 'Attribute_Class' ], " WHERE  Concat(Attribute_Class,'.',Attribute_Name) IN ($attribute_list)" ) if $attribute_list;
    my $att_count = @attributes;

    for my $index ( 0 .. $att_count - 1 ) {
        unless ( $att_info{Attribute_Name}[$index] ) {next}
        my $temp_name = $att_info{Attribute_Class}[$index] . '_Attribute.' . $att_info{Attribute_Name}[$index];
        my $att_type  = $att_info{Attribute_Type}[$index];

        unless ( $self->{configs}{$temp_name}{header} ) {
            $self->{configs}{$temp_name}{header} = $att_info{Attribute_Name}[$index];
        }

        if ( $att_type =~ /^FK/i ) {
            $self->{configs}{$temp_name}{type} = 'foreign key';
            if ( $self->{configs}{$temp_name}{limit_options} ) {
                $self->{configs}{$temp_name}{options} = $self->{configs}{$temp_name}{limit_options};
            }
            else {
                my @options = $dbc->get_FK_info_list($att_type);
                $self->{configs}{$temp_name}{options} = \@options

            }
        }
        elsif ( $att_type =~ /enum\((.+)\)/i ) {
            my $list = $1;
            $self->{configs}{$temp_name}{type} = 'enum';
            if ( $self->{configs}{$temp_name}{limit_options} ) {
                $self->{configs}{$temp_name}{options} = $self->{configs}{$temp_name}{limit_options};
            }
            else {
                my @options = Cast_List( -list => $list, -to => 'Array' );
                $self->{configs}{$temp_name}{options} = \@options;
            }
        }
        else {
            $self->{configs}{$temp_name}{type} = 'text';
        }
    }
    return 1;
}

##################
#  This looks up a xml file to set the values already set by user
#
####################
sub load_input {
####################
    my $self  = shift;
    my %args  = &filter_input( \@_, -mandatory => 'file' );
    my $table = $args{-table};
    my $file  = $args{-file};
    ### this load the submission

    # open the latest submission file
    require XML::Dumper;

    # define directories
    my $dump = new XML::Dumper();

    my $stored_ref = $dump->xml2perl($file);
    $self->{input} = $stored_ref;
    return;
}

##################
#
#
#
####################
sub load_configs {
####################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = &filter_input( \@_, -mandatory => 'table|file' );
    my $file = $args{-file};
    my $main = $args{-main};

    my $Template = new SDB::Template( -dbc => $dbc, -quiet => 1 );
    $Template->configure( -template => $file, -header => $file );

    my @input = @{ $Template->{config}{-input} } if $Template->{config}{-input};

    my @order = @{ $Template->{config}{-order} } if $Template->{config}{-order};
    my @fields;
    my %configs;

    if (@order) {
        push @fields, @order;
    }

    for my $entry (@input) {

        my %entry = %$entry if $entry;
        my ($field_name) = keys %entry;

        ########### TEMPORARY !!! ##################
        if ( $field_name =~ /tax/i ) {next}
        unless ( $field_name =~ /ident/i || $field_name =~ /Sample_Type/i || $field_name =~ /dis/i || $field_name =~ /patho/i || $field_name =~ /Nucleic_Acid/i ) {next}
        ########### TEMPORARY !!! ##################

        if ( !$entry{$field_name}{hidden} && !$entry{$field_name}{preset} && !@order ) {
            push @fields, $field_name;
        }

        $configs{$field_name}{header}        = $entry{$field_name}{header};
        $configs{$field_name}{limit_options} = $entry{$field_name}{options};
        $configs{$field_name}{mandatory}     = $entry{$field_name}{mandatory};
        $configs{$field_name}{hidden}        = $entry{$field_name}{hidden};
        $configs{$field_name}{default}       = $entry{$field_name}{preset};
    }

    my $grey;

    $self->{configs} = \%configs;
    $self->{fields}  = \@fields;
    $self->{main}    = $main;

    return 1;
}

##############################
# private_functions          #
##############################

return 1;
