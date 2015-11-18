package SDB::Work_Flow;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Work_Flow.pm - This object is the superclass of alDente database objects.

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
####################
sub load {
####################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my %args       = &filter_input( \@_, -mandatory => 'file' );
    my $table      = $args{-table};
    my $file       = $args{-file};
    my $submission = $args{-submission};
    my $mode       = $args{-mode};

    require YAML;
    my $hash = YAML::LoadFile($file);

    my $main_file = $hash->{-config}{1}{file};
    my $full_file_name = $self->get_Full_Filename( -file => $main_file );

    $self->{template}     = $file;
    $self->{control_file} = $full_file_name;
    $self->{mode}         = $mode;
    $self->{config}       = $hash->{-config};
    $self->{main_field}   = $hash->{-main_field};

    my @condition_fields;
    my %config = %{ $self->{config} } if $self->{config};
    my %mf_hash;
    for my $key ( keys %config ) {
        unless ( $config{$key}{parent_field} ) {next}
        $mf_hash{ $config{$key}{parent_field} }{number}    = $key;
        $mf_hash{ $config{$key}{parent_field} }{condition} = $config{$key}{condition};
    }

    $self->{condition_fields} = \%mf_hash;

    return;
}

####################
sub get_Full_Filename {
####################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = &filter_input( \@_, -mandatory => 'file' );
    my $file = $args{-file};
    require alDente::Tools;
    my ( $path, $sub_path ) = alDente::Tools::get_standard_Path( -type => 'template', -dbc => $dbc );
    my $file_name = $path . $sub_path . 'Form/' . $file;
    return $file_name;
}

####################
sub save_Condition_Fields {
####################
    my $self  = shift;
    my $dbc   = $self->{dbc};
    my %args  = &filter_input( \@_, -mandatory => 'input' );
    my $input = $args{-input};
    unless ($input) {return}
    my %input = %$input;

    my %condition_fields = %{ $self->{condition_fields} } if $self->{condition_fields};
    for my $cfield ( keys %condition_fields ) {
        my @records;
        my %form_input = %{ $input{$cfield} } if $input{$cfield};
        for my $number ( keys %form_input ) {
            if ( $form_input{$number} ) {
                my $condition = '$form_input{$number} ' . $condition_fields{$cfield}{condition};
                if ( eval $condition ) {
                    push @records, $number;
                }
            }
            $self->{config}{ $condition_fields{$cfield}{number} }{records} = \@records;
        }
    }
    return 1;
}

##############################
# private_functions          #
##############################

return 1;
