package gdchart;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
package gdchart;
bootstrap gdchart;
var_gdchart_init();
@EXPORT = qw(	line_graph bar_graph area_graph line_graph_3d bar_graph_3d
		area_graph_3d double_stack triple_stack hiloclose hiloclose_3d
		combo_line_bar combo_line_area combo_hlc_bar combo_hlc_area
		combo_hlc_bar_3d combo_hlc_area_3d pie_chart combo_line_bar_3d
		combo_line_area_3d gdc_annotate four_stack five_stack
		six_stack seven_stack eight_stack nine_stack ten_stack);
1;
$VERSION="1.0";

%chart_types = (	line			=> 0,
			area			=> 1,
			bar			=> 2,
			hiloclose		=> 3, 
			combo_line_bar		=> 4,
			combo_hlc_bar		=> 5,
			combo_line_area		=> 6,  
			combo_hlc_area		=> 7,
			hiloclose_3d		=> 8,
			combo_line_bar_3d	=> 9,
			combo_line_area_3d	=> 10,
			combo_hlc_bar_3d	=> 11,
			combo_hlc_area_3d	=> 12,
			bar_3d			=> 13,
			area_3d			=> 14,
			line_3d			=> 15); 

%title_sizes = (	verysmall => 1,
			small => 2,
			mediumbold => 3,
			large => 4,
			verylarge => 5 );

%stack_types = (	behind => 0,
			above => 1,
			beside => 2,
			layered => 3 );

%hlc_styles = (		diamond => 1,
			close_connected => 2,
			connecting =>	4,
			i_cap	=> 8 );


%gdcpie_pct_placements = (	none 	=> 0,
				above 	=> 1,
				below 	=> 2,
				right 	=> 3,
				left 	=> 4,
			);


# Globals
$GDC_novalue=-99999999;
$GDC_title_size="verylarge";
$GDC_xtitle_size="mediumbold";
$GDC_ytitle_size="mediumbold";
$GDC_3d_depth=5.0;
$GDC_3d_angle=45;
$GDC_bar_width=75;
$GDC_BGColor=hex 'ffffff';
$GDC_GridColor=hex'b5b5b5';
$GDC_grid=1;
$GDC_XTitleColor;
$GDC_YTitleColor;
$GDC_YTitle2Color;
$GDC_XLabelColor;
$GDC_YLabelColor;
$GDC_YLabel2Color;
$GDC_xaxis=1;
$GDC_yaxis=1;
$GDC_yaxis2=1;
$GDC_border=1;
$GDC_requested_ymin=0;
$GDC_requested_ymax=1;
$GDC_requested_yinterval=1;
$GDC_ylabel_density=80;
$GDC_HLC_cap_width=20;
$GDC_ylabel_fmt="%.2f";

# Pie Globals
$gdcpie_nocolor = hex '1000000';
$GDC_pie_bgcolor = hex 'ffffff';
$GDC_pie_textcolor = 0;
$GDC_pie_plotcolor = hex 'ffffff';
$GDC_pie_edgecolor = $gdcpie_nocolor;
$GDC_pie_other_threshold=-1;
$GDC_pie_3d_angle=45;
$GDC_pie_3d_depth=25;
$GDC_pie_title_size="mediumbold";
$GDC_pie_label_size="mediumbold";
$GDC_pie_label_line=1;
$GDC_pie_label_dist=20;
$GDC_pct_placement="right";


# to be implemented:
# 
# scatter
#
#
sub set_variables	{
set_vars (      $GDC_stack_type,
                $GDC_title,
                $GDC_xtitle,
                $GDC_ytitle,
                $GDC_ytitle2,
                $title_sizes{$GDC_title_size},
                $title_sizes{$GDC_xtitle_size},
                $title_sizes{$GDC_ytitle_size},
                $GDC_3d_depth,
                $GDC_3d_angle,
                $GDC_bar_width,
                $GDC_BGColor,
                $GDC_TitleColor,
                $GDC_GridColor,
                $GDC_LineColor,
                $GDC_PlotColor,
                $GDC_VolColor,
		$GDC_XTitleColor,
		$GDC_YTitleColor,
		$GDC_YTitle2Color,
		$GDC_XLabelColor,
		$GDC_YLabelColor,
		$GDC_YLabel2Color,
		$GDC_grid,
		$GDC_xaxis,
		$GDC_yaxis,
		$GDC_yaxis2,
		$GDC_border,
		$GDC_requested_ymin,
		$GDC_requested_ymax,
		$GDC_requested_yinterval,
		$GDC_ylabel_density,
		$GDC_HLC_Style,
		$GDC_HLC_cap_width,
		$GDC_ylabel_fmt,
		$GDC_extcolor_ref,
		$GDC_bg_image);
}

