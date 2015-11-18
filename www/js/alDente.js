//Builds the add on parameters for the current form element name/value pair.
function buildAddOns(f,e_name,e_value,extra) {
	if (e_value == '-') return '-'; //In this case do not build the addons.
	var addons;
	switch(e_name) {
		case 'Search_Edit':
			addons = '&Search+for=1&Table=' + e_value + '&Multi-Record=' + getValue(f,'Multi-Record');
			break;
		case 'Create_New':
			switch(e_value) {
				case 'Library_Plate':
					addons = '&New+Library_Plate=1&New+Plate+Type=Original&Require=FK_Rack__ID,FK_Plate_Format__ID';
					break;
				case 'Tube':
					addons = '&New+Tube=1&New+Plate+Type=Original&Require=FK_Rack__ID,FK_Plate_Format__ID';
					break;				
				case 'Primer':
				case 'Buffer': 
				case 'Matrix':				
				case 'Reagent':
					addons = '&New+Entry=New+Reagent&Solution_Type=' + e_value;
					break;
				case 'Library':
					addons = '&Create+New+Library=1';
					break;				
				case 'Source':
					addons = '&Create+New+Source=1';
					break;
				default:
					addons = '&New+Entry=New+' + e_value;
			}
			break;
		case 'Sequence_Requests':
			if (e_value == 'Remove Sequence Request') {
				addons = '&' + e_value + '=1&Search+String=' + getValue(f,'Search String') + '&All+Users=' + getValue(f,'All Users');
			}
			else {
				addons = '&' + e_value + '=1&Search+String=' + getValue(f,'Search String') + '&All+Users=' + getValue(f,'All Users');
			}
			break;
		case 'Edit_Stock_Notification_Settings':
			addons = '&Edit+Table=' + e_value;
			break;
		case 'Plates':
			if (e_value == 'View Ancestry') {
				if (getValue(f,'Plates_List')) {addons = '&Seek+Plate=' + getValue(f,'Plates_List') + '&' + e_value + '=1';}
				else {alert('Please scan plate(s) first.'); addons = '-'; }
			}
			else if (e_value == 'Find Plates') {
				addons = '&Find_Plates=Find+Plates&Equipment_Name=&Project_Name=&Library=&Group_By=Library&Rack_Conditions=%27%2B4+degrees%27&Rack_Conditions=%27-20+degrees%27&Rack_Conditions=%27-80+degrees%27&Rack_Conditions=%27Room+Temperature%27';
			}
			else if (e_value == 'Plate History') {
				if (getValue(f,'Plates_List')) {addons = '&Barcode=' + getValue(f,'Plates_List') + '&' + e_value + '=Plate+History&Generations=' + getValue(f,'Generations');}
				else {alert('Please scan plate(s) first.'); addons = '-'; }
			}
			else if (e_value == 'Plate Set') {
				if (getValue(f,'Plates_List')) {addons = '&Grab+Plate+Set=1&Plate+Set+Number=' + getValue(f,'Plates_List');}
				else {alert('Please enter a plate set number first.'); addons = '-'; }
			}
			else if (e_value == 'Create New Plate') {
				if (getValue(f,'Library')) {addons = '&New+Plate=1&Use+Library=' + getValue(f,'Library');}
				else { alert('Please enter a library first.'); addons = '-'; }
			<!--	else {addons = '&New+Plate=1&New+Plate+Type=Original&Require=FK_Rack__ID,FK_Plate_Format__ID';	-->
			}
			else if (e_value == 'Create New Tube') {
				if (getValue(f,'Library')) {addons = '&New+Tube=1&Use+Library=' + getValue(f,'Library');}
				else { alert('Please enter a library first.'); addons = '-'; }
			<!--	else {addons = '&New+Plate=1&New+Plate+Type=Original&Require=FK_Rack__ID,FK_Plate_Format__ID';	-->
			}
			else if (e_value == 'Search Plates') {
				addons =  '&Search+for=1&Table=Plate';
			}
			else {
				if (getValue(f,'Plates_List')) {addons = '&Barcode=' + getValue(f,'Plates_List') + '&' + e_value + '=1';}
				else {alert('Please scan plate(s) first.'); addons = '-'; }
			}
			break;
		case 'Equipment':
			if (e_value == 'Search Equipment') {
				addons = '&Search+for=1&Table=Equipment';
			}
			else {
				addons = '&Barcode=' + getValue(f,'Equipment_List') + '&' + e_value + '=1';
			}
			break;
		case 'Solution':
			switch(e_value) {
				case 'Find Stock':
					if (getValue(f,'Solution_List')) {addons = '&Barcode=' + getValue(f,'Solution_List') + '&Group='+getValue(f,'Group')+ '&' + e_value + '=1';}
					else {alert('Please scan solution first.'); addons = '-'; }
					break;
				case 'Empty':
					addons = '&Barcode=' + getValue(f,'Solution_List') + '&Empty+Date=' + getValue(f,'Empty_Open_Date') + '&' + e_value + '=1';
					break;
				case 'Open':
					addons = '&Barcode=' + getValue(f,'Solution_List') + '&Open+Date=' + getValue(f,'Empty_Open_Date') + '&' + e_value + '=1';
					break;
				case 'Search Solution':
					addons = '&Search+for=1&Table=Solution';
					break;
				case 'Show Applications':
					addons = '&Reagent+Applications=1&Solution_ID=' + getValue(f,'Solution_List');
					break;
                                default :
                                        alert('Argument Not found');
                                        break;
			}
			break;
		case 'Solution_Search':
			addons = '&Search+String=' + getValue(f,'Search_String') + '&Days+to+Expire=' + getValue(f,'Days_To_Expire') + '&Group='+getValue(f,'Group')+ '&' + e_value + '=1';
			break;
		case 'Library_View':
			switch(e_value) {
				case 'Library':
					addons = '&List+Libraries=1&Verbose=' + getValue(f,'Verbose') + '&Library+Name=' + getValue(f,'Library Name') + '&Library+Type=' + getValue(f,'Library Type') + '&Project+Name=' + getValue(f,'Project Name');
					break;
				case 'LibraryPrimer':
					addons = '&View+LibraryApplication=1&Library+Name=' + getValue(f,'Library Name') + '&Library+Type=' + getValue(f,'Library Type') + '&Project+Name=' + getValue(f,'Project Name') + '&Object_Type=' + 'Primer';
					break;
				case 'LibraryAntibiotic':
					addons = '&View+LibraryApplication=1&Library+Name=' + getValue(f,'Library Name') + '&Library+Type=' + getValue(f,'Library Type') + '&Project+Name=' + getValue(f,'Project Name') + '&Object_Type=' + 'Antibiotic';
					break;
				case 'VectorPrimer':
					addons = '&View+Primers+for+Vectors=1&Library+Name=' + getValue(f,'Library Name') + '&Library+Type=' + getValue(f,'Library Type') + '&Project+Name=' + getValue(f,'Project Name');
					break;
			}
			break;
		case 'Library_Create':
			switch(e_value) {
				case 'Library':
					addons = '&Create+New+Library=Update+Database+with+New+Library&Re-Pool=' + getValue(f,'Re-Pool') + '&Pool_Library=' + getValue(f,'Pool_Library');
					break;
				case 'LibraryPrimer':
					addons = '&LibraryApplication=1&Library+Name=' + getValue(f,'Pool_Library') + '&Library+Type=' + getValue(f,'Library Type') + '&Project+Name=' + getValue(f,'Project Name') +'&Object_Type=' + 'Primer';
					break;
				case 'LibraryAntibiotic':
					addons = '&LibraryApplication=1&Library+Name=' + getValue(f,'Pool_Library') + '&Library+Type=' + getValue(f,'Library Type') + '&Project+Name=' + getValue(f,'Project Name') + '&Object_Type=' + 'Antibiotic';
					break
				case 'LibraryVector_Type':
					addons = '&New+Entry+Table=LibraryVector_Type&New+Entry=Set+Library+Vector';
					break;
				case 'VectorPrimer':
   					addons = '&New+Entry+Table=VectorPrimer&New+Entry=Set+Vector/Primer+direction';
					break;
                                case 'VectorAntibiotic':
                                        addons = '&New+Entry+Table=VectorAntibiotic&New+Entry=Set+Antibiotic+for+Vector';
                                        break;
			}
			break;
		case 'Library_Search_Edit':
			addons = '&Search+for=1&Table=' + e_value + '&Multi-Record=' + getValue(f,'Library_Multi-Record');
			break;
		case 'Project_View':
			addons = '&Info=1&Table=' + e_value;
			break;
		case 'Project_Search_Edit':
			addons = '&Search+for=1&Table=' + e_value + '&Multi-Record=' + getValue(f,'Project_Multi-Record');
			break;
		case 'Project_Create':
		case 'Vector_Primer_Create':
				addons = '&New+Entry=New+' + e_value + '&New+Entry+Table=' + e_value;
				break;
		case 'Vector_Primer_View':
			switch(e_value) {
                                case 'Antibiotic':
				case 'Vector_Type':
				case 'Primer':
					addons = '&List+' + e_value + 's=1';
					break;
				case 'Primer_Customization':
					addons = '&Info=1&Table=' + e_value;
					break;
				case 'Chemistry_Code':
					addons = '&Library+Main=1&List+Chemistry+Options=1';
					break;
			}
			break;
		case 'Vector_Primer_Search_Edit':
			addons = '&Search+for=1&Table=' + e_value + '&Multi-Record=' + getValue(f,'Vector_Primer_Multi-Record');
			break;
		case 'Data_Table':
			var action = getValue(f,'Data_Action');
			if (action == 'Edit+Table') {
				//addons = '&' + action + '=' + e_value;

				addons = '&Search+for=1&Table=' + e_value + '&Multi-Record=1';

				//addons = '&Start_Multitable=1&Table=' + e_value;
			}
			else {
				addons = '&' + action + '=1&Table=' + e_value;
			}
			break;
		case 'Resubmit_Sequencing_Library':
			addons = '&Resubmit_Sequencing_Library=' + getValue(f,'Resubmit_Sequencing_Library') + '&Library_Name=' + getValue(f,'Library_Name') + '&Scanned+ID=' + getValue(f,'Scanned ID') + '&Target=Storable';
			break;
		default:
			addons = '&' + e_value + '=' + e_value;
	}

	if (extra) {addons = addons + extra;}
	return addons;
}
function num_check_box(f, t, n, c, i) {
var total=0;

var initial = parseInt(i);

	
	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
		if ((e.type=='checkbox') ) {		
		    if (e.checked && e.name != c)
           	    {
                  
                  	total = total+1;
           	    }
		}		
	} 
	if (initial){total = total+initial}
	t.value=total;

}

function check_all_boxes(f, t, n, c)
{
        ToggleNamedCheckBoxes(f,t,n);
	var initial;
	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
		if ((e.name=='Num_Filled_Wells') ) {		
		    initial = parseInt(e.value);
		}		
	} 
        num_check_box(f,t,n,c,initial);
}

