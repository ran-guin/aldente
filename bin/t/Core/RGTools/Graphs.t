#!/usr/local/bin/perl

use strict;
use warnings;

# Add to the lib search path
use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Test::More qw(no_plan);
use Test::Differences;
use Test::Exception;
#use Test::Output;
use Test::MockModule;

use DBD::Mock;
use DBI;

# check that the module we're testing can be used
BEGIN {
    use_ok("RGTools::Graphs");
}

my $graph = Graphs->new();


# test public method
test_new();
test_set_config();
test_get_config();
test_create_graph();
test_get_PNG();
test_get_GIF();
test_create_PNG_file();
test_create_GIF_file();
test_get_PNG_HTML();
test_get_GIF_HTML();
#
# test Private Methods:
test__set_general_config();
test__set_axis_config();
test__set_line_config();
test__set_bar_config();
test__set_pie_config();
test__set_thumbnail();
test__set_matrix_config();
test__set_line_graph();
test__set_bar_graph();
test__set_pie_graph();
test__set_matrix_graph();



sub test_new {

  print "\nTesting new()\n";

  # create a new Graphs object
  my $graph = Graphs->new();
  # test if the object is type of 'Graphs';
  isa_ok ($graph, 'Graphs');
}

sub test_set_config {
  print "\nTesting set_config()\n";
  can_ok($graph, ("set_config"));
  my %input = (
	       -height => 500,
	       -width  => 300,
	       -data   => {
			   'x_axis' => [2,5,10,20],
			   'set 1'  => [3,4,8,9],
			   'set 2'  => [9.8,5,20.4,45],
			   },
	       -type   => 'xy',
	       );

  $graph->set_config(%input);
  ok ($graph->{height} == $input{-height}, 'set_config: set height');
  ok ($graph->{width} == $input{-width}, 'set_config: set width');
  is_deeply($graph->{data}, $input{-data}, 'set_config: set data');
  ok ($graph->{type} eq $input{-type}, 'set_config: set type');
}

sub test_get_config {
  print "\nTesting get_config()\n";
  can_ok($graph, ("get_config"));
  my $config = $graph->get_config();
  ok ($config->{height} == $graph->{height}, 'get_config: get height');
  ok ($config->{width} == $graph->{width}, 'get_config: get width');
  is_deeply($config->{data}, $graph->{data}, 'get_config: get data');
  ok ($config->{type} eq $graph->{type}, 'get_config: get type');
  my %input = (
	       -height => 500,
	       -width  => 300,
	       -data   => {
			   'x_axis' => [2,5,10,20],
			   'set 1'  => [3,4,8,9],
			   'set 2'  => [9.8,5,20.4,45],
			   },
	       -type   => 'xy',
	       );

  $graph->set_config(%input);
  $config = $graph->get_config();
  ok ($config->{height} == $input{-height}, 'get_config and set_config match');
  ok ($config->{width} == $input{-width}, 'get_config and set_config match');
  is_deeply($config->{data}, $input{-data}, 'get_config and set_config match');
  ok ($config->{type} eq $input{-type}, 'get_config and set_config match');
}

sub test_create_graph {
  print "\nTesting create_graph()\n";
  can_ok($graph, ("create_graph"));
  my %input = (
	       -height => 500,
	       -width  => 300,
	       -data   => {
			   'x_axis' => [2,5,10,20],
			   'set 1'  => [3,4,8,9],
			   'set 2'  => [9.8,5,20.4,45],
			   },
	       -type   => 'xy',
	       );
  $graph->set_config(%input);
  $graph->create_graph();
  isa_ok ($graph->{image}, 'GD::Image');
}

sub test_get_PNG {
  print "\nTesting get_PNG()\n";
  can_ok($graph, ("get_PNG"));
}
sub test_get_GIF {
  print "\nTesting get_GIF()\n";
  can_ok($graph, ("get_GIF"));
}

sub test_create_PNG_file {
  print "\nTesting create_PNG_file()\n";
  can_ok($graph, ("create_PNG_file"));
}

sub test_create_GIF_file {
  print "\nTesting create_GIF_file()\n";
  can_ok($graph, ("create_GIF_file"));
}

