/* add validateForm , showBranch, swapFolders */

/* Hide & unHide Elements (by ID or by Name) */

function HideNamedElement (name) {
    var Elem = document.getElementsByName(name);
    for (var j=0; j < Elem.length; j++){
        var e = Elem[j];
        e.style.display='none';
    }
}

function unHideNamedElement (name, type) {
    var Elem = document.getElementsByName(name);
    var Etype = type || '';
    for (var j=0; j < Elem.length; j++){
        var e = Elem[j];
        e.style.display = Etype;
    }
}

function HideElement (id) {
    var Elem = document.getElementById(id);
    Elem.style.display='none';
}

function unHideElement (id, type) {
    var Elem = document.getElementById(id);
    var Etype = type || '';
    Elem.style.display = Etype;
}

/* Simple accessor to retrieve an element that may be either an id or a name (optional index may be supplied if element name is an array ) */
function getElement (scope, identifier, index) {
    var el = scope.getElementById(identifier);
    if (el) { return el }
    
    var list = scope.getElementsByName(identifier);
    if (list && list.length == 1) {
        return list[0];
    }
    
    if (typeof index != 'undefined') { return list[index] }
    return list;
}

/* Simple Accessor to set element value that accounts for element type - including Bootstrap multiselect dropdowns */
function setElementValue (cell, value) {
    if (cell.className.match('multiselect')) {
        /* Account for bootstrap multiselect form elements if applicable */
        if (!value) {  $(cell).multiselect('deselect', cell.value) }
        else { $(cell).multiselect('select',value); }
    }
    else {
        cell.value = value;
    }
}

/* Function to go along with standard LampLite matrix forms which include auto-fill options (where '' indicates value should be copied from element above */
function resetAutofillForm(f, x_ids, y_ids) {
    // in conjunction with autofillForm for matrix forms (sets rows 2..N = "''")
    // otherwise, clears listed elements
    // input element naming format = 'x.y' with commma-delimited list of x, y values supplied 
    //
    // previously, this was inappropriately used to toggle checkboxes... this should be done using ToggleNamedCheckboxes function instead
    
    // supply list of form elements or list of x,y names in matrix
    var x_id_array = x_ids.split(',');
    var y_id_array = y_ids.split(',');

    for (var x=0; x<x_id_array.length; x++ ) {
        var xName = x_id_array[x];
        
        if (y_id_array.length) {
            // matrix list of form elements (format assumed to be 'x.y' for each x, y value provided
            for (var y=0; y<y_id_array.length; y++) {
                var afCell = getElement(document, xName + '-' + y_id_array[y], 0);
                if (afCell.className.match('multiselect')) { 
                    var value = '';
                    if (y == 0) { 
                        for (var o=0; o<afCell.children.length; o++) {
                            /* Need to select and deselect multiselect items since the label doesn't clear otherwise ...cleaner fix would be preferable, but this works for now... */
                            if (afCell.children[o].value) {
                                var value = afCell.children[o].value;
                                $(afCell).multiselect('select',value);
                                $(afCell).multiselect('deselect',value);
                                break;
                            }
                        }
                    }
                    else { $(afCell).multiselect('select',"''"); }
                }
            }
        }
        else {
            // single list of form elements 
            var cell = getElement(document, xName, 0);
            if (cell.className.match('multiselect')) { $(cell).multiselect('select',''); }
        }
    }
    return;
}

/* Function to go along with standard LampLite matrix forms which include auto-fill options (where '' indicates value should be copied from element above */
function clearForm(f, x_ids, y_ids) {
    // in conjunction with autofillForm for matrix forms (sets rows 2..N = "''")
    // otherwise, clears listed elements
    // input element naming format = 'x.y' with commma-delimited list of x, y values supplied 
    //
    // previously, this was inappropriately used to toggle checkboxes... this should be done using ToggleNamedCheckboxes function instead
    
    // supply list of form elements or list of x,y names in matrix
    var x_id_array = x_ids.split(',');
    var y_id_array = y_ids.split(',');

    for (var x=0; x<x_id_array.length; x++ ) {
        var xName = x_id_array[x];
        
        if (y_id_array.length) {
            // matrix list of form elements (format assumed to be 'x.y' for each x, y value provided
            var topCell = getElement(document, xName + '-' + y_id_array[0], 0);
            setElementValue (topCell, '');
            
            for (var y=1; y<y_id_array.length; y++) {
                var afCell = getElement(document, xName + '-' + y_id_array[y], 0);
                setElementValue (afCell, "''");
            }
        }
        else {
            // single list of form elements 
            var cell = getElement(document, xName, 0);
            setElementValue(cell, '');
        }
    }

   return;
}