function set_Band(f,tbl,c)
{
        mynum = 0;
        if (tbl){
	for (i=0;i<tbl.length;++i)
        {
                tbl[i].value = "";
        }
        }
	 


	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
		if ((e.type=='checkbox') ) {		
		    if (e.checked && e.name != c)
           	    {
                  
                  	tbl[mynum++].value = e.value
           	    }
		    else
		    {
			tbl[mynum].value = ""   
		    }
		}		
	} 
}


function AutofillColumn(f,prefix,count){
      for (var i=2; i <= count ; i++) {
        var j = i - 1;
        var last = document.getElementById(prefix + j);
        var current  = document.getElementById(prefix + i);
        if (last.value && !current.value){
            current.value = last.value;
        }
    }
}



function ClearElements(f,list){
    var source_array =list.split(',');
    for (var i=0; i<source_array.length; i++) {
        var temp =  document.getElementById(source_array[i]);
        temp.value = '';
    }
}



function fill_wells(f,id, maxrow,maxcol,list){
	var i;
	var fillby;
	var textelem = document.getElementById(id);
	var wellarray = new Array('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P');

	for(var i=0;i < f.length;i++){
		var e = f.elements[i];
		if (e.type =='radio' && e.name == 'Fill_By' && e.checked){
			fillby = e.value;
		}

	}
	var rowindex;
	
	if (maxrow == 'H') {
		rowindex = 8;
	} else if (maxrow =='P') {
		rowindex = 16;
	}

	// Get the selected wells 
	var selectwells = document.getElementsByName(list);
	var selectedwells = new Array();
	var selectedindex = 0;
	for (var j=0;j < selectwells.length;j++){
		if (selectwells[j].checked){	
			selectedwells[selectedindex] = selectwells[j].value;
	
			selectedindex++;	
		}	
	}
	var well = textelem.id;    // the well being double-clicked
	well.search(/(\w)(\d+)/i);
	var row = RegExp.$1;
       	var col = RegExp.$2;

	var rowbegin;
	var rowend;
	var count_wells = 0;

	for (var k=0;k<wellarray.length; k++){
		if(row == wellarray[k]){
			rowbegin = k;
		}
		if(maxrow ==wellarray[k]){ 
			rowend = k;
		}
	}	

	if (fillby =='by column'){
		var testarray = new Array();
		var index = 0;
		for (var i = 1; i<=maxcol;i++){
			testarray[i] = new Array();
			for (var j = 0; j < rowindex;j++) {
				var key = wellarray[j];
				testarray[i][j] = key + i;			
			}
		
		}			
		for (var i = 0; i<selectedwells.length;i++) {
			var obj = document.getElementById(testarray[col][rowbegin]);
			if(!obj.disabled){
				obj.value = selectedwells[i];
			}
			else{
				i--;
			}
			rowbegin++;
			if (rowbegin >= rowindex) {rowbegin = 0;col++};
		}	

	} else {
		var testarray = new Array();
		var index = 0;
		for (var i = 0; i<rowindex;i++){
			testarray[i] = new Array();
			for (var j = 1; j <= maxcol;j++) {
				var key = wellarray[i];
				testarray[i][j] = key + j;	
			}
		
		}	
		for (var i = 0; i<selectedwells.length;i++) {
			var obj = document.getElementById(testarray[rowbegin][col]);
			if(!obj.disabled){
				obj.value = selectedwells[i];
			}
			else{
				i--;
			}
			col++;
			if (col > maxcol && rowbegin < rowindex) {col = 1; rowbegin++;}
		}
	}
	
}