sub set_pievariables	{

set_pievars	(
$GDC_pie_bgcolor,
$GDC_pie_textcolor,
$GDC_pie_plotcolor,
$GDC_pie_edgecolor,
$GDC_pie_other_threshold,
$GDC_pie_3d_angle,
$GDC_pie_3d_depth,
$title_sizes{$GDC_pie_title_size},
$title_sizes{$GDC_pie_label_size},
$GDC_pie_label_dist,
$GDC_pie_label_line,
$GDC_pie_explode_ref,
$GDC_missing_ref,
$gdcpie_pct_placements{$GDC_pct_placement},
$GDC_pie_title);
			}

sub gdc_annotate	{

$GDC_anno_font = $title_sizes{"small"} unless defined ($GDC_anno_font); 
$GDC_anno_color = 0 unless defined ($GDC_anno_color); 
#
#annotate	(
#		$GDC_anno_set,
#		$GDC_anno_color,
#		$GDC_anno_note,
#		$GDC_anno_point,
#		$GDC_anno_font );
#
			}
	
sub line_graph {

my ( $width, $height, $filename, $labels, $dataset, $plotcolor, $title, $xtitle, $ytitle) = @_;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}

$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$plotcolor;

set_variables();

$number = greatest ($dataset, $labels);

$dataset_ref = ptrcreate ("float", 0,  $number+1);
$labels_ref = ptrcreate ("char *", "novalue", $number+1);
 
