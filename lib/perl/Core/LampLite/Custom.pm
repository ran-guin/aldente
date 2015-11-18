package LampLite::Custom;

use strict;

use RGTools::RGIO;

#############
sub wizard {
#############
    my $self = shift;
    my %args = @_;
    my $title = $args{-title} || 'Fill in the Informations Please';
    my $pages = $args{-pages};
    
    
    my $id = $args{-id} || 'wid-id-0';         ## Wizard ID
    
    my @pages = @$pages if $pages;
    my $size = @pages;
    
    
    
    my $header ; ## contain css file info
    my $footer; ## contain js
    my $layers;
    my $top_layer;
    
    
    my $header = qq(<!-- Basic Styles -->
        <link rel="stylesheet" type="text/css" media="screen" href="http://192.241.236.31/test4.smartadmin/css/bootstrap.min.css">
        <link rel="stylesheet" type="text/css" media="screen" href="http://192.241.236.31/test4.smartadmin/css/font-awesome.min.css">
        <!-- SmartAdmin Styles : Please note (smartadmin-production.css) was created using LESS variables -->
        <link rel="stylesheet" type="text/css" media="screen" href="http://192.241.236.31/test4.smartadmin/css/smartadmin-production.css">
        <link rel="stylesheet" type="text/css" media="screen" href="http://192.241.236.31/test4.smartadmin/css/smartadmin-skins.css"> );
    
    for my $index (0 .. $size -1){
       my $number = $index+1;
       my $tab = 'tabular' . $number;
       my $step = 'step' . $number; 
       
       my $section_title = "<h3><strong>Step $number</strong> - $pages[$index]{-name}</h3>  ";
       
       if ($number == 1){
          $layers .= qq(
           	<div class="tab-pane active" id="$tab">
       			<br>$section_title<br>
               $pages[$index]{-content}
       			<br>
       			<br>
       		</div>
          );

          $top_layer .= qq( 
           	<li class="active" data-target="#$step">
    				<a href="#$tab" data-toggle="tab"> <span class="step">$number</span> <span class="title">$pages[$index]{-name}</span> </a>
    			</li>
    		 );
       }
       else{
          
          $layers .= qq(
           	<div class="tab-pane" id="$tab">
       			<br>$section_title<br>
               $pages[$index]{-content}
       			<br>
       			<br>
       		</div>
          );
          
          $top_layer .= qq( 
             <li data-target="#$step">
				   <a href="#$tab" data-toggle="tab"> <span class="step">$number</span> <span class="title">$pages[$index]{-name}</span> </a>
			    </li>
			 );
       }
    }
    
    
    
    
    
    
    my $widget = qq(
       <!-- NEW WIDGET START -->
       <article class="col-sm-12 col-md-12 col-lg-6">
		      <!-- Widget ID (each widget will need unique ID)-->
        		<div class="jarviswidget jarviswidget-color-darken" id="$id" data-widget-editbutton="false" data-widget-deletebutton="false">

        		<!-- widget options:
        		   usage: <div class="jarviswidget" id="$id" data-widget-editbutton="false">

        			data-widget-colorbutton="false"
        			data-widget-editbutton="false"
        			data-widget-togglebutton="false"
        			data-widget-deletebutton="false"
        			data-widget-fullscreenbutton="false"
        			data-widget-custombutton="false"
        			data-widget-collapsed="true"
        			data-widget-sortable="false"
				-->

				<header>
					<span class="widget-icon"> <i class="fa fa-check"></i> </span>
					<h2>$title </h2>
				</header>



        		<!-- widget div-->
        			<div>
        				<!-- widget edit box -->
        				<div class="jarviswidget-editbox">
        					<!-- This area used as dropdown edit box -->
        				</div>
        		   <!-- end widget edit box -->


				<!-- widget content -->
				   <div class="widget-body">

        				<div class="row">
        					<form id="wizard-1" novalidate="novalidate">
        					<div id="bootstrap-wizard-1" class="col-sm-12">
        						<div class="form-bootstrapWizard">
        							<ul class="bootstrapWizard form-wizard">
        							   $top_layer								
        							</ul>
        							<div class="clearfix"></div>
        						</div>
        						<div class="tab-content">
                            $layers								
        						       <div class="form-actions">

							);
    
    
    
    
    
    
    my $footer =qq(
       <div class="row">
         <div class="col-sm-12">
         <ul class="pager wizard no-margin">
         		<!--<li class="previous first disabled">
                     <a href="javascript:void(0);" class="btn btn-lg btn-default"> First </a>
               </li>-->
               <li class="previous disabled">
                     <a href="javascript:void(0);" class="btn btn-lg btn-default"> Previous </a>
               </li>
               <!--<li class="next last">
               		<a href="javascript:void(0);" class="btn btn-lg btn-primary"> Last </a>
               </li>-->
               <li class="next">
               		<a href="javascript:void(0);" class="btn btn-lg txt-color-darken"> Next </a>
            	</li>
         </ul>
         </div>
       </div>
	</div>
	</div>
	</div>
	</form>
	</div>
	</div>
	<!-- end widget content -->

	</div>
	<!-- end widget div -->
	</div>
	<!-- end widget -->
	</article>
   <!-- WIDGET END --> 
   );

   my $function = qq(
 		<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.0.2/jquery.min.js"></script>
 		<script>
 			if (!window.jQuery) {
 				document.write('<script src="http://192.241.236.31/test4.smartadmin/js/libs/jquery-2.0.2.min.js"><\\/script>');
 			}
 		</script>

 		<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.10.3/jquery-ui.min.js"></script>
 		<script>
 			if (!window.jQuery.ui) {
 				document.write('<script src="http://192.241.236.31/test4.smartadmin/js/libs/jquery-ui-1.10.3.min.js"><\\/script>');
 			}
 		</script>


         <script src="http://192.241.236.31/test4.smartadmin/js/plugin/bootstrap-wizard/jquery.bootstrap.wizard.min.js"></script>

         <script type="text/javascript">
      
         // DO NOT REMOVE : GLOBAL FUNCTIONS!

         \$(document).ready(function() {

         //Bootstrap Wizard Validations


           \$('#bootstrap-wizard-1').bootstrapWizard({
             'tabClass': 'form-wizard',
             'onNext': function (tabular, navigation, index) {
                
               var \$valid = \$("#wizard-1").valid();
               if (!\$valid) {

                 \$validator.focusInvalid();
                 return false;
               } else {
                  alert('bang2');
               
                 \$('#bootstrap-wizard-1').find('.form-wizard').children('li').eq(index - 1).addClass('complete');
                 alert('bang3');
                 
                 \$('#bootstrap-wizard-1').find('.form-wizard').children('li').eq(index - 1).find('.step').html('<i class="fa fa-check"></i>');
                 alert('bang4');
               
               }
             }
           });


         // fuelux wizard
           var wizard = \$('.wizard').wizard();

           wizard.on('finished', function (e, data) {
             //\$("#fuelux-wizard").submit();
             //console.log("submitted!");
             \$.smallBox({
               title: "Congratulations! Your form was submitted",
               content: "<i class='fa fa-clock-o'></i> <i>1 seconds ago...</i>",
               color: "#5F895F",
               iconSmall: "fa fa-check bounce animated",
               timeout: 4000
             });

           });


         })

         </script>

         </script>

         <script src="http://192.241.236.31/test4.smartadmin/js/bootstrap/bootstrap.min.js"></script>
         <script src="http://192.241.236.31/test4.smartadmin/js/notification/SmartNotification.min.js"></script>
         <script src="http://192.241.236.31/test4.smartadmin/js/smartwidgets/jarvis.widget.min.js"></script>
         <script src="http://192.241.236.31/test4.smartadmin/js/plugin/jquery-validate/jquery.validate.min.js"></script>
         <script src="http://192.241.236.31/test4.smartadmin/js/plugin/bootstrap-slider/bootstrap-slider.min.js"></script>
         <script src="http://192.241.236.31/test4.smartadmin/js/demo.js"></script>
         <script src="http://192.241.236.31/test4.smartadmin/js/app.js"></script>         
         
   );
      

    my $page = 
    "<!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->" .
    $header .$widget . $footer . $function .
    "<!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->" 
    
    ; 

    

    return $page;
}


return 1;
