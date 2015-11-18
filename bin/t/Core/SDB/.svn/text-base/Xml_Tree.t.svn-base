#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    # Example:     $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new SDB::Xml_Tree(%args);

}

############################################################
use_ok("SDB::Xml_Tree");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("SDB::Xml_Tree", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bcreate\b/ ) {
    can_ok("SDB::Xml_Tree", 'create');
    {
        ## <insert tests for create method here> ##
    }
}

if ( !$method || $method =~ /\bget_root\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_root');
    {
        ## <insert tests for get_root method here> ##
    }
}

if ( !$method || $method =~ /\bset_root\b/ ) {
    can_ok("SDB::Xml_Tree", 'set_root');
    {
        ## <insert tests for set_root method here> ##
    }
}

if ( !$method || $method =~ /\bget_current\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_current');
    {
        ## <insert tests for get_current method here> ##
    }
}

if ( !$method || $method =~ /\bset_current\b/ ) {
    can_ok("SDB::Xml_Tree", 'set_current');
    {
        ## <insert tests for set_current method here> ##
    }
}

if ( !$method || $method =~ /\bget_id\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_id');
    {
        ## <insert tests for get_id method here> ##
    }
}

if ( !$method || $method =~ /\bset_id\b/ ) {
    can_ok("SDB::Xml_Tree", 'set_id');
    {
        ## <insert tests for set_id method here> ##
    }
}

if ( !$method || $method =~ /\bget_name\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_name');
    {
        ## <insert tests for get_name method here> ##
    }
}

if ( !$method || $method =~ /\bset_name\b/ ) {
    can_ok("SDB::Xml_Tree", 'set_name');
    {
        ## <insert tests for set_name method here> ##
    }
}

if ( !$method || $method =~ /\bget_text\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_text');
    {
        ## <insert tests for get_text method here> ##
    }
}

if ( !$method || $method =~ /\bset_text\b/ ) {
    can_ok("SDB::Xml_Tree", 'set_text');
    {
        ## <insert tests for set_text method here> ##
    }
}

if ( !$method || $method =~ /\bget_attribute\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_attribute');
    {
        ## <insert tests for get_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bset_attribute\b/ ) {
    can_ok("SDB::Xml_Tree", 'set_attribute');
    {
        ## <insert tests for set_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bget_next\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_next');
    {
        ## <insert tests for get_next method here> ##
    }
}

if ( !$method || $method =~ /\bset_next\b/ ) {
    can_ok("SDB::Xml_Tree", 'set_next');
    {
        ## <insert tests for set_next method here> ##
    }
}

if ( !$method || $method =~ /\bget_first_child\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_first_child');
    {
        ## <insert tests for get_first_child method here> ##
    }
}

if ( !$method || $method =~ /\bset_first_child\b/ ) {
    can_ok("SDB::Xml_Tree", 'set_first_child');
    {
        ## <insert tests for set_first_child method here> ##
    }
}

if ( !$method || $method =~ /\bget_parent\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_parent');
    {
        ## <insert tests for get_parent method here> ##
    }
}

if ( !$method || $method =~ /\bset_parent\b/ ) {
    can_ok("SDB::Xml_Tree", 'set_parent');
    {
        ## <insert tests for set_parent method here> ##
    }
}

if ( !$method || $method =~ /\bget_xml_tag\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_xml_tag');
    {
        ## <insert tests for get_xml_tag method here> ##
    }
}

if ( !$method || $method =~ /\badd_node\b/ ) {
    can_ok("SDB::Xml_Tree", 'add_node');
    {
        ## <insert tests for add_node method here> ##
    }
}

if ( !$method || $method =~ /\breplace\b/ ) {
    can_ok("SDB::Xml_Tree", 'replace');
    {
        ## <insert tests for replace method here> ##
    }
}

if ( !$method || $method =~ /\bcopy\b/ ) {
    can_ok("SDB::Xml_Tree", 'copy');
    {
        ## <insert tests for copy method here> ##
    }
}

if ( !$method || $method =~ /\bdeep_copy\b/ ) {
    can_ok("SDB::Xml_Tree", 'deep_copy');
    {
        ## <insert tests for deep_copy method here> ##
    }
}

if ( !$method || $method =~ /\bsearch\b/ ) {
    can_ok("SDB::Xml_Tree", 'search');
    {
        ## <insert tests for search method here> ##
    }
}

if ( !$method || $method =~ /\bis_valid\b/ ) {
    can_ok("SDB::Xml_Tree", 'is_valid');
    {
        ## <insert tests for is_valid method here> ##
    }
}

if ( !$method || $method =~ /\bis_empty\b/ ) {
    can_ok("SDB::Xml_Tree", 'is_empty');
    {
        ## <insert tests for is_empty method here> ##
    }
}

if ( !$method || $method =~ /\bremove\b/ ) {
    can_ok("SDB::Xml_Tree", 'remove');
    {
        ## <insert tests for remove method here> ##
    }
}

if ( !$method || $method =~ /\bget_next_node\b/ ) {
    can_ok("SDB::Xml_Tree", 'get_next_node');
    {
        ## <insert tests for get_next_node method here> ##
    }
}

if ( !$method || $method =~ /\brender\b/ ) {
    can_ok("SDB::Xml_Tree", 'render');
    {
        ## <insert tests for render method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Xml_Tree test');

exit;