/* Function to go along with standard LampLite matrix forms which include auto-fill options (where '' indicates value should be copied from element above */
function autofillForm (f, x_ids, y_ids) {
// provide comma-delimited lists of column names and row names
// element names or ids will be assumed to be unique with id/name format: 'xname-yname' for each cell 
	
    var x_id_array = x_ids.split(',');
    var y_id_array = y_ids.split(',');
    
    for (var x=0; x<x_id_array.length; x++ ) {
        var xName = x_id_array[x];
        var value_above = '';  
        var label_above = '';
        for (var y=0; y<y_id_array.length; y++) {
            var yName = y_id_array[y];  
		    cellName = xName + '-' + yName;
		    var cell = getElement(document, cellName,0);
                    var value;
                    var label;
                    if (cell) {
                        value = cell.value;
                        if (cell.options) { label = cell.options[cell.selectedIndex].text; }
                        if (typeof label == 'undefined') { label = value }
                    }
                    else { continue; }
                    
                    if ( typeof value == 'undefined' ) { value = ''; label = '' }
		    if (value.match(/^''$/)) {
		        // set cell to value above if current value = '' (even if cell above is blank) 
		        value = value_above;
                        label = label_above;
                       
                        setElementValue(cell, value);
                    }
		    value_above = value;
                    label_above = label;
	    }
    }
}