sub test_get_PNG_HTML {
  print "\nTesting get_PNG_HTML()\n";
  can_ok($graph, ("get_PNG_HTML"));
}
sub test_get_GIF_HTML {
  print "\nTesting get_GIF_HTML()\n";
  can_ok($graph, ("get_GIF_HTML"));
}
#
# test Private Methods:
sub test__set_general_config {

  print "\nTesting _set_general_config()\n";
  can_ok($graph,("_set_general_config"));
  my %input = (
	       -height => 500,
	       -width => 700,
	       -data => {
			 x_axis  => ['a', 'b', 'c', 'd'],
			 'set 1' => [1,2,3,4],
			 'set 2' => [3,4,5,6],
			},
	       -title => 'Title',
	       -type => 'line',
	       -dclrs => [ qw(orange yellow green dgreen blue purple black red) ],
	       -bgclr => 'black',
	       -axislabelclr => 'red',
	       -transparent => 1,
	       -interlaced => 1,
	       -zero_axis => 1,
	       -thumbnail => 1,
	      );
  $graph->_set_general_config(%input);
  ok ($graph->{height} == $input{-height}, '_set_general_config: set height');
  ok ($graph->{width} == $input{-width}, '_set_general_config: set width');
  is_deeply($graph->{data}, $input{-data}, '_set_general_config: set data');
  is_deeply($graph->{dclrs}, $input{-dclrs}, '_set_general_config: set dclrs');
  ok ($graph->{title} eq $input{-title}, '_set_general_config: set title');
  ok ($graph->{type} eq $input{-type}, '_set_general_config: set type');
  ok ($graph->{bgclr} eq $input{-bgclr}, '_set_general_config: set bgclr');
  ok ($graph->{axislabelclr} eq $input{-axislabelclr}, '_set_general_config: set asixlabelclr');
  ok ($graph->{transparent} == $input{-transparent}, '_set_general_config: set transparent');
  ok ($graph->{interlaced} == $input{-interlaced}, '_set_general_config: set interlaced');
  ok ($graph->{zero_axis} == $input{-zero_axis}, '_set_general_config: set zero_axis');
  ok ($graph->{thumbnail} == $input{-thumbnail}, '_set_general_config: set thumbnail');

  my %default = (
	       -height => undef,
	       -width => undef,
	       -type => undef,
	       -dclrs => undef,
	       -bgclr => undef,
	       -axislabelclr => undef,
	       -transparent => undef,
	       -interlaced => undef,
	       -zero_axis => undef,
	      );

  $graph->_set_general_config(%default);
  ok ($graph->{height} == 300, '_set_general_config: set height default');
  ok ($graph->{width} == 400, '_set_general_config: set width default');
  is_deeply($graph->{dclrs}, [ qw(red orange yellow green dgreen blue purple black) ], '_set_general_config: set dclrs default');
  ok ($graph->{type} eq 'line', '_set_general_config: set type default');
  ok ($graph->{bgclr} eq 'white', '_set_general_config: set bgclr default');
  ok ($graph->{axislabelclr} eq 'blue', '_set_general_config: set asixlabelclr default');
  ok ($graph->{transparent} == 0, '_set_general_config: set transparent default');
  ok ($graph->{interlaced} == 0, '_set_general_config: set interlaced default');
  ok ($graph->{zero_axis} == 0, '_set_general_config: set zero_axis default');

}

