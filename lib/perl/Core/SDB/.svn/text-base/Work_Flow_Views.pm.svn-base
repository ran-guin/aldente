###################################################################################################################################
# SDB::Work_Flow_Views.pm
#
#
#
#
###################################################################################################################################
package SDB::Work_Flow_Views;

use base LampLite::Form_Views;
use strict;
use CGI qw(:standard);

## RG Tools
use RGTools::RGIO;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## alDente modules

use vars qw( %Configs );
my $q = new CGI;

##############################
sub get_Buttons {
##############################
    my $self        = shift;
    my $dbc         = $self->{dbc};
    my %args        = filter_input( \@_, -args => 'dbc' );
    my $page_number = $args{-page};
    my $last_page   = $args{-last_page};
    my $mode        = $args{-mode};

    my $next;
    my $previous;

    if ($last_page) {
        if ( $mode =~ /draft/i ) {
            $next = $q->submit( -force => 1, -name => 'rm', -value => 'Exit', -class => 'Action', -onclick => 'return validateForm(this.form);' );
        }
        elsif ( $mode =~ /submit/i ) {
            $next = $q->submit( -force => 1, -name => 'rm', -value => 'Submit', -class => 'Action', -onclick => 'return validateForm(this.form);' );
        }
        elsif ( $mode =~ /approve/i ) {
            $next = $q->submit( -force => 1, -name => 'rm', -value => 'Approve', -class => 'Action', -onclick => 'return validateForm(this.form);' );
        }
    }
    else {
        $next = $q->submit( -force => 1, -name => 'rm', -value => 'Next', -class => 'Action', -onclick => 'return validateForm(this.form);' );
    }

    if ( $page_number > 1 ) {
        $previous = $q->submit( -force => 1, -name => 'rm', -value => 'Previous', -class => 'Action', -onclick => 'return validateForm(this.form);' );
    }

    my $section .= $previous . $next . $q->hidden( -force => 1, -name => 'current_page', -value => $page_number );
    return $section;
}

1;