function fill_single_well(f,id,nowell){
	var textelem = document.getElementById(id);
	var selected_wells = "";
        // go through each element of the form, if the element is a checkbox and it is checked, concat the id
        for (var i=0; i<f.length; i++) {
           var e = f.elements[i];
	   var well_name = ""; 
	   if( nowell )	{ well_name = e.id.replace("Wells",""); }
	   else			{ well_name = e.id.replace("Wells","") + '-' + e.value; }	
           // check if this checkbox is in the current layer
           if (e.type=='checkbox' && e.checked) {
		if (!selected_wells) { selected_wells = well_name; }
		else { selected_wells = selected_wells + ',' + well_name; }
		e.checked = 0;
           }
        }

	textelem.value = selected_wells;
}

// This function is for pooling sources
function fill_single_pool(f,id){
	var textelem = document.getElementById(id);
	var selected_wells = "";

    // go through each element of the form, if the element is a checkbox and it is checked, concat the id and the volume
    for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
       // check if this checkbox is in the current layer
		if (e.type=='checkbox' && e.checked && e.name.match('Wells')) {
			var well_name = e.id.replace("Wells","");
			var amount = document.getElementById("Pool_Amount" + well_name );
			var units = document.getElementById("Pool_Units" + well_name );
			var pool_info = well_name;
			if( amount.value && units.value ) {
				pool_info = pool_info + '[' + amount.value + ' ' + units.value + ']';
			}
			if (!selected_wells) { selected_wells = pool_info; }
			else { selected_wells = selected_wells + ',' + pool_info; }
			
			// reset the checkbox and the volume elements
			e.checked = 0;
			amount.value = '';
			//units.value = '';
        }
    }

	textelem.value = selected_wells;
}

