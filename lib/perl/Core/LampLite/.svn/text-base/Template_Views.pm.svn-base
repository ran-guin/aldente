###################################################################################################################################
# LampLite::Template_Views.pm
#
#
#
#
###################################################################################################################################
package LampLite::Template_Views;

use base LampLite::Views;

use strict;

## RG Tools
use RGTools::RGIO;
use LampLite::Bootstrap;

use LampLite::Template;
use LampLite::CGI;

my $BS = new Bootstrap();    ## Login errors do not need to be session logged, so can be called directly ##
my $q = new LampLite::CGI();

###############
sub std_page {
###############
    my $self = shift;

    my @fields = ('Employee_Name', 'Employee_ID', 'Employee_Status');
    my $table = 'Employee';

    my $page = "<h2>...VIEW...</h2>\n";
    
    $page .= $self->head();
    $page .= "Table: \n";
    $page .= $self->table(-table=>$table, -fields=>\@fields);
    $page .= $self->script(-table=>$table, -fields=>\@fields);
    
    $page .= "<A Href='http://limsdev02.bcgsc.ca/SDB_rg/cgi-bin/make_angular.pl' target='xyz'>LINK</A>\n";

    return $page;

}

#######################
sub sample_js_table {
#######################
    my $self = shift;

    my $block = $self->head();
    $block .= "<div id='DivExample'>Hello World</div>\n";

    my @fields = ('Employee_Name', 'Employee_ID', 'Employee_Status');
    my $table = 'Employee';

    $block .= $self->table(-table=>$table, -fields=>\@fields);
    $block .= $self->script(-table=>$table, -fields=>\@fields);

    return $block;
}


##############
sub head {
##############
    my $self = shift;
    
    my $head =<<ANG;

<style>
table, th , td  {
          border: 1px solid grey;
                  border-collapse: collapse;
                            padding: 5px;
}
table tr:nth-child(odd) {
          background-color: #f1f1f1;
}
table tr:nth-child(even) {
          background-color: #ffffff;
}
</style>

ANG

#    $head .= qq(<script src= "http://ajax.googleapis.com/ajax/libs/angularjs/1.2.26/angular.min.js"></script>);


 return $head;
}