sub test__set_thumbnail {
  print "\nTesting _set_thumbnail()\n";
  can_ok($graph, ("_set_thumbnail"));
  my %input = (
	       -height => 500,
	       -width => 700,
	       -data => {
			 x_axis  => ['a', 'b', 'c', 'd'],
			 'set 1' => [1,2,3,4],
			 'set 2' => [3,4,5,6],
			},
	       -title => 'Title',
	       -type => 'line',
	       -dclrs => [ qw(orange yellow green dgreen blue purple black red) ],
	       -bgclr => 'black',
	       -axislabelclr => 'red',
	       -transparent => 1,
	       -interlaced => 1,
	       -zero_axis => 1,
	       -thumbnail => 1,
	      );
  $graph->set_config(%input);
  $graph->_set_thumbnail();
  ok ($graph->{height} == 40, '_set_thumbnail: set height');
  ok ($graph->{width} == 100, '_set_thumbnail: set width');
  ok ($graph->{title} eq '', '_set_thumbnail: set title');
  ok ($graph->{x_label} eq '', '_set_thumbnail: set x_label');
  ok ($graph->{y_label} eq '', '_set_thumbnail: set y_label');
  ok ($graph->{y_tick_number} == 1, '_set_thumbnail: set u_stick_number');
  ok ($graph->{show_values} == 0, '_set_thumbnail: set show_values');
  ok ($graph->{no_legend} == 1, '_set_thumbnail: set no_legend');
  ok ($graph->{axis_font} eq 'gdTinyFont', '_set_thumbnail: set axis_font');
  ok ($graph->{y_number_format} eq '%.1g', '_set_thumbnail: set y_number_format');
  ok ($graph->{marker_size} == 1, '_set_thumbnail: set marker_size');
  ok ($graph->{axis_space} == 0, '_set_thumbnail: set axis_space');
  ok ($graph->{y_label_skip} == ($graph->{y_tick_number} - 1), '_set_thumbnail: set y_label_skip');
  ok ($graph->{axislabelclr} eq $graph->{bgclr}, '_set_thumbnail: set asixlabelclr');
  ok ($graph->{long_ticks} == 0, '_set_thumbnail: set long_ticks');
  ok ($graph->{x_label_skip} == 3, '_set_thumbnail: set x_label_skip');

}



sub test__set_axis_config {
  print "\nTesting _set_axis_config()\n";
  can_ok($graph, ("_set_axis_config"));

  my %input = (
	       -y_label => 'Y Label',
	       -y_max_value => 10,
	       -y_min_value => 0,
	       -y_tick_number => 4,
	       -y_label_skip => 1,
	       -y_number_format => '%d',
	       -x_label => 'X Label',
	       -x_max_value => 5,
	       -x_min_value => 0,
	       -x_label_skip => 1,
	       -x_number_format => '',
	       -x_labels_vertical => 1,
	       -show_values => 1,
	       -values_format => '%d',	
	      );


  $graph->_set_axis_config(%input);
  ok ($graph->{y_label} eq $input{-y_label}, '_set_axis_config: set y_label');
  ok ($graph->{y_max_value} == $input{-y_max_value}, '_set_axis_config: set y_max_value');
  ok ($graph->{y_min_value} == $input{-y_min_value}, '_set_axis_config: set y_min_value');
  ok ($graph->{y_tick_number} == $input{-y_tick_number}, '_set_axis_config: set y_label');
  ok ($graph->{y_label_skip} == $input{-y_label_skip}, '_set_axis_config: set y_label_skip');
  ok ($graph->{y_number_format} eq $input{-y_number_format}, '_set_axis_config: set y_mumber_format');
  ok ($graph->{x_label} eq $input{-x_label}, '_set_axis_config: set x_label');
  ok ($graph->{x_max_value} == $input{-x_max_value}, '_set_axis_config: set x_max_value');
  ok ($graph->{x_min_value} == $input{-x_min_value}, '_set_axis_config: set x_min_value');
  ok ($graph->{x_label_skip} == $input{-x_label_skip}, '_set_axis_config: set x_label_skip');
  ok ($graph->{x_number_format} eq $input{-x_number_format}, '_set_axis_config: set x_mumber_format');
  ok ($graph->{show_values} == $input{-show_values}, '_set_axis_config: set show_values');
  ok ($graph->{values_format} eq $input{-values_format}, '_set_axis_config: set values_format');

  my %default = (
		 -y_tick_number     => undef,
		 -y_label_skip      => undef,
		 -x_label_skip      => undef,
		 -axis_space        => undef,
		 -long_ticks        => undef,
,
		 );
  $graph->_set_axis_config(%default);

  ok ($graph->{y_tick_number} == 5, '_set_axis_config: set y_tick_number default');
  ok ($graph->{y_label_skip} == 1, '_set_axis_config: set y_label_skip default');
  ok ($graph->{x_label_skip} == 1 , '_set_axis_config: set x_label_skip default');
  ok ($graph->{axis_space} == 4, '_set_axis_config: set axis_space default');
  ok ($graph->{long_ticks} == 0, '_set_axis_config: set long_ticks default');

}