// Form validation script
function validateForm(f,repeats, formtype, validatorname) {

    // Get a list of all the validator tags
    var list = f.getElementsByTagName('validator');
    var size = list.length;
    var message ='';

    if (! formtype) { formtype = 'append' }
    // Array of all the missing elements
    var missings = new Array(0);
    var confirmPrompt = '';
         
    for(var i=0;i<size;i++) {
        if (! confirmPrompt && list[i].getAttribute('confirmPrompt') ) { 
            confirmPrompt = list[i].getAttribute('confirmPrompt');
            continue;
        }

        
        // Get the attributes of the validator tag
        var fieldName = list[i].getAttribute('name');
        var fieldID   = list[i].getAttribute('id');
    
        if (validatorname && validatorname != fieldName) { continue }
        var alias  = list[i].getAttribute('alias') || fieldName || fieldID;
        var format = list[i].getAttribute('format');
        var mandatory = list[i].getAttribute('mandatory');
        
        var readonly  = list[i].getAttribute('readonly');
        var prompt = list[i].getAttribute('prompt') || '';
        var type   = list[i].getAttribute('type') || 'undef';
        var count  = list[i].getAttribute('count') || 'undef';

        var caseVal  = list[i].getAttribute('case_value') || 'undef';
        var caseID  = list[i].getAttribute('case_name');
	var listed;

        var readableFormat = readable(format);
        if (caseID != null) {
            var cValue = getElementValue(f,caseID);
            var options = caseVal.split('|');
            var activated = 0;
            for (var o=0; o<options.length; o++) {
                var option = options[o];
                if (option == 'undef') { 
                    // if no case_value supplied, activate if dependent element is non-empty
                    if (cValue && cValue.length > 0) { activated = 1 }
                }
                else if (cValue && cValue.match(',')) {
                    var List = cValue.split(',');
                    for (j=0; j<List.length; j++) {
                        if (List[j] == option) { activated = 1; }
                    }
                }
                if ( cValue == option) { activated = 1;  }
            }
            if (activated) { }
            else { continue }
        }
	    
		var test_string = new RegExp(' list');
		if (test_string.test(format) ){
			format = format.replace(test_string,"");
		    listed =1; 
		}
	
        // Get the HTMLInputElement referenced by the <validator> tag
         // var inputField = f.elements[fieldName];
         
         var inputField = new Array(0);
         if (fieldName) { 
             inputField = f.elements[fieldName]; // document.getElementsByName(fieldName);
        }
        else if (fieldID) { 
            var idField = document.getElementById(fieldID);
            if (idField) { inputField = idField }
        }
         var inputElement;
         
         // force elements into an array to enable checking for multiple rows if necessary (field with same name shows up as an array)
        
         var Elem = new Array(0);
         if (0 && repeats && inputField.length > 0) { 
             // this logic may need to be revisited for repeat element names - or may be preferable to avoid repeats altogether if possible      
             for (var j=0;j<inputField.length;j++) {
                 inputElement = inputField[j];
                 Elem.push(inputElement);
             }
         }
         else{      
             inputElement = inputField;           
             Elem.push(inputElement);
         } 
     
        var checks = Elem.length;       // length of array (= 1 for normal non-ed elements)
        var checked;

        for(var k=0; k<checks; k++) {
            inputElement = Elem[k];
            if (inputElement && ! inputElement.type && inputElement.length > 0 && inputElement[0].type && inputElement[0].type.match(/(radio|checkbox)/) ) {
                // section for looking for selection of at least one radio / checkbox elements chosen
                if ( mandatory  && mandatory.match(/(1|true)/) ) {
                    // seems to always pass simple boolean test ... mandatory may be somehow always saved as a string.. so always true ?
                    // may need to similarly adjust logic below where if (mandatory) is currently tested... 

                    // get checkbox elements with the same name if applicable 
                    var tlist = document.getElementsByName(fieldName);
                    if (! tlist) { tlist = document.getElementById(fieldID) }
                    
                    var count = tlist.length;
                    if ( count ) {
                        // for radio buttons, we need to check if they are actually selected 
                        var found_option = 0;
                        for (var m=0; m<tlist.length; m++) {
                             if (tlist[m].value && tlist[m].type && tlist[m].type.match(/(radio|checkbox)/) && tlist[m].checked) { found_option++; m = tlist.length; } 
                         }
                        if ( !found_option) {
                            message += add_message(fieldName + " not chosen", prompt);
                            missings.push(fieldName); 
                        }
                    }
                    else { 
                        message += add_message(fieldName + " not specified", prompt);
                        missings.push(fieldName);
                    }
                }
            }
            else if (inputElement && mandatory && inputElement.type && inputElement.type.match(/checkbox/)) {
                // for checkboxes, make sure at least one is selected 
                var tlist = document.getElementsByName(fieldName);
                var count = tlist.length;
                if (count < 2 || ! ( message.match(/\bfieldName\b/) ) ) {
                    // skip this section if multiple elements with the same name & message already generated 
                    var found_option = 0;
                    for (var m=0; m<tlist.length; m++) {
                        if (tlist[m].value && tlist[m].checked) { found_option++; m = tlist.length; } 
                    }
                    if (!found_option) { 
                        message += add_message(fieldName + " not selected", prompt);
                        missings.push(fieldName);
                    }
                }
            }
            else {
                // If the value is empty and there does exist a choice drop down, set that as the inputElement

            if (repeats && k>0 && inputElement.value.match(/^''$/) ) { 
                // enable use of '' to use same value as previous record //

                // need to set this slightly differently for cases of popdown menus... //

                // need to also adjust for date fields (not sure why they aren't working ?) //

                //inputElement.value=Elem[k-1].value;
                inputElement.value=null;
            }

            // Value inside this element
            var value = inputElement.value;
            
            if (inputElement.type && inputElement.type.match(/^radio$/)){
               if(inputElement.checked){checked = 1;}
            }

            // Change the background color to white untill this element is checed
            inputElement.style.backgroundColor='#ffffff';
            
            // If the field is disabled, sip
            if(inputElement.disabled) {
                continue;
            }
	    if (listed && format){
		// pattern testing should be moved to a new fucntion in future
		var value_array = value.split(/\s*,\s*/);
		var a_size = value_array.length;
		var faield;
	        for(var z=0;z<a_size;z++) {
			var a_elem = value_array[z];			
			var test_string = new RegExp(format);
			if (a_elem.length == 0 || test_string.test(a_elem)){
		}
	    else{
		    message += add_message(alias + " value(" + a_elem + ") should match pattern: " + readableFormat, prompt);
		    failed =1;
	    }
	}
        
	if (failed){
		missings.push(inputElement);
	}
	format ='';
    }
			
            // Check format only for text fields
            if (format && inputElement.type) {
                if (!inputElement.type.match(/^(text|password)$/)) {
                    format = '';
                }
            } 

            // Figure out if the element is mandatory and/or has a format associated with it
            //  if it fails any of the checks, concat a message to 'message' string and push the element in missings array
            if (readonly && formtype == 'edit') {
                if(trim(value).length > 0) {
                    message += add_message(alias + " cannot be changed", prompt);
                    missings.push(inputElement);
                }
            }

            // Figure out if the element is mandatory and/or has a format associated with it
            //  if it fails any of the checks, concat a message to 'message' string and push the element in missings array
            
            if (formtype == 'append') {
                if (mandatory==1 && format) {
                    if(trim(value).length==0) {
                        message += add_message(alias + " is Mandatory", prompt);
                        missings.push(inputElement);
                    }
                    else if (!value.match(format)) {
                        message += add_message(alias + " should match pattern: " + readableFormat, prompt);
                        missings.push(inputElement);
                    }
                } else if(format) {
                    if ( value && !value.match(format)) {
                        message += add_message(alias + " should match pattern: " + readableFormat, prompt);
                        missings.push(inputElement);
                    }
                } else if (mandatory==1) {
                    if (inputElement.type && inputElement.type.match(/^radio$/)){
                      if ((k == (checks -1)) && (!checked)){
                          message += add_message(alias + " is Mandatory", prompt);
                          missings.push(inputElement);
                      }                     
                    }
                    else if (trim(value).length==0) {
                        message += add_message(alias + " is Mandatory", prompt);
                         missings.push(inputElement);
                    }
                    else if (value.match(/^\-\-/)) {
                        message += add_message(alias + " is Mandatory.", prompt);
                        missings.push(inputElement);
                    }
                    else if (type.match(/date/) && value.match(/^0/)) {
                        message += add_message(alias + " requires non-zero date.", prompt);
                        missings.push(inputElement);
                    }
                }
            }
            }
         } // end of K
    } // end of i

    // Set the background color of missing elements to orange
    for(var i=0;i<missings.length;i++) {
        if (missings[i] && missings[i].type) {
            missings[i].style.backgroundColor='#ffcc33';
        }
    }

    // Alert the user about the missing elements and set the focus to the first missing element
    if (confirmPrompt) {
        var cr=confirm(confirmPrompt);
        if (cr==false) { return false }
    }
    
    if (message) {
        alert(message);
        // Add a small help to the message to explain the regular expressions
        /*		message += "\nSome suggestions:\n\n";
        message += "If a field is mandatory, you can not leave it blank.\n";
        message += "\\w+   : The field should only contain word characters.\n";
        message += "[1-9]+ : The field should only contain digits.\n";
        message += "[0-9a-zA-Z]{5,6}: The field should be exactly 5 or 6 alphanumeric characters.\n";*/
       
        if(missings[0] && missings[0].type) { missings[0].focus() }
        return false;
    } else {
        // If everything is fine, proceed to submitting the form
        return true;
    }
}