############
sub table {
############
    my $self = shift;
    my %args = filter_input(\@_);
    my $fields = $args{-fields};
    my $table  = $args{-table};

$table .= <<START;

<div ng-app="" ng-controller="customersController"> 

Found = {{response.fields.length}} x {{response.data.length}} 

<!-- http://www.w3schools.com//website/Customers_mysql.php  --> 

START

    $table .= qq(<input type='text' ng-model="searchname" value="ABC"></input>\n);

    $table .= "TABLE<BR><table title='ABC'>\n";

    $table .= "\n\t<th ng-repeat=\"f in response.fields\">{{f}}\n";

    $table .= "\n\t\t<tr ng-repeat=\"v in response.data\">\n";
    foreach my $field (@$fields) {
        if (1) { $table .= "<td>{{v.$field}}</td>\n" }
    }

    $table .= "</table>";
    $table .= qq("<p>FB: <span>{{ searchname }} : {{ searchname.length }}</span>\n);

    $table .= qq(<p>Number of characters left: <span ng-bind="left()"></span></p>);
    $table .= qq(<p>Right: <span ng-model="upd"></span></p>);
    $table .= qq(<p><button ng_click="extra({{ searchname }})">Research1</button>);
    $table .= qq(<p><button onclick="alert('ok')">Research2</button>);

    $table .= "</div>\n";

    return $table;

}

#############
sub script {
############
    my $self = shift;
    my %args = filter_input(\@_);
    my $fields = $args{-fields};
    my $table  = $args{-table};
    my $condition = $args{-condition};

    my $field_list = join ',', @$fields;

    my $condition = "Employee_Name like 'T%'";
    #my $url = qq(http://limsdev02.bcgsc.ca/SDB_rg/cgi-bin/get_data.pl?Table=$table&Fields=$field_list&Condition=$condition);
    my $url = qq(http://limsdev02.bcgsc.ca/SDB_rg/cgi-bin/searchDB.pl?Table=$table&Fields=$field_list&JSON=1);

    print "<HR>TABLE: $table;<BR> FIELDS: $field_list; <BR>CONDITION: $condition<BR><HR>";

return <<SCRIPT;

<script>
function customersController(\$scope,\$http) {
    \$http.get("$url&Condition=Employee_ID<10")
    .success(function(response) {\$scope.response = response;});
    
    \$scope.left  = function() {return 100 - \$scope.searchname.length;};
    
    \$scope.extra  = function( name ) {  \$http.get("$url&Condition=Employee_ID<name.length").success(function(response) { \$scope.upd = 'xyz';}); };
}
</script>
 
SCRIPT

}

############
sub table2 {
############

return <<TABLE;

<div ng-app="" ng-controller="customersController"> 

<!-- http://www.w3schools.com//website/Customers_mysql.php  --> 
<div>
<table>
  <tr> <td>Name</td> <td>Country</td> </tr>
  <tr ng-repeat="x in names">
    <td>{{ x.Name }}</td>
    <td>{{ x.Country }}</td>
  </tr>
</table>
</div>
</div>

TABLE

}

#############
sub script2 {
############

return <<SCRIPT;

<script>
function customersController(\$scope,\$http) {
    \$http.get("http://limsdev02.bcgsc.ca/SDB_py/cgi-bin/get_data.py")
    .success(function(response) {\$scope.names = response;});
}
</script>
SCRIPT

}

##############
sub bootply {
##############
    my $self = shift;
    
    
my $page = "BOOTPLY";

=begin

<!DOCTYPE html>
<html lang='en'>
    <head>
        <meta http-equiv='content-type' content='text/html; charset=UTF-8'> 
        <meta charset='utf-8'>
        <title>Bootply.com - Bootply Bootstrap Preview</title>
        <meta name='generator' content='Bootply' />
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <link href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css" rel="stylesheet">
        
        <!--[if lt IE 9]>
          <script src="//html5shim.googlecode.com/svn/trunk/html5.js"></script>
        <![endif]-->
        <link rel="shortcut icon" href="/bootstrap/img/favicon.ico">
        <link rel="apple-touch-icon" href="/bootstrap/img/apple-touch-icon.png">
        <link rel="apple-touch-icon" sizes="72x72" href="/bootstrap/img/apple-touch-icon-72x72.png">
        <link rel="apple-touch-icon" sizes="114x114" href="/bootstrap/img/apple-touch-icon-114x114.png">










        <!-- CSS code from Bootply.com editor -->
        
        <style type="text/css">

html,
body \{
  height: 100%;
\}

\#wrap \{
  min-height: 100%;
  height: auto !important;
  height: 100%;
  margin: 0 auto -60px;
  padding: 0 0 60px;
\}

\#footer {
  height: 60px;
  background-color: #f5f5f5;
}

\#wrap > .container {
  padding: 60px 15px 0;
}
.container .credit {
  margin: 20px 0;
}

\#footer > .container {
  padding-left: 15px;
  padding-right: 15px;
}

code {
  font-size: 80%;
}
        </style>
    </head>
    
    <!-- HTML code from Bootply.com editor -->
    
    <body  >
        
        <!-- Wrap all page content here -->
