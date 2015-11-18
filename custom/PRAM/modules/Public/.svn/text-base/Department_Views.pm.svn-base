###################################################################################################################################
# Public::Department_View.pm
#
#
#
#
###################################################################################################################################
package PRAM::Public::Department_Views;

use base PRAM::Department_Views;

use strict;

## RG Tools
use RGTools::RGIO;
use SDB::HTML;
use LampLite::Form;

#
# Usage: 
#   my $view = $self->display(-data=>$data);
#
# Returns: Formatted view for the raw data
###########################
sub display {
###########################
    my $self = shift;
    my %args = filter_input(\@_,-args=>'data');
    my $data = $args{-data};
    
    ## Format the raw data into a viewable form (ie HTML)
    my $view;
    
    return $view;
}

################
sub home_page {
################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->{dbc};        

    my $page = section_heading("New Purchase Request");
 
    my $Form = new LampLite::Form(-dbc=>$dbc);
    
    my $requester = $dbc->config('user'); ## $Form->View->prompt(-table=>'Request', -field=>'FKRequester_User__ID');
    my $request_date = $Form->View->prompt(-table=>'Request', -field=>'Request_Date', -class=>'');
    my $cost_centre = $Form->View->prompt(-table=>'Request', -field=>'FK_Cost_Centre__ID');
    my $item = $Form->View->prompt(-table=>'Item_Request', -field=>'FK_Item__ID', -id=>'Selected_Item');
    my $notes = $Form->View->prompt(-table=>'Item_Request', -field=>'Notes', -style=>'width:100%');

    my $qty = $Form->View->prompt(-table=>'Item_Request', -field=>'Unit_Qty', -placeholder=>'-- # --');
    my $cost = $Form->View->prompt(-table=>'Item_Request', -field=>'Unit_Cost', -placeholder=>'-- $ --');

    my $new_cost = $Form->View->prompt(-table=>'Item', -field=>'Item_Cost', -placeholder=>'-- Cost --');
    my $new_category = $Form->View->prompt(-table=>'Item', -field=>'FK_Item_Category__ID');
    my $new_name = $Form->View->prompt(-table=>'Item', -field=>'Item_Name', -type=>'text');
    my $new_vendor = $Form->View->prompt(-table=>'Item', -field=>'FK_Vendor__ID');
    my $new_catalog = $Form->View->prompt(-table=>'Item', -field=>'Item_Catalog');

    my $query = "SELECT * FROM Item LEFT JOIN Item_Category ON FK_Item_Category__ID=Item_Category_ID WHERE Item_Category_ID LIKE '<Item_Category>' AND Item_Name LIKE '<Item_Name>' AND Item_Catalog LIKE '<Item_Catalog>' LIMIT 4";
    my $replace = "Item_Category,Item_Name,Item_Catalog";
#        my $Form = new LampLite::Form(-dbc=>$dbc);
#        $page .= $Form->View->prompt(-table=>'Item_Request', -field=>'FK_Item__ID', -id=>'Item_Name');
#        $page .= qq(<input class='form-control' id='Item_Name' type='text' ng-model='itemName' data-autocomplete="http://limsdemo01.dmz.bcgsc.ca:3000/items/search/"> </input>\n);
#         <input class='form-control' id='Item_Name' type='text' ng-model='itemName' data-autocomplete="http://limsdemo01.dmz.bcgsc.ca:3000/items/search/"> </input> 
   
    $page .=<<TEMPLATE;

    <div ng-app="requestApp">
     <div ng-controller="reqController">
       <h1> New Request </h1>
       <table class='table'>
         <tr>
           <td >Requested By:</td> 
           <td width=80%>$requester</td>
         </tr>
         <tr>
            <td>Requested:</td> 
            <td>$request_date</td>
         </tr>
         <tr>
            <td>Cost Centre:</td>
            <td>$cost_centre</td>
         </tr>
         <tr>
            <td>Requested Items:</td>
            <td>{{ items.length }}</td>
         </tr>
       </table>
       <hr>
       <form ng-submit="addItem()">
         <table class = 'table table-bordered table-hover' style='width:100%'>
           <thead>
             <tr>
               <th style='width:100px'> Qty </th> 
               <th style='width:100px'> Cost </th> 
               <th > Item </th>
               <th > Vendor </th>
               <th > Catalog </th>
               <th> Catalog </th>
             </tr>
             </thead>
             <tr ng-repeat="item in items">
               <td>$qty</td>
               <td>$cost</td>
               <td> {{ item.name }} </td>
               <td> {{ item.vendor }} </td>
               <td> {{ item.catalog }} </td>
             </tr>
           </table>
         <input type='hidden' id='search_records' value='Item'> </input>
         <input type='hidden' id='display_records' value='Item_Name,Item_Catalog,Item_Cost'> </input>
         <input type='hidden' id='set_records' value='FK_Item__ID,Unit_Cost,Unit_Qty'> </input>
         <input type='hidden' value='Current User' ng-model='userName'> </input>
         <hr>
         Existing Item: $item
         <button type='submit'> Add </button>
         <hr>
         $notes
      </form>
      New Item:
      <form ng-submit="searchButton()">
        Query:
        <input id='searchQuery' type='hidden' class='form-control' value="$query">
        <input id='replaceQuery' type='hidden' class='form-control' value="$replace">
        <P>
        <table class='table.table-bordered' style='width:100%'>
         <thead>
           <tr>
             <th> </th>
             <th style='width:100px'> Unit_Cost </th> 
             <th > Category </th> 
             <th > Item </th>
             <th > Vendor </th>
             <th > Catalog </th>
           </tr>
          </thead>
          <tr>
            <td>  <button type='submit'> Search </button> </td>
            <td>$new_cost</td>
            <td>$new_category</td>
            <td>$new_name</td>
            <td>$new_vendor</td>
            <td>$new_catalog</td>
          </tr>
        </table>
        
      </form>
      
      Test:
      <form>
        <button type='submit' id='executeAjax'> run AJAX via button id: executeAjax </button>
      </form>
      <form>
        <button type='submit' id='runAjax' onclick="runAjax('hello');"> run runAjax from onclick </button>
      </form>
      <form ng-submit='ajaxQuery()'>
        <button type='submit' id='angularAjax'> run Ajax via Angular method: ajaxQuery </button>
        
      </form>
      
    </div>
</div>
<P>
<div>
  Query: <span id='query'></span>
</div>
<P>
<div>
  Message: <span id='message'></span>
</div>

TEMPLATE

    return $page;
}

1;