function add_message (message, prompt) {
    // simple wrapper to clean up messaging with possible prompt override 
    if (prompt) { return prompt + "\n\n" }
    else { return message + "\n\n" }
}

/// Used to dynamicly change what fields are mandatory
function unset_mandatory_validators(f, name) {

	// Get a list of all the validator tags
	var list = f.getElementsByTagName('validator');
	var size = list.length;

	for(var i=0;i<size;i++) {
	  var thisname = list[i].getAttribute('name');
            if ( !name || name == thisname ) {
		  //alert('make NOT mandatory');
		  list[i].setAttribute('mandatory', 0);
	    }
            else if (name.match(/\*/)) {
                /* allow wildcards in unset element name */
                name.replace('.','\.');
                var nameExp = new RegExp(name);
                //var nameExp = new RegExp('OC.*');
                if (nameExp.test(thisname)) {
                    list[i].setAttribute('mandatory', 0);
                }                 
            }
	}
}

/// Used to dynamicly change what fields are mandatory
function set_mandatory_validators(f, name) {

	// Get a list of all the validator tags
	var list = f.getElementsByTagName('validator');
	var size = list.length;

	for(var i=0;i<size;i++) {
	  var thisname = list[i].getAttribute('name');
	  if ( !name || name == thisname ) {
		list[i].setAttribute('mandatory', 1);
          }
          else if (name.match(/\*/)) {
                /* allow wildcards in unset element name */
                name.replace('.','\.');
                var nameExp = new RegExp(name);
                //var nameExp = new RegExp('OC.*');
                if (nameExp.test(thisname)) {
                    list[i].setAttribute('mandatory', 1);
                }                 
            }
        }
}

// converts REGEXP formatting specs to slightly more human readable variation for alert messages 
function readable (format) {
     
     if (! format) { return }
     var readable = format.replace(/\\d/g,'#');
     readable = readable.replace(/^\^/,'');
     readable = readable.replace(/\$$/,'');

    readable = "'" + readable + "'";
    return readable;
}

function trim(str) { 
    str.replace(/^\s*/, '').replace(/\s*$/, ''); 

    return str;
} 

// Trim a string
function trim(str) {

    if ( str ) { str = str.replace(/^\s*|\s*$/g,""); }
    else { var empty = ''; return empty; }
    return str;
}
