################################################################################
#
# Xml_Tree.pm
#
# This module implements a XML tree as a linked tree.
# The tree is implemented in an array. 
# The tree has one root node.
# Each node has the following structure:
# {
#	'id'	=> node id, 
#	'name'	=> name of the node, e.g. 'SAMPLE_SET.SAMPLE.alias'
#	'text'	=> string of text of the corresponding xml element,
#	'attribute'	=> hash reference of the attributes of the corresponding xml element,
#	'parent'	=> parent node id, -1 if no parent, e.g. the root.
#	'first_child'	=> id of its first child, -1 if no children
#	'next'	=>	id of the next node in the same level, -1 if no next node in the same level
# }
################################################################################

package SDB::Xml_Tree;

##############################
# superclasses               #
##############################
@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
);
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;
use XML::Parser;
use XML::Writer;

##############################
# constructor                #
##############################
sub new {
    #
    # Constructor of the object
    #
    my $this	= shift;
    my $class	= ref( $this ) || $this;
    my %args	= @_;
    my $file	= $args{-file};
    
    my $self = {};
    bless( $self, $class );

    my $tree	= [];
    if( $file ) {
		$tree = $self->create( -file=>$file );
    }
    
    $self->{tree}	 = $tree;
    $self->{root}    = ( @$tree ) ? 0 : -1;
    $self->{current} = $self->{root};

    return $self;
}