<div id="wrap">
  
  <!-- Fixed navbar -->
  <div class="navbar navbar-default navbar-fixed-top">
    <div class="container">
      <div class="navbar-header">
        <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
        </button>
        <a class="navbar-brand" href="#">UTM</a>
        <h3 align=center>Title</h3>
      </div>
      <div class="collapse navbar-collapse">
        <ul class="nav navbar-nav">
          <li class="active"><a href="#">Home</a></li>
          <li><a href="#about">About</a></li>
          <li><a href="#contact">Contact</a></li>
          <li class="dropdown">
            <a href="#" class="dropdown-toggle" data-toggle="dropdown">Dropdown <b class="caret"></b></a>
            <ul class="dropdown-menu">
              <li><a href="#">Action</a></li>
              <li><a href="#">Another action</a></li>
              <li><a href="#">Something else here</a></li>
              <li class="divider"></li>
              <li class="dropdown-header">Nav header</li>
              <li><a href="#">Separated link</a></li>
              <li><a href="#">One more separated link</a></li>
            </ul>
          </li>
        </ul>
      </div><!--/.nav-collapse -->
    </div>
  </div>
  
  <!-- Begin page content -->
  <div class="container">
    <div class="page-header">
      <h1>Sticky footer with fixed navbar</h1>
    </div>
    <p class="lead">Pin a fixed-height footer to the bottom of the viewport in desktop browsers with this custom HTML and CSS. A fixed navbar has been added within <code>#wrap</code> with <code>padding-top: 60px;</code> on the <code>.container</code>.</p>
    <p>Back to <a href="../sticky-footer">the default sticky footer</a> minus the navbar.</p>
  </div>
</div>

<div id="footer">
  <div class="container">
    <p class="text-muted credit">Example courtesy <a href="http://martinbean.co.uk">Martin Bean</a> and <a href="http://ryanfait.com/sticky-footer/">Ryan Fait</a>.</p>
  </div>
</div>

        
        <script type='text/javascript' src="//ajax.googleapis.com/ajax/libs/jquery/2.0.2/jquery.min.js"></script>


        <script type='text/javascript' src="//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>

        
        <!-- JavaScript jQuery code from Bootply.com editor  -->
        
        <script type='text/javascript'>
        
        \$(document).ready(function() {
        
            
        
        });
        
        </script>
        
        <script>
          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
          ga('create', 'UA-40413119-1', 'bootply.com');
          ga('send', 'pageview');
        </script>
        
    </body>
</html>

BOOTPLY

=cut

return $page;
}

################
sub standard {
################
    my $self = shift;

my $page =<<STANDARD;

<!-- Wrap all page content here -->
<div id="wrap">
  
  <!-- Fixed navbar -->
  <div class="navbar navbar-default navbar-fixed-top">
    <div class="container">
      <div class="navbar-header">
        <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
        </button>
        <a class="navbar-brand" href="#">Project name</a>
      </div>
      <div class="collapse navbar-collapse">
        <ul class="nav navbar-nav">
          <li class="active"><a href="#">Home</a></li>
          <li><a href="#about">About</a></li>
          <li><a href="#contact">Contact</a></li>
          <li class="dropdown">
            <a href="#" class="dropdown-toggle" data-toggle="dropdown">Dropdown <b class="caret"></b></a>
            <ul class="dropdown-menu">
              <li><a href="#">Action</a></li>
              <li><a href="#">Another action</a></li>
              <li><a href="#">Something else here</a></li>
              <li class="divider"></li>
              <li class="dropdown-header">Nav header</li>
              <li><a href="#">Separated link</a></li>
              <li><a href="#">One more separated link</a></li>
            </ul>
          </li>
        </ul>
      </div><!--/.nav-collapse -->
    </div>
  </div>
  
  <!-- Begin page content -->
  <div class="container">
    <div class="page-header">
      <h1>Sticky footer with fixed navbar</h1>
    </div>
    <p class="lead">Pin a fixed-height footer to the bottom of the viewport in desktop browsers with this custom HTML and CSS. A fixed navbar has been added within <code>#wrap</code> with <code>padding-top: 60px;</code> on the <code>.container</code>.</p>
    <p>Back to <a href="../sticky-footer">the default sticky footer</a> minus the navbar.</p>
  </div>
</div>

<div id="footer">
  <div class="container">
    <p class="text-muted credit">Example courtesy <a href="http://martinbean.co.uk">Martin Bean</a> and <a href="http://ryanfait.com/sticky-footer/">Ryan Fait</a>.</p>
  </div>
</div>

STANDARD
 
   return $page;
} 