function addPool(tableid,numberpool,button){
	var quantity = jQuery("#" + tableid + " tr").length;
	//alert(numberpool);
	jQuery("#" + numberpool).val(quantity);
	//alert(jQuery("#" + numberpool).html());

	var action_button = jQuery("input[value='"+button+"']");
	//alert(action_button.attr('onclick'));
	//action_button.trigger('click');

	//this will clone the lasttable row.
	var Row = jQuery("#" + tableid + " tr:last");
        var val=Row.find('[name="poolTargetWells"]').attr('value');
        
        var clonedRow = jQuery("#" + tableid + " tr:last").clone(); 

	//get textbox ID
	var textID = clonedRow.find('[name="poolTargetWells"]').attr('id');

	//change textbox ID to a new id
	clonedRow.find('[name="poolTargetWells"]').attr('id', "target" + quantity);

	//update onclick javascript to use the new id
        clonedRow.find('[name="poolTargetWells"]').attr('onclick', clonedRow.find('[name="poolTargetWells"]').attr("onclick").replace(textID, "target" + quantity));

	//update action button validating javascript
	action_button.attr('onclick',  action_button.attr('onclick') + " if (!getElementValue(document.thisform,\'target" + quantity + "\',1)) {alert(\'Missing target " + quantity + "\'); return false;} ");
	
	//blank out select textbox and select options
	clonedRow.find('[name="FK_Library__Name"]').val('');
	clonedRow.find('[name="FK_Library__Name Choice"]').empty().append(new Option('--Enter string above to search list--',''));
	
	//replace select textbox id
	var re = new RegExp('FK_Library__Name', 'g');
	var id = clonedRow.find('[name="FK_Library__Name"]').attr('id');
	clonedRow.find('[name="FK_Library__Name"]').attr('id', id.replace(re,"FK_Library__Name" + quantity));
	    
        //update action button validating javascript
	action_button.attr('onclick',  action_button.attr('onclick') + " if (!getElementValue(document.thisform,\'" + id.replace(re,"FK_Library__Name" + quantity) + "\',1)) {alert(\'Missing Library Name " + quantity + "\'); return false;} ");

	//replace select option id
	var id2 = clonedRow.find('[name="FK_Library__Name Choice"]').attr('id');
        if (id2) {
	    clonedRow.find('[name="FK_Library__Name Choice"]').attr('id', id2.replace(re,"FK_Library__Name" + quantity));
        
	    //replace indicator id
	    var id = clonedRow.find('[class="ajax_indicator"]').attr('id');
	    clonedRow.find('[class="ajax_indicator"]').attr('id', id.replace(re,"FK_Library__Name" + quantity));
        }

	//add the row back to the table
	jQuery("#" + tableid ).append(clonedRow);
        
        //trigger the onclick for the textbox
	clonedRow.find('[name="poolTargetWells"]').trigger('click');
       
}