##########################################################
# This method is to create a XML tree from the template xml file  
#
# input: 
#		-file => xml template file name
#
# output: 
#		array reference to the xml tree
#
# example: 
#		my $tree = $Xml_Tree->create( -file=>$filename );
#
############################
sub create {
    my $self	= shift;
    my %args	= @_;
    my $file	= $args{-file};

	
	my $handlers = Xml_Handler->new();
    # initialize the XML::Parser with references to handler routines
    #
=begin
    my $parser = XML::Parser->new( 
    					Handlers => {
        					Start =>   \&handle_elem_start,
        					End => \&handle_elem_end,
	    					Char =>    \&handle_char_data
    					} 
    );
=cut
    my $parser = XML::Parser->new( 
    					Handlers => {
        					Start =>   sub {$handlers->handle_elem_start(@_)},
        					End => sub{$handlers->handle_elem_end(@_)},
	    					Char =>    sub{$handlers->handle_char_data(@_)}
    					} 
    );

	
    #
    # read in the data and run the parser on it
    #
    if( $file ) {
        $parser->parsefile( $file ); 
	#$Data::Dumper::Indent = 0;
	#print Dumper $tree;
        return $handlers->{tree};
    } else {
    	print "File $file does not exist!\n";
    	return;
    }

    ###
    ### Handlers
    ###
	package Xml_Handler;
	
	sub new {
		my $type = shift;
    	my $self = {};
=begin
		my $tree = [];
    my @element_stack;
    my @node_id_stack;
    my %parent_last_child_node_id;
    my $current_data;	
    my $last_start_element;
    my $last_start_node_id;
=cut    
		$self->{tree} = [];
		$self->{element_stack} = ();
		$self->{node_id_stack} = ();
		$self->{parent_last_child_node_id} = {};
		$self->{current_data} = '';
		$self->{last_start_element} = '';
		$self->{last_start_node_id} = '';
    	bless( $self, $type );
		return $self;
	}
	
    #
    # handle element start
    #
    sub handle_elem_start {
        my( $self, $expat, $name, %atts ) = @_;

        push @{$self->{element_stack}}, $name; #push to stack
	my $path = join '.', @{$self->{element_stack}};
		       
	## create a node, set the name and attribute
	my %node;
	$node{id} = $#{$self->{tree}} + 1;
	$node{name} = $path;
	$node{attribute} = \%atts;
	$node{parent} = -1;
	$node{first_child} = -1;
	$node{next} = -1;
	$node{text} = '';

	#parent, first_child, next
	if (defined $self->{node_id_stack}[$#{$self->{node_id_stack}}]) {
	    #parent
	    #the last node of the stack will always be the parent of current node
	    $node{parent} = $self->{node_id_stack}[$#{$self->{node_id_stack}}];

	    #first_child
	    #if this node's parent hasn't have a child yet, this node is the first child of the parent
	    if ($self->{tree}[$node{parent}]{first_child} == -1) {
		$self->{tree}[$node{parent}]{first_child} = $node{id};
	    }

	    #next
	    #get the last child of the parent and set its next and rest last child of the parent
	    if ($self->{parent_last_child_node_id}{$node{parent}}) {
		$self->{tree}[$self->{parent_last_child_node_id}{$node{parent}}]{next} = $node{id};
	    }
	    $self->{parent_last_child_node_id}{$node{parent}} = $node{id};
	}

	push @{$self->{tree}}, \%node;
		        
        $self->{current_data} = ''; # reset $current_data
        $self->{last_start_element} = $name;
	$self->{last_start_node_id} = $node{id};
        push @{$self->{node_id_stack}}, $node{id};
    } 
    
    #
    # collect character data into the recent element's buffer
    #
    sub handle_char_data {
        my( $self, $expat, $text ) = @_;
	$self->{current_data} .= $text;
    }

    #
    # pop up the closing element from stack
    # finish the node
    #
    sub handle_elem_end {
        my( $self, $expat, $name ) = @_;
        if( $name eq $self->{last_start_element} ) { # this is a text element
	    ## store text $current_data to the node
	    $self->{tree}[$self->{last_start_node_id}]{text} = $self->{current_data};
        }

        pop @{$self->{element_stack}};
	pop @{$self->{node_id_stack}};
       	$self->{current_data} = ''; # empty $current_data
    }
}

#
# get/set methods
#
sub get_root {
	my $self = shift;
	return $self->{root};
}
sub set_root {
	my $self = shift;
	my %args = @_;
	my $new_root = $args{-root};
	$self->{root} = $new_root;
}
sub get_current {
	my $self = shift;
	return $self->{current};
}
sub set_current {
	my $self = shift;
	my %args = @_;
	my $new_current = $args{-current};
	$self->{current} = $new_current;
}
sub get_id {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	return $self->{tree}[$node]{id};
}
sub set_id {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	my $new_id = $args{-id};
	$self->{tree}[$node]{id} = $new_id;
}
sub get_name {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	return $self->{tree}[$node]{name};
}
sub set_name {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	my $new_name = $args{-name};
	$self->{tree}[$node]{name} = $new_name;
}
sub get_text {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	return $self->{tree}[$node]{text};
}
sub set_text {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	my $new_text = $args{-text};
	$self->{tree}[$node]{text} = $new_text;
}
sub get_attribute {
	my $self	= shift;
	my %args = @_;
	my $node = $args{-node};
	return $self->{tree}[$node]{attribute};
}
sub set_attribute {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	my $name = $args{-name};
	my $value = $args{-value};
	my $attribute = $args{-attribute};
	
	if( $attribute ) {
		my %new_attribute = %$attribute;
		$self->{tree}[$node]{attribute} = \%new_attribute;
	}
	elsif( $name ) {
		$self->{tree}[$node]{attribute}{$name} = $value;
	}
}
sub get_next { # return the next node id
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	return $self->{tree}[$node]{next};
}
sub set_next {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	my $new_next = $args{-next};
	$self->{tree}[$node]{next} = $new_next;
}
sub get_first_child {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	return $self->{tree}[$node]{first_child};
}
sub set_first_child {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	my $new_first_child = $args{-first_child};
	$self->{tree}[$node]{first_child} = $new_first_child;
}
sub get_parent {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	return $self->{tree}[$node]{parent};
}
sub set_parent {
	my $self = shift;
	my %args = @_;
	my $node = $args{-node};
	my $new_parent = $args{-parent};
	$self->{tree}[$node]{parent} = $new_parent;
}
sub get_xml_tag {
    my $self = shift;
    my %args = @_;
    my $node = $args{-node};
    my $xml_tag = $self->get_name(-node=>$node);
    $xml_tag =~ s/^.*\.(.*)$/$1/;
    return $xml_tag;
}

# 
##########################################################
# This method adds a new node to the end of the tree. All pointers(parent, first_child, next) are set to -1.
#
# input: 
#		-name => name of the node. optional. 
#		-text => text of the node. optional. 
#		-attribute => hash reference. attribute of the node. optional
#
# output: 
#		id of the new node
#
# example: 
#		my $new = $Xml_Tree->add_node();
#
############################
sub add_node {
	my $self	= shift;
	my %args = @_;
	my $name = $args{-name} || '';
	my $text = $args{-text};
	my $attribute = $args{-attribute} || {};
	
	$text = '' if( ! defined $text );

	my $new_id = @{$self->{tree}};

	## add a new node after the last node
	my %node;
	$node{id} = $new_id;
	$node{name} = $name;
	$node{text} = $text;
	my %attr_hash = %$attribute;
	$node{attribute} = \%attr_hash;
	$node{parent} = -1;
	$node{first_child} = -1;
	$node{next} = -1;
	push @{$self->{tree}}, \%node;
	return $new_id;
}

## replace the old node( with children if it has ) with nodes created from a template
## keep the parent and next pointers unchanged
sub replace {
	my $self	= shift;
	my %args = @_;
	my $old = $args{-old};
	my $template = $args{-template};
	return $old if( !$template );
	
	my $parent = $self->get_parent( -node=> $old );
	my $next = $self->get_next( -node=> $old );
	my $first_child;
	my $is_first_child = 0;
	my $path;
	if( $self->is_valid( -node=>$parent ) ) {
		$first_child = $self->get_first_child( -node=>$parent );
		$path = $self->get_name( -node=>$parent );
	}
	if( $first_child == $old ) {
		$is_first_child = 1;
	}
	
	my $replace_tree = SDB::Xml_Tree->new( -file=>$template );
	return $old if( $replace_tree->is_empty() );

	## add new node(s) from template
	my $new = $self->deep_copy( -source_tree=>$replace_tree, -source_node=>$replace_tree->get_root(), -parent=>$parent, -prev=>-1, -is_first_child=>$is_first_child, -add_path=>$path );
	
	## assign the original next pointer to the last node( at the same level as old ) of the replace subtree	
	my $last = $new;
	my $next_node = $self->get_next( -node=>$new );
	while( $self->is_valid( -node=>$next_node ) ) {
		$last = $next_node;
		$next_node = $self->get_next( -node=>$next_node );
	}
	$self->set_next( -node=>$last, -next=>$next );
	
	## update the next pointer of the prior node if it is not the first child of the parent
	if( !$is_first_child ) {
		my $prior = $first_child;
		my $next_sibling = $self->get_next( -node=>$prior );
		while( $self->is_valid( -node=>$next_sibling ) && $next_sibling != $old ) {
			$prior = $next_sibling;
			$next_sibling = $self->get_next( -node=>$next_sibling );
		}
		if( $next_sibling == $old ) {
			$self->set_next( -node=>$prior, -next=>$new );
		}
	}

	return $new;
}

##########################################################
# This method makes a copy of the source node from the source tree. 
# It can either only copy the single node that is specified, or copy the specified node with all its children.
# The parent pointer will be set to -1 unless it is given. The next pointer is always set to -1.
#
# input:
#		-source_tree => the source tree
#  		-source_node => the source node
#		-parent => the parent node
#		-recursive => 0 or 1. If 1, the children of the source node will be copied too.
#
# output: 
#		the new node
#
# example: 
#		my $new_node = $tree->copy( -source_tree=>$src_tree, -source_node=>$source_node, -recursive=>1 );
#		my $new_node = $tree->copy( -source_tree=>$src_tree, -source_node=>$source_node, -parent=>$parent, -recursive=>1 );
#
############################
sub copy {
	my $self	= shift;
	my %args = @_;
	my $source_tree = $args{-source_tree};
	my $source_node = $args{-source_node};
	my $parent = $args{-parent};
	my $recursive = $args{-recursive}; # 1 or 0
	my $path = $args{-add_path};

	my $new_name = $source_tree->get_name( -node=>$source_node );
	$new_name = $path . '.' . $new_name if( $path );
	my $new = $self->add_node( 
					 -name=>$new_name, 
					 -text=>$source_tree->get_text( -node=>$source_node ),
					 -attribute=>$source_tree->get_attribute( -node=>$source_node )
					);
	$parent = -1 if( ! defined $parent );
	$self->set_parent( -node=>$new, -parent=>$parent );
	
	if( $recursive ) {
		## copy children
		my $child = $source_tree->get_first_child( -node=>$source_node );
		if( $source_tree->is_valid( -node=>$child ) ) {
			$self->deep_copy( -source_tree=>$source_tree, -source_node=>$child, -parent=>$new, -prev=>-1, -is_first_child=>1, -add_path=>$path );
		}
	}
	
	return $new;
}

sub deep_copy {
	my $self	= shift;
	my %args = @_;
	my $source_tree = $args{-source_tree};
	my $source_node = $args{-source_node};
	my $parent = $args{-parent};
	my $prev = $args{-prev};
	my $is_first_child = $args{-is_first_child};
	my $path = $args{-add_path};

	my $new_name = $source_tree->get_name( -node=>$source_node );
	$new_name = $path . '.' . $new_name if( $path );
	my $new = $self->add_node( 
					 -name=>$new_name, 
					 -text=>$source_tree->get_text( -node=>$source_node ),
					 -attribute=>$source_tree->get_attribute( -node=>$source_node )
					);
	$self->set_parent( -node=>$new, -parent=>$parent );
	if( $is_first_child ) {
		$self->set_first_child( -node=>$parent, -first_child=>$new );
	}
	if( $self->is_valid( -node=>$prev ) ) {
		$self->set_next( -node=>$prev, -next=>$new );
	}
	
	## copy first child
	my $child = $source_tree->get_first_child( -node=>$source_node );
	if( $source_tree->is_valid( -node=>$child ) ) {
		$self->deep_copy( -source_tree=>$source_tree, -source_node=>$child, -parent=>$new, -prev=>-1, -is_first_child=>1, -add_path=>$path );
	}
	
	## copy next node
	my $next = $source_tree->get_next( -node=>$source_node );
	if( $source_tree->is_valid( -node=>$next ) ) {
		$self->deep_copy( -source_tree=>$source_tree, -source_node=>$next, -parent=>$parent, -prev=>$new, -is_first_child=>0, -add_path=>$path );
	}
	
	return $new;
}

sub search {
	my $self	= shift;
	my %args = @_;
	my $name = $args{-name};
	my $branch = $args{-branch};
	my $return_all = $args{-return_all};
	my $start_with = $args{-start_with};
	
	my @matches;
	
	my $next;
	if( defined $branch ) {
		$next = $branch;
	}
	else {
		$branch = $self->get_root();
	}

	if( $name ) {
		while( $self->is_valid( -node=>$next ) ) {
			#return $next if( $self->get_name( -node=>$next ) eq $name );
			if( $self->get_name( -node=>$next ) eq $name ) {
				push @matches, $next;
			}
			$next = $self->get_next_node( -current=>$next );
		}
	}
	elsif( $start_with ) {
		while( $self->is_valid( -node=>$next ) ) {
			my $node_name = $self->get_name( -node=>$next );
			if(  $node_name =~ /^$start_with/ ) {
				push @matches, $next;
			}
			$next = $self->get_next_node( -current=>$next );
		}
	}
	
	if( $return_all ) {
		return @matches;
	}
	else {
		if( @matches ) {
			## return the first matched node id			
			return $matches[0];
		}
		else {
			return -1;
		}
	}
}

sub is_valid {
	my $self	= shift;
	my %args = @_;
	my $node = $args{-node};
	
	if( $node >= 0 ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub is_empty {
	my $self	= shift;
	if( $self->is_valid( -node=>$self->get_root() ) ){
		return 0;
	}
	else{
		return 1;
	}
}

sub remove {
	my $self	= shift;
	my %args = @_;
	my $node = $args{-node};
	
	my $child = $self->get_first_child( -node=>$node );
	if( $self->is_valid( -node=>$child ) ) {
		print "Node $node has children! It cannot be removed!\n";
		return $node; 
	}
	
	my $parent = $self->get_parent( -node=>$node );
	if( $self->is_valid( -node=>$parent ) ) {
		my $first_child = $self->get_first_child( -node=>$parent );
		if( $first_child == $node ) { ## this is the first child of its parent
			$self->set_first_child( -node=>$parent, -first_child=>$self->get_next( -node=>$node ) );
		}
		else {
			my $previous;
			my $current = $first_child;
			while( $current != $node ) {
				$previous = $current;
				$current = $self->get_next( -node=>$current );
			}
			$self->set_next( -node=>$previous, -next=>$self->get_next( -node=>$node ) );
		}
	}
	else { # no parent
			my $previous;
			my $current = $self->{root};
			while( $current != $node ) {
				$previous = $current;
				$current = $self->get_next( -node=>$current );
			}
			if( defined $previous ) {
				$self->set_next( -node=>$previous, -next=>$self->get_next( -node=>$node ) );
			}
			else { # this is the root node, replace the root with the next node
				$self->set_root( -root=>$self->get_next( -node=>$node ) );
			}
	}
	
	return $self->get_next( -node=>$node );
}

# get the next node with pre-order tree walking method
sub get_next_node {
	my $self	= shift;
	my %args = @_;
	my $current = $args{-current};
	
	my $child = $self->get_first_child( -node=>$current );
	if( $self->is_valid( -node=>$child ) ) {
		return $child;
	}
	else {
		my $next = $self->get_next( -node=>$current );
		if( $self->is_valid( -node=>$next ) ) {
			return $next;
		}
		else {
			my $parent = $self->get_parent( -node=>$current );
			while( $self->is_valid( -node=>$parent ) ) {
				
				my $parent_next = $self->get_next( -node=>$parent );
				if( $self->is_valid( -node=>$parent_next ) ) {
					return $parent_next;
				}
				else {
					$parent = $self->get_parent( -node=>$parent );
				}
			}
		}
	}
	
	return -1;
}
##########################################################
# This method is to generate xml from the tree.  
#
# input: 
#		-type => output type. e.g. "xml"
#		-out_file => output file name. optional.
#		-exclude_empty_attribute => flag to exclude empty attributes in the output. optional  
#
# output: 
#		Return the xml string. It also writes the xml string to the file if -out_file is given. 
#
# example: 
#		my $xml = $Xml_Tree->render( -type=>'xml' );
#		my $xml = $Xml_Tree->render( -type=>'xml', -out_file=>$filename );
#
############################
sub render { # output the XML
    my $self	= shift;
    my %args	= @_;
    my $type	= $args{-type};
    my $file	= $args{-out_file};
    my $exclude_empty_attribute = $args{-exclude_empty_attribute};

    ### create XML::Writer object ###
    my $xml = '';
    my $xmlns = "http://www.w3.org/2001/XMLSchema-instance";
    my $writer  = new XML::Writer( 
				   OUTPUT => \$xml, 
				   DATA_MODE=>1, 
				   DATA_INDENT=>8, 
				   #NAMESPACES=>1,
				   #PREFIX_MAP=>{ $xmlns=>'xsi' } 
				   );

    $writer->xmlDecl( 'UTF-8' );
    #$writer->startTag( [$xmlns, 'SAMPLE_SET'], [$xmlns, "noNamespaceSchemaLocation"], "$schema_location" );
    #$writer->startTag( [$xmlns, 'SAMPLE_SET'] );
    #print Dumper $self->{tree};

    my $node = $self->get_root();
    while( $self->is_valid( -node=>$node ) ) {
    		my %attrs_sorted;
			my $attrs = $self->get_attribute(-node=>$node);
			foreach my $key ( sort keys %$attrs ) {
				if( !$exclude_empty_attribute || ( defined $attrs->{$key} && $attrs->{$key} ) ) {
					$attrs_sorted{$key} = $attrs->{$key};
				}
			}
    	
	## if it is a text node, start and close using dataElement
	if ( $self->get_text(-node=>$node) ne '' ) {
            $writer->dataElement( $self->get_xml_tag(-node=>$node), $self->get_text(-node=>$node), %attrs_sorted );
        }
	elsif ( $self->get_first_child(-node=>$node) == -1) {
	    #single tag (no next and no child and no text)
	    $writer->startTag( $self->get_xml_tag(-node=>$node), %attrs_sorted );
	    $writer->endTag( $self->get_xml_tag(-node=>$node) );
	}
        else {
	    #else start tag
            $writer->startTag( $self->get_xml_tag(-node=>$node), %attrs_sorted );
        }

	## if no more child, recursively close tags if next is -1 (i.e. no more child and this is the last node of the level)
        if ($self->get_first_child(-node=>$node) == -1) {
            my $current_node = $node;
            #recurse until root
            while ($self->get_next(-node=>$current_node) == -1 && $self->get_parent(-node=>$current_node) != -1) {
                $current_node = $self->get_parent(-node=>$current_node);
                $writer->endTag( $self->get_xml_tag(-node=>$current_node) );
            }
        }

	$node = $self->get_next_node( -current=>$node );
    }

    $writer->end();
    
    if ($file) {
	open my $XMLF, ">$file" or die("Could not open $file");
	print {$XMLF} $xml;
	close $XMLF;
    }
		
    return $xml;
}

return 1;