###################
sub test_upload {
###################
    my $self = shift;

    return $self->modal();
    
    my $upload =<<UPLOAD;
    
    <form name="myForm">
      	<fieldset><legend>Upload on form submit</legend>
    	    Username: <input type="text" name="userName" ng-model="username" size="48" required=""> 
    	      			<i ng-show="myForm.userName.\$error.required">*required</i><br>
    	    Profile Picture: <input type="file" ng-file-select="" ng-model="picFile" name="file" accept="image/*" ng-file-change="generateThumb(picFile[0], \$files)" required="">
    	<i ng-show="myForm.file.\$error.required">*required</i>
    	  	<br>

    		<button ng-disabled="!myForm.\$valid" ng-click="uploadPic(picFile)">Submit</button>
    	    <img ng-show="picFile[0].dataUrl != null" ng-src="{{picFile[0].dataUrl}}" class="thumb">
    		<span class="progress" ng-show="picFile[0].progress >= 0">		
    			<div style="width:{{picFile[0].progress}}%" ng-bind="picFile[0].progress + '%'" class="ng-binding"></div>
    		</span>	
    		<span ng-show="picFile[0].result">Upload Successful</span>
      	</fieldset>
    	<br>
    </form>
    <fieldset><legend>Upload right away</legend>
    	<div class="up-buttons">
    		<div ng-file-select="" ng-model="files" class="upload-button" ng-file-change="upload(files)" ng-multiple="false" ng-accept="'image/*,application/pdf'" tabindex="0">Attach an Image or PDF</div><br>
    		<button ng-file-select="" ng-model="files" ng-file-change="upload(files)" ng-multiple="true">Attach Any File</button>
    	</div>
    	<div ng-file-drop="" ng-model="files" class="drop-box" drag-over-class="{accept:'dragover', reject:'dragover-err', delay:100}" ng-multiple="true" allow-dir="true" accept="image/*,*pdf" ng-file-change="upload(files)">
    			Drop Images or PDFs<div>here</div>
    	</div>
    	<div ng-no-file-drop="" class="drop-box">File Farg&amp;Drop not supported on your browser</div>
    </fieldset>
    <br>

UPLOAD

}