for ( $i = 0; $i <= $number; $i++) {
        ptrset ($dataset_ref, $$dataset[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

single_arg (    $width, $height,
                $filename,
                ($#$dataset+1),
                $labels_ref,
                $dataset_ref,
                $chart_types{"line"} );

return $filename;
		}

sub bar_graph {

my ( $width, $height, $filename, $labels, $dataset, $plotcolor, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$plotcolor;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset_ref = ptrcreate ("float", 0, $#$dataset+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);

for ( $i = 0; $i <= $#$dataset; $i++) {
        ptrset ($dataset_ref, $$dataset[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

single_arg (    $width, $height,
                $filename,
                ($#$dataset+1),
                $labels_ref,
                $dataset_ref,
                $chart_types{"bar"} );

return $filename;
		}

sub area_graph {

my ( $width, $height, $filename, $labels, $dataset, $plotcolor, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$plotcolor;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$number = greatest ($dataset, $labels);

$dataset_ref = ptrcreate ("float", 0, $number+1);
$labels_ref = ptrcreate ("char *", "test", $number+1);
 
for ( $i = 0; $i <= $number; $i++) {
        ptrset ($dataset_ref, $$dataset[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

single_arg (    $width, $height,
                $filename,
                ($#$dataset+1),
                $labels_ref,
                $dataset_ref,
                $chart_types{"area"} );

return $filename;
		}

sub bar_graph_3d {

my ( $width, $height, $filename, $labels, $dataset, $plotcolor, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$plotcolor;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$number = greatest ($dataset, $labels);

$dataset_ref = ptrcreate ("float", 0, $number+1);
$labels_ref = ptrcreate ("char *", "test", $number+1);
 
for ( $i = 0; $i <= $number; $i++) {
        ptrset ($dataset_ref, $$dataset[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

single_arg (    $width, $height,
                $filename,
                ($#$dataset+1),
                $labels_ref,
                $dataset_ref,
                $chart_types{"bar_3d"} );

return $filename;
		}

sub line_graph_3d {

my ( $width, $height, $filename, $labels, $dataset, $plotcolor, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$plotcolor;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$number = greatest ($dataset, $labels);

$dataset_ref = ptrcreate ("float", 0, $number+1);
$labels_ref = ptrcreate ("char *", "test", $number+1);
 
for ( $i = 0; $i <= $number; $i++) {
        ptrset ($dataset_ref, $$dataset[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

single_arg (    $width, $height,
                $filename,
                ($#$dataset+1),
                $labels_ref,
                $dataset_ref,
                $chart_types{"line_3d"} );

return $filename;
		}

sub area_graph_3d {

my ( $width, $height, $filename, $labels, $dataset, $plotcolor, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$plotcolor;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$number = greatest ($dataset, $labels);

$dataset_ref = ptrcreate ("float", 0, $number+1);
$labels_ref = ptrcreate ("char *", "test", $number+1);
 
for ( $i = 0; $i <= $number; $i++) {
        ptrset ($dataset_ref, $$dataset[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

single_arg (    $width, $height,
                $filename,
                ($#$dataset+1),
                $labels_ref,
                $dataset_ref,
                $chart_types{"area_3d"} );

return $filename;
		}


sub double_stack {

my ( $type, $stack_type, $width, $height, $filename, $labels, $dataset1, $dataset2, $plotcolors, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=$stack_types{$stack_type};
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}

set_variables();

$number = greatest ($dataset1, $dataset2, $labels);

$dataset1_ref = ptrcreate ("float", $GDC_novalue, $number+1);
$dataset2_ref = ptrcreate ("float", $GDC_novalue, $number+1);
$plotcolors_ref = ptrcreate ("long", 0, $number+1);
$labels_ref = ptrcreate ("char *", "novalue", $number+1);
 
for ( $i = 0; $i <= $number; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

double_arg (    $width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref,
                $dataset2_ref,
                $chart_types{"$type"} );

return $filename;
		}


sub combo_line_bar {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $axis1col, $axis2col, $title, $xtitle, $ytitle) = @_;

$number = greatest ($dataset1, $dataset2, $labels);

$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$axis1col;
$GDC_VolColor=$axis2col;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $number; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}

set_variables();

$dataset1_ref = ptrcreate ("float", 0, $number+1);
$dataset2_ref = ptrcreate ("float", 0, $number+1);
$labels_ref = ptrcreate ("char *", "test", $number+1);
 
for ( $i = 0; $i <= $number; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

combo (		$width, $height,
                $filename,
                ($number +1),
                $labels_ref,
                $dataset1_ref,
                $dataset2_ref,
                $chart_types{"combo_line_bar"} );

return $filename;
		}

sub combo_line_area {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $axis1col, $axis2col, $title, $xtitle, $ytitle) = @_;


$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$axis1col;
$GDC_VolColor=$axis2col;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

combo (		$width, $height,
                $filename,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref,
                $dataset2_ref,
                $chart_types{"combo_line_area"} );

return $filename;
		}

sub triple_stack {

my ( $type, $stack_type, $width, $height, $filename, $labels, $dataset1, $dataset2, $dataset3, $plotcolors, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=$stack_types{$stack_type};
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

triple_arg (    $width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref,
                $chart_types{"$type"} );

return $filename;
		}

sub hiloclose_3d {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $dataset3, $plotcolors, $hlc_style, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

$GDC_HLC_Style=0;

foreach $style (@$hlc_style)	{
	$GDC_HLC_Style = $GDC_HLC_Style + $hlc_styles{$style};
				}

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

hiloclose_wrap ($width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref,
                $chart_types{"hiloclose_3d"} );

return $filename;
		}

sub hiloclose {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $dataset3, $plotcolors, $hlc_style, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

$GDC_HLC_Style=0;

foreach $style (@$hlc_style)	{
	$GDC_HLC_Style = $GDC_HLC_Style + $hlc_styles{$style};
				}

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

hiloclose_wrap ($width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref,
                $chart_types{"hiloclose"} );

return $filename;
		}

sub combo_hlc_bar {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $dataset3, $dataset4, $plotcolors, $axis2color, $hlc_style, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

$GDC_HLC_Style=0;

foreach $style (@$hlc_style)	{
	$GDC_HLC_Style = $GDC_HLC_Style + $hlc_styles{$style};
				}

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

combo_hiloclose_wrap ($width, $height,
                $filename,
		$axis2color,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref,
		$dataset4_ref,
                $chart_types{"combo_hlc_bar"} );

return $filename;
		}

sub combo_hlc_area {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $dataset3, $dataset4, $plotcolors, $axis2color, $hlc_style, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

$GDC_HLC_Style=0;

foreach $style (@$hlc_style)	{
	$GDC_HLC_Style = $GDC_HLC_Style + $hlc_styles{$style};
				}

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

combo_hiloclose_wrap ($width, $height,
                $filename,
		$axis2color,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref,
		$dataset4_ref,
                $chart_types{"combo_hlc_area"} );

return $filename;
		}

sub combo_hlc_bar_3d {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $dataset3, $dataset4, $plotcolors, $axis2color, $hlc_style, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

$GDC_HLC_Style=0;

foreach $style (@$hlc_style)	{
	$GDC_HLC_Style = $GDC_HLC_Style + $hlc_styles{$style};
				}

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

combo_hiloclose_wrap ($width, $height,
                $filename,
		$axis2color,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref,
		$dataset4_ref,
                $chart_types{"combo_hlc_bar_3d"} );

return $filename;
		}

sub combo_hlc_area_3d {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $dataset3, $dataset4, $plotcolors, $axis2color, $hlc_style, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=0;
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

$GDC_HLC_Style=0;

foreach $style (@$hlc_style)	{
	$GDC_HLC_Style = $GDC_HLC_Style + $hlc_styles{$style};
				}

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

combo_hiloclose_wrap ($width, $height,
                $filename,
		$axis2color,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref,
		$dataset4_ref,
                $chart_types{"combo_hlc_area_3d"} );

return $filename;
		}


sub pie_chart	{

my ( $width, $height, $filename, $labels, $dataset1, $piecolors, $pie_type, $title) = @_;

$GDC_pie_title=$title;

$number = greatest ($dataset1, $labels);

$GDC_pie_explode_ref = ptrcreate ("int", 0, $#$dataset1+1);
$GDC_missing_ref = ptrcreate ("int", 0, $#$dataset1+1);

@missing = @ { $GDC_pie_missing };
@explode = @ { $GDC_pie_explode };

if ( $#explode > 1 )	{

for ( $i = 0; $i <= $#explode; $i++) 	{
	ptrset ($GDC_pie_explode_ref, $explode[$i], $i, "int");
					}

			}

if ( $#missing > 1 )	{

for ( $i = 0; $i <= $#missing; $i++) 	{
        ptrset ($GDC_missing_ref, $missing[$i], $i, "int");
					}	
			}

set_pievariables();

$gd_pietype = 1 if $pie_type eq "2d";
$gd_pietype = 0 if $pie_type eq "3d";

$dataset1_ref = ptrcreate ("float", 0, $number+1);
$labels_ref = ptrcreate ("char *", "test", $number+1);
$piecolors_ref = ptrcreate ("long", "test", $number+1);

for ( $i = 0; $i <= $number; $i++) {
        ptrset ($piecolors_ref, $$piecolors[$i], $i, "long");
		}

for ( $i = 0; $i <= $number; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
				}

$pie_type=$pie_types{$graph_type};
gd_pie_graph	(	$width, $height,
		 	$filename,
		 	$gd_pietype,
		 	$piecolors_ref,
			($#$dataset1 + 1),
			$labels_ref,
			$dataset1_ref	);
}

sub combo_line_area_3d {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $axis1col, $axis2col, $title, $xtitle, $ytitle) = @_;


$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$axis1col;
$GDC_VolColor=$axis2col;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

combo (		$width, $height,
                $filename,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref,
                $dataset2_ref,
                $chart_types{"combo_line_area_3d"} );

return $filename;
		}

sub combo_line_bar_3d {

my ( $width, $height, $filename, $labels, $dataset1, $dataset2, $axis1col, $axis2col, $title, $xtitle, $ytitle) = @_;


$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;
$GDC_PlotColor=$axis1col;
$GDC_VolColor=$axis2col;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

combo (		$width, $height,
                $filename,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref,
                $dataset2_ref,
                $chart_types{"combo_line_bar_3d"} );

return $filename;
		}

sub greatest        {
my $greatest = 0;
foreach $array (@_)     {
$greatest = $#$array if $greatest < $#$array;
                        }
return $greatest;
                }

sub four_stack {

my ( 	$type, $stack_type, $width, $height, $filename, $labels, 
	$dataset1, $dataset2, $dataset3, $dataset4, 
	$plotcolors, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=$stack_types{$stack_type};
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

four_arg (    $width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref, $dataset4_ref,
                $chart_types{"$type"} );

return $filename;
		}


sub five_stack {

my ( 	$type, $stack_type, $width, $height, $filename, $labels, 
	$dataset1, $dataset2, $dataset3, $dataset4, $dataset5, 
	$plotcolors, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=$stack_types{$stack_type};
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$dataset5_ref = ptrcreate ("float", 0, $#$dataset5+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($dataset5_ref, $$dataset5[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

five_arg (    $width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref, $dataset4_ref,
		$dataset5_ref,
                $chart_types{"$type"} );

return $filename;
		}


sub six_stack {

my ( 	$type, $stack_type, $width, $height, $filename, $labels, 
	$dataset1, $dataset2, $dataset3, $dataset4, $dataset5, $dataset6, 
	$plotcolors, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=$stack_types{$stack_type};
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$dataset5_ref = ptrcreate ("float", 0, $#$dataset5+1);
$dataset6_ref = ptrcreate ("float", 0, $#$dataset6+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($dataset5_ref, $$dataset5[$i], $i, "float");
        ptrset ($dataset6_ref, $$dataset6[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

six_arg (    $width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref, $dataset4_ref,
		$dataset5_ref,$dataset6_ref,
                $chart_types{"$type"} );

return $filename;
		}


sub seven_stack {

my ( 	$type, $stack_type, $width, $height, $filename, $labels, 
	$dataset1, $dataset2, $dataset3, $dataset4, $dataset5, $dataset6, $dataset7, 
	$plotcolors, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=$stack_types{$stack_type};
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$dataset5_ref = ptrcreate ("float", 0, $#$dataset5+1);
$dataset6_ref = ptrcreate ("float", 0, $#$dataset6+1);
$dataset7_ref = ptrcreate ("float", 0, $#$dataset7+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($dataset5_ref, $$dataset5[$i], $i, "float");
        ptrset ($dataset6_ref, $$dataset6[$i], $i, "float");
        ptrset ($dataset7_ref, $$dataset7[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

seven_arg (    $width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref, $dataset4_ref,
		$dataset5_ref, $dataset6_ref, $dataset7_ref,
                $chart_types{"$type"} );

return $filename;
		}

sub eight_stack {

my ( 	$type, $stack_type, $width, $height, $filename, $labels, 
	$dataset1, $dataset2, $dataset3, $dataset4, $dataset5, $dataset6, $dataset7, $dataset8, 
	$plotcolors, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=$stack_types{$stack_type};
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}
set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$dataset5_ref = ptrcreate ("float", 0, $#$dataset5+1);
$dataset6_ref = ptrcreate ("float", 0, $#$dataset6+1);
$dataset7_ref = ptrcreate ("float", 0, $#$dataset7+1);
$dataset8_ref = ptrcreate ("float", 0, $#$dataset8+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($dataset5_ref, $$dataset5[$i], $i, "float");
        ptrset ($dataset6_ref, $$dataset6[$i], $i, "float");
        ptrset ($dataset7_ref, $$dataset7[$i], $i, "float");
        ptrset ($dataset8_ref, $$dataset8[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

eight_arg (    $width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref, $dataset4_ref,
		$dataset5_ref, $dataset6_ref, $dataset7_ref, $dataset8_ref,
                $chart_types{"$type"} );

return $filename;
		}


sub nine_stack {

my ( 	$type, $stack_type, $width, $height, $filename, $labels, 
	$dataset1, $dataset2, $dataset3, $dataset4, $dataset5, $dataset6, $dataset7, $dataset8, $dataset9, 
	$plotcolors, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=$stack_types{$stack_type};
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}

set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$dataset5_ref = ptrcreate ("float", 0, $#$dataset5+1);
$dataset6_ref = ptrcreate ("float", 0, $#$dataset6+1);
$dataset7_ref = ptrcreate ("float", 0, $#$dataset7+1);
$dataset8_ref = ptrcreate ("float", 0, $#$dataset8+1);
$dataset9_ref = ptrcreate ("float", 0, $#$dataset9+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($dataset5_ref, $$dataset5[$i], $i, "float");
        ptrset ($dataset6_ref, $$dataset6[$i], $i, "float");
        ptrset ($dataset7_ref, $$dataset7[$i], $i, "float");
        ptrset ($dataset8_ref, $$dataset8[$i], $i, "float");
        ptrset ($dataset9_ref, $$dataset9[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

nine_arg (    $width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref, $dataset4_ref,
		$dataset5_ref, $dataset6_ref, $dataset7_ref, $dataset8_ref,
		$dataset9_ref,
                $chart_types{"$type"} );

return $filename;
		}


sub ten_stack {

my ( 	$type, $stack_type, $width, $height, $filename, $labels, 
	$dataset1, $dataset2, $dataset3, $dataset4, $dataset5, $dataset6, $dataset7, $dataset8, $dataset9, $dataset10, 
	$plotcolors, $title, $xtitle, $ytitle) = @_;


$GDC_stack_type=$stack_types{$stack_type};
$GDC_title=$title;
$GDC_xtitle=$xtitle;
$GDC_ytitle=$ytitle;

if ( $GDC_anno_point == 0 )	{
	$GDC_anno_set = 0;
	gdc_annotate();
				}

else 				{
	$GDC_anno_set = 1;
	gdc_annotate();
				}

if (defined $GDC_extcolor )	{
	@array = @ {$GDC_extcolor};
	$GDC_extcolor_ref = ptrcreate ("long", 0, $#$dataset+1);

for ( $i = 0; $i <= $#array; $i++) 	{
        ptrset ($GDC_extcolor_ref, $array[$i], $i, "long");
                       			}
				}

else 	{
	$GDC_extcolor_ref = ptrcreate ("long", $GDC_novalue, 1);
	}

set_variables();

$dataset1_ref = ptrcreate ("float", 0, $#$dataset1+1);
$dataset2_ref = ptrcreate ("float", 0, $#$dataset2+1);
$dataset3_ref = ptrcreate ("float", 0, $#$dataset3+1);
$dataset4_ref = ptrcreate ("float", 0, $#$dataset4+1);
$dataset5_ref = ptrcreate ("float", 0, $#$dataset5+1);
$dataset6_ref = ptrcreate ("float", 0, $#$dataset6+1);
$dataset7_ref = ptrcreate ("float", 0, $#$dataset7+1);
$dataset8_ref = ptrcreate ("float", 0, $#$dataset8+1);
$dataset9_ref = ptrcreate ("float", 0, $#$dataset9+1);
$dataset10_ref = ptrcreate ("float", 0, $#$dataset10+1);
$plotcolors_ref = ptrcreate ("long", 0, $#$plotcolors+1);
$labels_ref = ptrcreate ("char *", "test", $#$labels+1);
 
for ( $i = 0; $i <= $#$dataset1; $i++) {
        ptrset ($dataset1_ref, $$dataset1[$i], $i, "float");
        ptrset ($dataset2_ref, $$dataset2[$i], $i, "float");
        ptrset ($dataset3_ref, $$dataset3[$i], $i, "float");
        ptrset ($dataset4_ref, $$dataset4[$i], $i, "float");
        ptrset ($dataset5_ref, $$dataset5[$i], $i, "float");
        ptrset ($dataset6_ref, $$dataset6[$i], $i, "float");
        ptrset ($dataset7_ref, $$dataset7[$i], $i, "float");
        ptrset ($dataset8_ref, $$dataset8[$i], $i, "float");
        ptrset ($dataset9_ref, $$dataset9[$i], $i, "float");
        ptrset ($dataset10_ref, $$dataset10[$i], $i, "float");
        ptrset ($labels_ref, $$labels[$i], $i, "char *");
                        }

for ( $i = 0; $i <= $#$plotcolors; $i++) {
        ptrset ($plotcolors_ref, $$plotcolors[$i], $i, "long");
		}

ten_arg (    $width, $height,
                $filename,
		$plotcolors_ref,
                ($#$dataset1 +1),
                $labels_ref,
                $dataset1_ref, $dataset2_ref, $dataset3_ref, $dataset4_ref,
		$dataset5_ref, $dataset6_ref, $dataset7_ref, $dataset8_ref,
		$dataset9_ref, $dataset10_ref,
                $chart_types{"$type"} );

return $filename;
		}


