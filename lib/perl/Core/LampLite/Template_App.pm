###################################################################################################################################
# LampLite::Template_App.pm
#
#
#
#
###################################################################################################################################
package LampLite::Template_App;

use base RGTools::Base_App;

use strict;

## RG Tools
use RGTools::RGIO;

use LampLite::Template;
use LampLite::Template_Views;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Log In');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
            'Test' => 'test',
        }
    );
    
    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

###########
sub test {
###########
    my $self = shift;
    my $dbc = $self->dbc();

    my $Model = new LampLite::Template();
    return $Model->View->std_page();

}

##############
sub AJS_head {
##############
    my $self = shift;

    return <<ANG;

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
<script src= "http://ajax.googleapis.com/ajax/libs/angularjs/1.2.26/angular.min.js"></script>

ANG

}

############
sub AJS_table {
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

    $table .= "TABLE<BR><table id='myTable' class='table table-striped' title='ABC'>\n";

    $table .= "\n\t<th ng-repeat=\"f in response.fields\">{{f}}\n";

    $table .= "\n\t\t<tr ng-repeat=\"v in response.data\">\n";
    
    foreach my $field (@$fields) {
        ## if {{v.Employee_ID}} <= {{ searchname.length }}
        if (1) { $table .= "<td>{{v.$field}}</td>\n" }
    }

    $table .= "</table>";
    $table .= qq("<p>FB: <span>{{ searchname }} : {{ searchname.length }}</span>\n);

    $table .= qq(<p>Number of characters left: <span ng-bind="left()"></span></p>);
    $table .= qq(<p>Right: <span ng-model="upd"></span></p>);
    $table .= qq(<p><button ng_click="extra({{ searchname }})">Research1</button>);
    $table .= qq(<p><button onclick="alert('ok')">Research2</button>);

$table .=<<dataTable;
    
    <script>    
    \$(document).ready(function(){
        \$('#myTable').dataTable();
    });
    </script>

dataTable

$table .= "</div>\n";

    return $table;
}

#########################
sub table_to_bootstrap {
#########################
    my $self = shift;
    my $table = shift;
    
    $table =~s/<Table /<Div class='table'/igxms;
    $table =~s/<TH /<Div class='table'/igxms;
    $table =~s/<Table /<Div class='table'/igxms;
    $table =~s/<Table /<Div class='table'/igxms;
}

#############
sub AJS_script {
#############
    my $self = shift;
    my %args = filter_input(\@_);
    my $fields = $args{-fields};
    my $table  = $args{-table};
    my $condition = $args{-condition};

    my $field_list = join ',', @$fields;

    my $condition = "Employee_Name like 'T%'";
    #my $url = qq(http://limsdev02.bcgsc.ca/SDB_rg/cgi-bin/get_data.pl?Table=$table&Fields=$field_list&Condition=$condition);
    my $url = qq(http://limsdev02.bcgsc.ca/SDB_rg/cgi-bin/searchDB.pl?Table=$table&Fields=$field_list&JSON=1);

    print "T: $table; F: $field_list; C: $condition<BR>";

    return <<SCRIPT;

<script>
function customersController(\$scope,\$http) {
    \$http.get("$url&Condition=Employee_ID<10")
    .success(function(response) {\$scope.response = response;});
    
    \$scope.left  = function() {return 100 - \$scope.searchname.length;};
    
    \$scope.extra  = function( name ) { alert('less than ' + name.length); \$http.get("$url&Condition=Employee_ID<name.length").success(function(response) {\$scope.upd = 'xyz';}); };
}
</script>

<script>
  function document.onready();
  \$(document).ready( function()  {
      /* Dynamic load...  */
      document.getElementById('DivExample').innerHTML = "<p>Hello</p>"
  }
  );
</script>
 
SCRIPT

}

###################
sub static_table {
###################
    my $self = shift;
    
    return <<STATIC;
    <div class="table-responsive">
    <table id="myTable" class="display table" width="100%">  
            <thead>  
              <tr>  
                <th>ENO</th>  
                <th>EMPName</th>  
                <th>Country</th>  
                <th>Salary</th>  
              </tr>  
            </thead>  
            <tbody>  
              <tr>  
                <td>001</td>  
                <td>Anusha</td>  
                <td>India</td>  
                <td>10000</td>  
              </tr>  
              <tr>  
                <td>002</td>  
                <td>Charles</td>  
                <td>United Kingdom</td>  
                <td>28000</td>  
              </tr>  
              <tr>  
                <td>003</td>  
                <td>Sravani</td>  
                <td>Australia</td>  
                <td>7000</td>  
              </tr>  
               <tr>  
                <td>004</td>  
                <td>Amar</td>  
                <td>India</td>  
                <td>18000</td>  
              </tr>  
              <tr>  
                <td>005</td>  
                <td>Lakshmi</td>  
                <td>India</td>  
                <td>12000</td>  
              </tr>  
              <tr>  
                <td>006</td>  
                <td>James</td>  
                <td>Canada</td>  
                <td>50000</td>  
              </tr>  

               <tr>  
                <td>007</td>  
                <td>Ronald</td>  
                <td>US</td>  
                <td>75000</td>  
              </tr>  
              <tr>  
                <td>008</td>  
                <td>Mike</td>  
                <td>Belgium</td>  
                <td>100000</td>  
              </tr>  
              <tr>  
                <td>009</td>  
                <td>Andrew</td>  
                <td>Argentina</td>  
                <td>45000</td>  
              </tr>  

                <tr>  
                <td>010</td>  
                <td>Stephen</td>  
                <td>Austria</td>  
                <td>30000</td>  
              </tr>  
              <tr>  
                <td>011</td>  
                <td>Sara</td>  
                <td>China</td>  
                <td>750000</td>  
              </tr>  
              <tr>  
                <td>012</td>  
                <td>JonRoot</td>  
                <td>Argentina</td>  
                <td>65000</td>  
              </tr>  
            </tbody>  
          </table>
        </div>
        
        <script>
        \$(document).ready(function(){
            \$('#myTable').dataTable();
        });
        </script>
        
STATIC
    
}
1;