#################
sub modal {
#################
    my $self = shift;
    
my $modal =<<MODAL;

    <body ng-controller="MainCtrl">
            <div class="bg"></div>

                    <div class="header">
                                <a class="github-link" href="https://github.com/likeastore/ngDialog">Star on GitHub</a>
                                            <h1>ngDialog</h1>
                                                        <div class="desc">
                                                                        Modals and popups provider for <a href="http://angularjs.org" target="_blank">Angular.js</a> applications. No dependencies. Highly customizable.
                                                                                    </div>
                                                                                                <div class="buttons">
                                                                                                                <a href="#" ng-click="open()" class="demo">Demo</a>
                                                                                                                                <a href="https://github.com/likeastore/ngDialog#api" class="docs">? Docs</a>
                                                                                                                                            </div>
                                                                                                                                                    </div>

                                                                                                                                                            <div class="hr"></div>

                                                                                                                                                                    <div class="socials">
                                                                                                                                                                                <a href="https://twitter.com/share" class="twitter-share-button" data-via="likeastore" data-related="likeastore">Tweet</a>
                                                                                                                                                                                            <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>
                                                                                                                                                                                                        <iframe src="http://ghbtns.com/github-btn.html?user=likeastore&repo=ngDialog&type=watch&count=true"
                                                                                                                                                                                                                  allowtransparency="true" frameborder="0" scrolling="0" width="90" height="20"></iframe>
                                                                                                                                                                                                                            <a href="https://twitter.com/likeastore" class="twitter-follow-button" data-show-count="false">Follow \@likeastore</a>
                                                                                                                                                                                                                                        <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>
                                                                                                                                                                                                                                                </div>

                                                                                                                                                                                                                                                        <div class="footer">
                                                                                                                                                                                                                                                                    Created by <a href="https://likeastore.com" class="logo">likeastore.</a>
                                                                                                                                                                                                                                                                            </div>

                                                                                                                                                                                                                                                                                    <script type="text/ng-template" id="firstDialog">
                                                                                                                                                                                                                                                                                                <div class="ngdialog-message">
                                                                                                                                                                                                                                                                                                                <h2>Native Angular.js solution</h2>
                                                                                                                                                                                                                                                                                                                                <div>With ngDialog you don't need jQuery or Bootstrap to create dialogs for <code>ng-app:</code></div>
                                                                                                                                                                                                                                                                                                                                                <ul class="mt">
                                                                                                                                                                                                                                                                                                                                                                    <li>Use it in controllers, factories or directives</li>
                                                                                                                                                                                                                                                                                                                                                                                        <li>Create your own directives</li>
                                                                                                                                                                                                                                                                                                                                                                                                            <li>Style all UI and templates</li>
                                                                                                                                                                                                                                                                                                                                                                                                                                <li>Configure themes</li>
                                                                                                                                                                                                                                                                                                                                                                                                                                                    <li>Add animations and effects</li>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </ul>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    <div class="mt">Module is shipped with both <code>ngDialog</code> service and default directive.</div>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                </div>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            <div class="ngdialog-buttons mt">
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            <button type="button" class="ngdialog-button ngdialog-button-primary" ng-click="next()">?</button>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        </div>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                </script>

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <script type="text/ng-template" id="secondDialog">
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    <div class="ngdialog-message">
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    <h2>And even more!</h2>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    <ul class="mt">
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <li>Load your templates as strings, ng-template tags or html partials</li>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            <li>ngDialog.js is < 2kb when minified!</li>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                <li>It has simple, extendable and elegant API ;)</li>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                </ul>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                <div class="mt">Spread a word about it:</div>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            </div>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <div class="mt">
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <a href="http://twitter.com/home?status=ngDialog.js - modal windows and popups provider for Angular.js applications, via \@likeastore!+http://likeastore.github.io/ngDialog/" class="action-btn" ng-like>Tweet</a>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <a href="http://www.facebook.com/share.php?u=http://likeastore.github.io/ngDialog" class="action-btn" ng-like>Like</a>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <a href="https://github.com/likeastore/ngDialog#ngdialog" class="action-btn read" target="_blank">Read docs</a>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    </div>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            </script>

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    <script src="./bower_components/angular/angular.min.js"></script>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            <script src="./js/ngDialog.min.js"></script>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    <script>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                var app = angular.module('exampleDialog', ['ngDialog']);

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            app.controller('MainCtrl', function (\$scope, ngDialog) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                \$scope.open = function () {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ngDialog.open({
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    template: 'firstDialog',
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            controller: 'FirstDialogCtrl',
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    className: 'ngdialog-theme-default ngdialog-theme-custom'
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        });
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        };
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    });

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        app.controller('FirstDialogCtrl', function (\$scope, ngDialog) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            \$scope.next = function () {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ngDialog.close('ngdialog1');
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ngDialog.open({
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    template: 'secondDialog',
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            className: 'ngdialog-theme-flat ngdialog-theme-custom'
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                });
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        };
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    });

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    app.directive('ngLike', function () {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        return {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                restrict: 'E',
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    link: function (scope, elem, attrs) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                elem.on('click', function () {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                window.open(attr.href, 'Share', 'width=600,height=400,resizable=yes');
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        });
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    };
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                });
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            </script>
    
MODAL

return $modal;

}

1;
