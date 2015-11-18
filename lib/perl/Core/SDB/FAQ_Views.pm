###################################################################################################################################
# SDB::FAQ_Views.pm
#
# View in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::FAQ_Views;

use base LampLite::Views;
use strict;
use SDB::FAQ;

my $q = new LampLite::CGI;

use RGTools::RGIO;   ## include standard tools
use SDB::HTML;
use LampLite::Bootstrap;

my $BS = new Bootstrap;

################
sub show_FAQs {
################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my $category = $args{-category};
    my $question = $args{-question};
    
    my $dbc = $self->dbc();
    
    if (! $dbc->table_loaded('FAQ')) { return "No FAQs defined within this database" }
    
    my $condition = 1;
    if ($category) { $condition .= " AND FAQ_Category = '$category'"}
    if ($question) { $condition .= " AND Question = '$question'"}
    
    $condition .= " ORDER BY FAQ_Category";
    
    my @fields = ('FAQ_Category', 'Question', 'Answer');
    my $hash = $dbc->hash(-table=>'FAQ', -fields=>\@fields, -condition=>$condition);

    my $block = section_heading('FAQs');
    
    my @modals;
    
    my $i = 0;
    my $last_category = '';
    while (defined $hash->{Question}[$i]) {
        my $c = $hash->{FAQ_Category}[$i] || '';
        my $q = $hash->{Question}[$i];
        my $a = $hash->{Answer}[$i];
        
        $a =~s/\n/<P>/g;
        
        my $title = "$c FAQs";        
        
        if ($last_category && $c ne $last_category) {
            $block .= subsection_heading("$last_category FAQs");
            $block .= Cast_List(-list=>\@modals, -to=>'ul');
            @modals = ( $BS->modal(-title=>$title, -body=>$a, -label=>"<B>$q</B>" ) );
        }
        else { push @modals, $BS->modal(-title=>$title, -body=>$a, -label=>"<B>$q</B>") }
        
        $last_category = $c;
        $i++;
    }

    if (@modals) {
        $block .= subsection_heading("$last_category FAQs");
        $block .= Cast_List(-list=>\@modals, -to=>'ul');
    }
    
    return $block;
}

1;