sub test__set_line_config {
  print "\nTesting _set_line_config()\n";
  can_ok($graph, ("_set_line_config"));

  my %input = (
	       -marker_size => 7,
	      );

  $graph->_set_line_config(%input);

  ok ($graph->{marker_size} == $input{-marker_size}, '_set_line_config: set values_format');

  my %default = (
		 -marker_size       => undef,
,
		 );
  $graph->_set_line_config(%default);

  ok ($graph->{marker_size} == 4, '_set_line_config: set marker_size default');

}
sub test__set_bar_config {
  print "\nTesting _set_bar_config()\n";
  can_ok($graph, ("_set_bar_config"));

  my %input = (
	           -bar_width => 5,
	           -bar_spacing => 10,
		   );


  $graph->_set_bar_config(%input);

  ok ($graph->{bar_spacing} == $input{-bar_spacing}, '_set_bar_config: set bar_spacing');
  ok ($graph->{bar_width} == $input{-bar_width}, '_set_bar_config: set bar_width');

  my %default = (
		 -bar_width         => undef,
		 -bar_spacing       => undef,
		 );
  $graph->_set_bar_config(%default);

  ok ($graph->{bar_width} == 10, '_set_bar_config: set bar_width default');
  ok ($graph->{bar_spacing} == 4, '_set_bar_config: set bar_spacing default');

}
sub test__set_pie_config {
  print "\nTesting _set_pie_config()\n";
  can_ok($graph, ("_set_pie_config"));

  my %input = (
	       '-3d' => 1,
	       -pie_height => 10,
	       -start_angle => 5,
	       -suppress_angle => 4,
	      );


  $graph->_set_pie_config(%input);
  ok ($graph->{'3d'} eq $input{'-3d'}, '_set_pie_config: set 3d');
  ok ($graph->{pie_height} == $input{-pie_height}, '_set_pie_config: set pie_height');
  ok ($graph->{start_angle} == $input{-start_angle}, '_set_pie_config: set start_angle');
  ok ($graph->{suppress_angle} == $input{-suppress_angle}, '_set_pie_config: set suppress_angle');


  my %default = (
		 '-3d'            => undef,
		 -pie_height      => undef,
		 );
  $graph->_set_pie_config(%default);

  ok ($graph->{'3d'} == 1, '_set_pie_config: set 3d default');
  ok ($graph->{pie_height} == 0.1 * $graph->{height}, '_set_pie_config: set pie_height');

}
sub test__set_matrix_config {
  TODO: {
      local $TODO = "Not implemented";

  };
}
sub test__set_line_graph {
  print "\nTesting _set_line_graph()\n";
  can_ok($graph, ("_set_line_graph"));
  my %input = (
	       -height => 500,
	       -width  => 300,
	       -data   => {
			   'x_axis' => [2,5,10,20],
			   'set 1'  => [3,4,8,9],
			   'set 2'  => [9.8,5,20.4,45],
			   },
	       -type   => 'xy',
	       );
  $graph->set_config(%input);
  $graph->_set_line_graph(%input);
  isa_ok ($graph->{image}, 'GD::Image');
}
sub test__set_bar_graph {
  print "\nTesting _set_bar_graph()\n";
  can_ok($graph, ("_set_bar_graph"));
  my %input = (
	       -height => 500,
	       -width  => 300,
	       -data   => {
			   'x_axis' => [2,5,10,20],
			   'set 1'  => [3,4,8,9],
			   'set 2'  => [9.8,5,20.4,45],
			   },
	       -type   => 'bar',
	       );
  $graph->set_config(%input);
  $graph->_set_bar_graph(%input);
  isa_ok ($graph->{image}, 'GD::Image');
}
sub test__set_pie_graph {
  print "\nTesting _set_pie_graph()\n";
  can_ok($graph, ("_set_pie_graph"));
  my %input = (
	       -height => 500,
	       -width  => 300,
	       -data   => {
			   'x_axis' => [2,5,10,20],
			   'set 1'  => [3,4,8,9],
			   },
	       -type   => 'pie',
	       );
  $graph->set_config(%input);
  $graph->_set_pie_graph(%input);
  isa_ok ($graph->{image}, 'GD::Image');
}
sub test__set_matrix_graph {
}