function addPoolBatch(tableid,numberpool,button){
	// check if the For_Update text box has value. If yes, add a new row by copying; if not, just update the text box
	var last_pool_textbox = jQuery("#" + tableid + " input").filter(function() {
		return jQuery(this).attr('class') == "For_Update";
	}).filter(":last");
	var not_empty = last_pool_textbox.val();
	if( !not_empty ) {
		// update Next_Batch_ID
		var batch_id = jQuery("#Next_Batch_ID").val();
		var next_batch_id = Number(batch_id) + 1;
		//alert( "current batch ID " + batch_id + "; next batch ID " + next_batch_id );
		jQuery("#Next_Batch_ID").val( next_batch_id );
		
        //trigger the onclick for last the textbox
		last_pool_textbox.trigger('click');
		return;
	}
	
	// last pool not empty
	var tableRow = jQuery("#" + tableid + " input").filter(function() {
		return jQuery(this).attr('class') == "For_Update";
	}).closest("tr").filter(":last");
	//alert( tableRow.length );


    var clonedRow = tableRow.clone(); 
	var tableColumn = clonedRow.find("td:contains('Pool Configuration')").first();
	tableColumn.html('<span>Pooling Conflicts Not Determined</span>');

	//get textbox ID
	var pool_textbox = clonedRow.find('[class="For_Update"]');
	var textID = pool_textbox.attr('id');
	//change textbox name and ID
	var batch_id = jQuery("#Next_Batch_ID").val();
	pool_textbox.attr('id', "target" + batch_id);
	pool_textbox.attr('name', "poolTargetWells." + batch_id);
	// update Next_Batch_ID
	var next_batch_id = Number(batch_id) + 1;
	jQuery("#Next_Batch_ID").val( next_batch_id );

	// update the pool ID in the label
	clonedRow.find('#Pool_Label').text( "Pool " + batch_id );
	
	//remove the copied value
	pool_textbox.attr('value', "");
	
	//update onclick javascript to use the new id
        pool_textbox.attr('onclick', pool_textbox.attr("onclick").replace(textID, "target" + batch_id));

	//update action button validating javascript
	var action_button = jQuery("input[value='"+button+"']");
	//alert(action_button.attr('onclick'));
	//action_button.trigger('click');
	action_button.attr('onclick',  action_button.attr('onclick') + " if (!getElementValue(document.thisform,\'target" + batch_id + "\',1)) {alert(\'Missing target " + batch_id + "\'); return false;} ");

	//add the row back to the table
	jQuery("#" + tableid ).append(clonedRow);

        //trigger the onclick for the textbox
	pool_textbox.trigger('click');
	
	// update the pool count
	var count_quantity = jQuery("#" + numberpool).val();
	count_quantity++;
	jQuery("#" + numberpool).val(count_quantity);
}

function removePoolBatch(tableid, numberpool) {
	var poolRows = jQuery("#" + tableid + " input").filter(function() {
			return jQuery(this).attr('class') == "For_Update";
		})
	var pool_count = poolRows.length;
	if ( pool_count > 1 ) {	// leave minimum one row for row copying 
		poolRows.closest("tr").filter(":last").remove();

		//update count if there is count
		if (numberpool) {
			var count_quantity = jQuery("#" + numberpool).val();
			count_quantity--;
			jQuery("#" + numberpool).val(count_quantity);
		}
	}
	else if( pool_count == 1 ) {
		alert( "You cannot delete all the pools! Minimum one pool is required." );
	}
}

function remove_row(tableid, min_row, count) {
	var quantity = jQuery("#" + tableid + " tr").length;
	if (quantity > min_row) {
		jQuery("#" + tableid + " tr:last").remove();
		//update count if there is count
		if (count) {
			var count_quantity = jQuery("#" + count).val();
			count_quantity--;
			jQuery("#" + count).val(count_quantity);
		}
	}
}
	
function update_well_information(form,Bname,BnameTextbox,itemNum,color){
	var arrId=GetSelectedItemValues(form,Bname,'id').split(",");
	var categories=new Array();
	var wells;
	var data=new Array();

	for(var i=0;i<arrId.length && arrId[0];i++){
		var checkbox=form.elements[arrId[i]];
	   	checkbox.checked=0;  // uncheck the checkbox
	    	checkbox.nextSibling.nextSibling.value=itemNum;  // change the hidden field containing the category of the well
	    	checkbox.nextSibling.value=color; // change the hidden field containing the color of the well
	}

	// update well coloring for all wells.  this would restore the loss of color after a page reload
	var categoryCount=0;
	for(var i=0;i<form.elements.length;i++){
		var e=form.elements[i];
		if(e.name==BnameTextbox){
			categories.push(e);
			data[categoryCount]=new Array();
			categoryCount++;
		}
		else if(e.name==Bname){
			var color=e.nextSibling.value;
		    	if(color){
				var category=e.nextSibling.nextSibling.value;
				data[category].push(e.value);
			}

			var TD=e;  // the table cell containing the checkbox
			// find table cell by tag
			while(TD.tagName != 'TD'){
				TD=TD.parentNode;
			}
			TD.bgColor=color;
		}
	}
	// update the textfields containining wells under each category
	for(var i=0;i<categories.length;i++){
		categories[i].value=data[i].join(",");
	}
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
// BEGIN CODE FOR CREATING A TABLE WITH SCROLLABLE BODY
// -determines table height dynamically from window size for scrollable table
// -used in views to maintain the table header and footer within the screen while scrolling through data
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 

function scrollTableColumnAlign(){
	var outerDiv = jQuery(".view_scroll_outer:visible");
	var innerDiv = outerDiv.children("div.view_scroll_inner");
	var widthrow = innerDiv.children("table").children("tbody").children("tr.widthrow").children("td");
 
	var headrow = jQuery(".scrollTableHeader:visible", outerDiv).children("tbody").children("tr").children("th");
	var footrow = jQuery(".scrollTableFooter:visible",outerDiv).children("tbody").children("tr:first").children("td"); 
    
	for(i=1;i<headrow.size();i++){
        jQuery(headrow[i]).width(jQuery(widthrow[i-1]).width());
	}

	if(footrow.size()==headrow.size()){
		for(i=0;i<headrow.size();i++){
			jQuery(footrow[i]).width(jQuery(widthrow[i-1]).width());
		}
	}else{
		jQuery(footrow[0]).width(widthrow.parent().width()-11);
	}
}

function scrollTableInit(){
	var outerDiv = jQuery(".view_scroll_outer:visible");
	var innerDiv = outerDiv.children("div.view_scroll_inner");
	var table = innerDiv.children("table");
	var height;
	if(table.size()==0){return;}   

	if(jQuery(".view_scroll_outer:visible .scrollTableHeader").size()==0){
		height = jQuery(window).height() - (table.position().top-jQuery("#tglTblScrollLock").position().top+table.children("thead").height()+table.children("tfoot").height()+5);
	}else{
		height = jQuery(window).height() - (jQuery(".view_scroll_inner:visible").position().top-jQuery("#tglTblScrollLock").position().top+jQuery(".view_scroll_outer:visible .scrollTableFooter").height()+5);
	}
	jQuery("#tglTblScroll").attr('disabled', 'disabled');
	jQuery("#tglTblScrollLock").attr('disabled', 'disabled');

	if(table.children("tbody").height()>=height){
		
                var style = table[0].getAttribute('style');  // make sure these are inherited by the header section as well 
                var bord = table[0].getAttribute('border');  
                
                table[0].removeAttribute("width");
		innerDiv.css({'overflow-x':'hidden','overflow-y':'scroll','height':height});
		outerDiv.css('float','left');

		if(jQuery(".scrollTableHeader", outerDiv).size()==0){
			var widthrow="<tr class=\"widthrow\">";
			table.children("tbody").children("tr:first").children("td").each(function(){
				widthrow+="<td style=\"line-height:0px;padding-top:0px;padding-bottom:0px;\"><div style=\"width:"+jQuery(this).width()+"px;\"></div></td>";
			});
			table.children("tbody").append(widthrow+"</tr>"); 
			table.children("thead,tfoot").hide();
                        
			outerDiv.prepend("<table class=\"scrollTableHeader\" cellspacing=\"0\" cellpadding=\"5\" style=\"" + style + "\" border='" + bord + "'>"+table.children("thead")[0].innerHTML+"</table>").append ("<table class=\"scrollTableFooter\" cellspacing=\"0\" cellpadding=\"5\" border=\"0\">"+table.children("tfoot")[0].innerHTML+"</table>");
		}

		scrollTableColumnAlign();
		jQuery(".trigger",table).click(function(){scrollTableColumnAlign();});
		if(jQuery("#tglTblScrollLock").val()=="Lock Table"){
			jQuery("#tglTblScroll").removeAttr("disabled");
		}
	}
	jQuery("#tglTblScrollLock").removeAttr("disabled");
}

function scrollTableToggle(){
	if(jQuery(".view_scroll_inner:visible").css("overflow-y")=="scroll"){
		jQuery(".view_scroll_inner:visible").removeAttr("style");
		scrollTableColumnAlign();
	}else{
		scrollTableInit();
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
// END CODE FOR CREATING A TABLE WITH SCROLLABLE BODY
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
function tableResize(tableId){
    var visHeight = window.innerHeight;
    var visWidth = window.innerWidth;
    document.getElementById(tableId).width = '100%';
    var menuOffset = parseInt(document.getElementById('body').style.paddingTop, 10);
    if (isNaN(menuOffset)) {
        menuOffset = 160;
    }
    var buttonPos = jQuery("#tglTblResize" + tableId).position().top - menuOffset;
    parseInt(buttonPos, 10);
    jQuery(window).scrollTop(buttonPos);
    
    var buttonDist = jQuery("#tglTblResize" + tableId).height();
    var $table = $("#" + tableId);
    var $wrapper = $table.closest('div.wrapper');
    
    var height = '';
    var width = '';

    if ($table.height() > (visHeight * 0.95 - buttonDist - menuOffset)) {
        height = (visHeight * 0.95) - buttonDist - menuOffset;
    }
    if ($table.width() > (visWidth * 0.95)) {
        width = (visWidth * 0.95);
    }
    $wrapper.css({'overflow':'auto', 'height':height, 'width':width}); 
    $table.floatThead({scrollContainer: function($table){ return $table.closest('div.wrapper'); }});
}

function tableRestore(tableId) {
    var $table = $("#" + tableId);
    var $wrapper = $table.closest('div.wrapper');
    $table.floatThead('destroy');
    $wrapper.css({'overflow':'', 'height':'', 'width':''}); 
    document.getElementById(tableId).width = '';
}

//code of awesomeness
function scrollTableLockToggle(){
   var button = jQuery('#tglTblScrollLock');
   if(button.val()=="Lock Table"){
      jQuery("#tglTblScroll").attr('disabled', 'disabled');
      var offset = parseInt(document.getElementById('body').style.paddingTop, 10);
      if (isNaN(offset)) {
         offset = 160;
      }
      var buttonPos = button.position().top - offset;
      parseInt(buttonPos, 10);

      jQuery(window).scrollTop(buttonPos);
      jQuery(window).bind("scroll",function(){
        if(jQuery(this).scrollTop()!=buttonPos){
            jQuery(this).scrollTop(buttonPos);
        }
      });
      button.css("background-color","03FF04").val("Unlock Table").text("Unlock Table");
   }else{
      if(jQuery(".view_scroll_outer:visible .scrollTableHeader").size()!=0){
         jQuery("#tglTblScroll").removeAttr("disabled");
      }
      jQuery(window).unbind("scroll");
      button.css("background-color","A0FFA1").val("Lock Table").text("Lock Table");
   }
}
