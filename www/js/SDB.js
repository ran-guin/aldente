var Warning; 
var old_warning;
clr=new Array('yellow','white','silver');

var nav = window.Event ? true : false;
var allow_submit = true;
var HelpWin = null;
var HelpWin_closed = false;
var formElementTypes = new Array('input','textarea','select');
var URL_version = location.pathname.match(/\/SDB_?\w+/)

if (nav) {
//   window.captureEvents(Event.KEYDOWN);
   window.onkeydown = NetscapeEventHandler_KeyDown;
//   window.captureEvents(Event.MOUSEDOWN);
   window.onmousedown = NetscapeEventHandler_MouseDown;
} else {
   document.onkeydown = MicrosoftEventHandler_KeyDown;
   document.onmousedown = MicrosoftEventHandler_MouseDown;
}

function highlight(state) {
	element=event.srcElement;
	if (element.tagName=='INPUT') {
		etype=element.type;
		if ((etype=='submit' || etype=='reset') && state==1) state=2;
		element.style.backgroundColor=clr[state];
		element.focus();
	}
}

function sendAlert(msg) {
	alert(msg);
}

function ToggleHelpWin(msg) {
<!-- This toggles a HelpWindow on or off (closes if window is already open)... -->

    if (HelpWin != null) {
        if (HelpWin.closed) {
	    OpenHelpWin(msg);
        } else {
            HelpWin_closed = true;
            HelpWin.close();
	}
    }
    else {
	   OpenHelpWin(msg);
    }
}
    
function TimedWin(msg,x,y,sec) {
	if (!x) x = 400;	
        if (!y) y = 400;
	if (!sec) sec = 5000;  

        HelpWin=window.open("","displayWindow","menubar=no,scrollbars=no,status=no,width=500,height=100,top=x,left=y,screenX=x,screenY=y");
        HelpWin.document.write(msg + '<br>');
	setTimeout('HelpWin.close()',5000);
}

function OpenHelpWin(msg,x,y) {
	if (!x) x = 400;	
        if (!y) y = 400;

        HelpWin=window.open("","displayWindow","menubar=no,scrollbars=no,status=no,width=500,height=100,top=x,left=y,screenX=x,screenY=y");
        HelpWin.document.write(msg + '<br>');

        if (HelpWin_closed) {
           HelpWin_closed = false;
        }	
}

function SendMessage(form,MessageToSend) {
	alert(MessageToSend);
}

function CheckInput(f) {

<!-- This is a standard Input display routine... -->

   var value = 0;
   var msg = 'Messages:\n**************\n';
   for (var i=0; i<f.length; i++) {
      var id = 123;
      var e = f.elements[i];            // look at each form in turn...
      var elementName = e.name;
      if ((e.type == 'select-one') || (e.type=='select-multiple')) {
         value = ' ';
         for (var j=0; j<e.options.length; j++) 
            if (e.options[j].selected) value += e.options[j].value + ' ';
      }
      else if (e.type == 'textarea') value = '...';
      else if ((e.type == 'radio') || (e.type == 'checkbox'))
         value = e.value + ' = ' + e.checked;
      else value = e.value + '(' + e.type + ')';

      msg += elementName + ' = ' + value + '\n';
   }
   alert(msg);
}

function PasteColumn (f, source_element, target_element, delim) {
// For this to work properly, the target element should be in the form: 'string<N>' or the element names in the form <target_element>.N 
// 
<!-- Provides capability to paste values into an html column   -->

    var source = document.getElementById(source_element);
    var source_array = document.getElementsByName(source_element);

    var values = new Array;
    
    var cloned_column;
    var cloned_column_cleared;

    var target_array = document.getElementsByName(target_element);
    if (target_array.length > 1) {   
        // target element is array of elements (probably cloned)
        cloned_column = 1;
        if (source_element.match(/^Clear/)) {
            // clearing target element ... a bit clunky requiring a specific element name, but okay for now... 
            for (var i=0; i<target_array.length; i++) { values.push('') }
            cloned_column_cleared = 1;
        }
    }
    
    if (cloned_column_cleared) { 
        // values set to blank in block above... 
    }
    else if (source) {
        var value = source.value;
        values.push(value);
    }
    else if (source_array) {
        for (var i=0; i<source_array.length; i++) {
            var val = source_array[i].value;
            if (val.match('\n')) {
                values = val.split('\n');
            }
            else {
                values.push(val);
            }
        }
    }
    
    var target_elements;
    var target = target_element;
    
    if  ( target.match(',') ) {
        // list of element names supplied explicitly
        target_elements = target.split(',');
    }
    
    for (var i=0; i<values.length; i++) {
        var record = i+1;
        var target = target_element;

        var target_name = target;
        
        if (target_elements && target_elements.length > 1) {
            target_name = target_elements[i];
        }
        else if (target.match('<N>') ) { 
            // if target is has explicit .<N> suffix 
            target = target.replace(/<N>/g, record);
            target_name = target;
        }
        else {
            // if target name is appended with .<row> 
            var before = document.getElementsByName(target_name);
            var record = i+1;
            var indexed = document.getElementsByName(target_name + '.' + record);

            if ( !(before.length) && (indexed.length) ) {
                target = target.replace(/$/, '.' + record);
                target_name = target_name + '.' + record;
            }
        }   
        
        // some additional logic might be nice to allow target_element to be 'ABC Choice|ABC' so that if ABC Choice is defined, then it needs to be in that list...
        // this would make it simpler to avoid setting the text section of search / filter lists
        // user would simply define paste_columns to be "$field Choice|$field" instead of simply "$field" as the easiest option for now 
        //
           
        if (target.match('|')) {
            var element_names = target.split('|');
            for (var j=0; j<=element_names.length; j++) {
                var eoptions = document.getElementsByName(element_names[j]);
                if (eoptions.length > 0) { 
                    target_name = element_names[j];
                    j = element_names.length; // stop loop once element is found... 
                }
            }
        }
           
        var index;
        if (cloned_column) { index = i }
                
        SetSelection(f, target_name, values[i], null, index);
        var after = getElementValue(f, target_name, null, index);  
             
        if (after != values[i]) {
            if (values[i] == '' || values[i] == "''") {
                var elements = document.getElementsByName(target_name);
                
                if (elements.length == 1 && ( elements[0].type == 'select-one' || elements[0].type == 'select-multiple' ) ) {
                    // add blank or '' values even if not in dropdown list                   
                    elements[0].options[elements[0].options.length] = new Option(values[i], values[i]);
                    SetSelection(f, target_name, values[i], null, index);
                }
                after = getElementValue(f, target_name, null, index);        
            }  
                      
            if (after != values[i]) {
                alert(values[i] + ' could not be set for record #' + record + ' in this column - ignored..left as ' + after); 
                continue;
            }
        }
    }
}
   
function SetSelection(f,Bname,Bvalue,Bselect,index) {
<!-- This routine sets a particular button on when run     -->

	var FindString = Bname + ',';  
	var PickButton = Bselect + ',';
	var SetButton = Bvalue;
	var found = 0;
	
	if (Bvalue == 'add')
 		SetButton = 'true';
 		
	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
		var elementName = e.name;
		if (elementName == Bname) {
		    
		    if (index != null) {
		        found = found+1;
		        if (found != index+1) { continue }  // eg for 3 identically named elements, if index = 2 only update 2nd element... 
		    }
			var Ename = e.value + ',';
			if (e.type=='checkbox') {
				if (Bselect && Bselect == 'all' && !e.disabled) {
					e.checked = SetButton;
				} else {
					if (PickButton.search(Ename)>=0 && !e.disabled) {
						if (Bvalue == 'toggle') 
							e.checked = !e.checked;	
						else 
							e.checked = SetButton;
					}
				}
			}
			else if (e.type=='radio') {
				if (PickButton.search(Ename)>=0)	
					e.checked = SetButton;
			}
			else if (e.type=='text') {
                            e.value = SetButton;
                        }
                        else if (e.type=='textarea') {
            	            e.value = SetButton;
                        }        
			else if (e.type=='select-one') {
				for (var j=0; j<e.options.length; j++) {
					if (e.options[j].value == SetButton)
						e.options[j].selected = true;
					else 
						e.options[j].selected = 0;
				}
			}
			else if (e.type=='select-multiple') {
				for (var j=0; j<e.options.length; j++) {
					if (e.options[j].value == SetButton)
						e.options[j].selected = true;
					else 
						e.options[j].selected = 0;
				}
			}
	        else if (e.type=='hidden') {
				e.value = SetButton;
                        } else {
                           alert('unrecognized element type: ' + e.type); 
                        }
		}
	}
}

function SetListSelection(f,Bname,Bvalue,Bexclude) {
<!-- This routine sets value for a list of elements     -->
	var to_exclude = document.getElementById(Bexclude).value;
	var excludes = to_exclude.split(",");
        var elements = Bname.split(",");
	var values = Bvalue.split(",");
        for(var i=0; i<excludes.length; i++){
          var range = excludes[i].split("-");
            if(range.length > 1)
            {
                excludes[i] = range[0];
                excludes.push(range[1]);
                for(var j=0; j<values.length ;j++)
                {
                  if (values[j]>range[0] && values[j]<range[1])
                  {
                     excludes.push(values[j]);
                  }
                }
            }
        }
	var exclude_hash = new Array();
	for(var i=0; i<excludes.length; i++) {
		exclude_hash[excludes[i]] = 1;
	}
        
	
	var value_index = 0;
	for(var i=0; i<elements.length; i++) {
		var element = document.getElementById(elements[i]);
		for (var i2=value_index; i2<values.length; i2++) {
                        value_index++;
			if (!exclude_hash[values[i2]]) {
				element.value = values[i2];
				break;
			}
		}
	}
}

function GetSelectedItemValues(f,Bname,wanted) {
<!-- This routine returns values of checked elements of a certain name    -->

	var arr = new Array(); 
	var lastElement = 0;
	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
		if (e.name == Bname && e.checked) {
			if(wanted=='value'){
				arr[lastElement] = e.value;
			}
			else if(wanted=='id'){
				arr[lastElement] = i;
			}
			lastElement++;
		}
	}
	var checked = arr.join(",");
	return (checked);
}

function MenuSearch2(Search,RecueMenu) {

    var sf_id = Search.id;
    var list_o = document.getElementById(sf_id + '.Choice');
    var filter_o = document.getElementById(sf_id + '.Filter');
    var search_o = document.getElementById(sf_id + '.Search');
    var new_o = document.getElementById(sf_id + '.New');
    
    var myregexp = new RegExp(Search.value, "i")
  
    var search_list = Search.value.split("\n");
    if (search_list.length > 1) { 
        var string = '';
        for (var i=0; i<search_list.length; i++) {
            if (search_list[i].length > 0) { 
                if (string.length > 0) { string = string + '|' }
                string = string + search_list[i];
            }
        } 
        myregexp = new RegExp(string, "i");
    }
   
    if (filter_o.checked) {
        var original_length = list_o.getAttribute('original_length') || 0;
        for (var i=list_o.length-1; i >= original_length; i--) {
//            if (!(list_o[i].value == '' || list_o[i].value.match(myregexp))) {
              if ( ! list_o[i].value.match(myregexp) ) {
                list_o.remove(i);
                list_o.setAttribute('filtered', 'true');
            }
        }

        // If the first one is a blank, then select the second one
        if(list_o[0] && list_o[0].value) {
            list_o[0].selected = 1;
        } else if(list_o[1] && list_o[1].value) {
            list_o[1].selected = 1;
        }
        Search.value = '';
    } else if(search_o.checked) {
        var found;
        for (var i=0; i<list_o.length; i++) {
            if(list_o[i].value.match(myregexp)) {
                found = 1;
                list_o[i].selected = 1;
                if(!list_o.multiple) { // stop at the first one, sine can't select multiple
                    break;
                }
            }
        }

        if(!found) {
            alert("No results matching '" + Search.value + "'");
        }

        Search.value = '';
    }
}


// These 2 functions are replaced by more general functions
// dependentFilter and fillOptions
//
// These should be removed

/*
function LongListMenuSearch(Search,URL,RecueMenu) {

    var sf_id = Search.id;
    var re = new RegExp('\\.', 'g');
    var indicator_id = "#indicator_" + sf_id.replace(re,"_");
    var $j = jQuery.noConflict();

    $j(indicator_id).bind("ajaxStart", function(){$j(this).show();})
    .bind("ajaxStop", function(){$j(this).hide();});

    var substr = trim(Search.value);
    if (substr.length >= 3) {
        $j.get(URL+"&Element_Value="+substr, function(data){FillLongList(Search,data,RecueMenu)});
    }

    $j(indicator_id).bind("ajaxStart", function(){$j(this).hide();});
}

function FillLongList(Search,ajax_list,RecueMenu) {

    var sf_id = Search.id;
    var scroll_list = document.getElementById(sf_id + '.Choice');
    scroll_list.options.length = 0;
    
    if (ajax_list) {

        var entries = new Array();
        entries = ajax_list.split(",");

        scroll_list.options[0] = new Option('', '');

        for(var i=0; i<entries.length; i++) {
            scroll_list.options[i+1] = new Option(entries[i],entries[i]);
        }
    }

    else {
        scroll_list.options[0] = new Option('--Enter string above to search list--','');
        alert("No results matching '" + Search.value + "'");
    }
   
    // If the first one is a blank, then select the second one
    if(scroll_list[0] && scroll_list[0].value) {
        scroll_list[0].selected = 1;
    } else if(scroll_list[1] && scroll_list[1].value) {
        scroll_list[1].selected = 1;
    }

    Search.value = '';
}
*/

// quick accessor to element when not sure if identifier is name or id 
function findElement (name, type) {
    var element  = document.getElementById(name);  // name or id can be passed as first parameter
    
    if (!element) {  
        // if element name used instead, it is retrieved in block below... 
        var elements = document.getElementsByName(name);
        
        var valid_elements = new Array();
        if (type) {
            for (i=0; i<elements.length; i++) {
                if (elements[i].type && elements[i].type.match(type)) { valid_elements.push(elements[i]) }
            }
        }
        else { valid_elements = elements }
        
        if (valid_elements.length > 1) { 
            alert('multiple elements matching ' + name + ':' + valid_elements.length);
        }
        else if (valid_elements.length < 1) { alert('element ' + name + ' not found') }        
        element = valid_elements[0];
    } 
    
    return element;
}

// auto expand textfield/textarea dynamically (in conjunction with reduce_textfield)
function expand_textfield (name, rows, cols, split) {    
    var element = findElement(name, 'text'); // name or id can be passed as first parameter   
     
    if (split) { split_contents(element) }  // split option changes comma-delimited lists into linefeeds
    
    if (element.type == 'text') {
        var size = rows; // only one parameter passed
        element.setAttribute('size', size); 
    }
    else if (element.type == 'textarea') {
        element.setAttribute('rows', rows);
        element.setAttribute('cols', cols);       
    }
    else {
        alert('cannot generate dynamic text area for ' + element.type);
    }
    return;  
}


// reduces textfield/textarea size to pre-zoom state (in conjunction with expand_textfield)
function reduce_textfield (name, rows, cols, unsplit) {
   var element = findElement(name, 'text'); // name or id can be passed as first parameter    

   if (unsplit) { unsplit_contents(element) } // unsplit option changes linefeeds into commas
 
   if (element.type == 'text') {
       var size = rows;   // first parameter passed in
       element.setAttribute('size', size); 
   }
   else if (element.type == 'textarea') {
       element.setAttribute('rows', rows);
       element.setAttribute('cols', cols);       
   }
   else {
       alert('cannot generate dynamic text area for ' + element.type);
   }
   return;
}

// split text area contents on comma to display on separate lines (can use in conjunction with unsplit_contents)
function split_contents (element) {
    var contents = element.value;
    var rows = contents.split(/\n|,/);
    
    var height = rows.length;
    
    var newcontents = new Array();
    for (var i=0; i< height; i++) {
        var val = rows[i];
        newcontents.push(val);
    }

    element.value = newcontents.join("\n");
    return height;
}

// condense line separated elements into comma-delimited list (can use in conjunction with split_contents)
function unsplit_contents (element) {      
       var contents = element.value;
       var rows = contents.split(/\n|,/);
       
       var newcontents = new Array;
       for (var i=0; i< rows.length; i++) {
           var val = rows[i];
           newcontents.push(val);
       }
   
       element.value = newcontents.join(",");
       return newcontents.length;
}

function populate_list(name, url, table, field, condition, reset) {
    // enables dynamic population of dropdown menus to speed up and simplify html page generation where multiple copies of the same list exists... 
    // adjust to accept parameters enabling ajax query rather than explicit list

    var ajax_call = url + '?Table=' + table + '&Field=' + field + '&Condition=' + condition + '&Global_Search=1';
    
    var $j = jQuery;//.noConflict();

//    var options = list.split(',');

    if (name) {
        element = document.getElementById(name);
        
        if (element && element.type.match('select')) {
            var populated = element.getAttribute('populated');
            var filtered  = element.getAttribute('filtered');
            
//            alert(name + ' P: ' + populated + '; F: ' + filtered + '; R: ' + reset);
     
            if (!populated || ( reset && filtered == 'true' ) ) {
                // if not yet populated, or filtered and reset option requested
                if (!populated) { element.setAttribute('original_length', element.length) }
                
                var index = element.getAttribute('original_length') || 0;
                
                if (reset) { index = reset }
                $j.get(ajax_call, function (data) {
                      // fillOptions(name, data)
                      var options = data.split(',');
                      for (var i=0; i<options.length; i++) {
                          element.options[index] = new Option(options[i], options[i]);
                          index++;
                      } 
                });
                element.setAttribute('filtered', 'false');  // boolean tests do not work if set to true/false keywords (?)
                element.setAttribute('populated', 'true');
            }
        }
    }
}

function repopulate_list(radio) {
    var name;
    var prefix = 'ForceSearch';

    if(radio.name.indexOf(prefix) == 0)  {
        name = radio.name.substring(prefix.length);
    } else {
        return;
    }

    var list_o    = document.getElementById(name + '.Choice');
    var orig_list = document.getElementById(name + '.OriginalList').innerHTML;
    // OriginalList is stored like <!--cat^!^.....^!^mouse-->
    var prefix = '<!--';
    var postfix= '-->';

    orig_list = orig_list.substring(orig_list.indexOf(prefix) + prefix.length);
    orig_list = orig_list.substring(0,orig_list.indexOf(postfix));
    
    var original = new Array();
    original = orig_list.split("^!^");
    
    if(list_o.options.length < original.length)  
        // Only do this if number of elements currently present are less than all the possible options
        //  This could potentially be a bug only 1 item gets filtered and one item is added from somewhere else (ie. a '' )
        for(var i=0; i<original.length; i++) 
            list_o.options[i] = new Option(original[i],original[i]);
}

function MenuSearch(f,ReduceMenu) {
 
<!-- This routine Searches a popup menu for a given string -->
<!-- Needed:                                               -->
<!--          textfield: (to enter in search string)..     -->
<!--          popup_menu: 'ForceSearch' = ('Search',...)   -->
<!--          popup_menu: (to search for string from)      -->
<!--  if ReduceMenu is set, the popup_menu is reduced          -->

   var MaxSearchLength = 4000;
   for (var i=1; i<f.length; i++) {
      var e = f.elements[i];            // look at each form in turn...
      var elementName = e.name;
      if (elementName.search(/forcesearch/i) >= 0) {   // Found 'ForceSearch' field...
	
        var TextIndex = i-1;   // index text field (checking for Search flag checkbox)
	 	while ((f.elements[TextIndex].type != 'text') && (TextIndex>0)) {
			TextIndex--;
	 	}
        var LastField = f.elements[TextIndex].name;

 		// FORCE if first option selected from pull-down menu 
 		// OR if field type is hidden...

         var TextString = f.elements[TextIndex].value;
         if (TextString.search(/\S/)>=0) {          // only perform if field is filled in...
			// ### check Force Status...
	 		var Search = ReduceMenu;     // variable to indicate that searching is to occur
			var k = i;

	 		if (e.type == 'select-one') {
				k=i+1; 
				for (var l=0; l<e.options.length; l++) {
					var selectName = e.options.value;
					if (selectName.search(/search/i)==0) Search = 1;
				}
			} else if (e.type == 'hidden') {
				k=k+1;
				if (e.value == 'Search') Search = 1; 
			} else if ((e.type == 'checkbox') || (e.type == 'radio')) {
				while (f.elements[k].name == elementName) {
				if (f.elements[k].checked) {
					var SelectedOption = f.elements[k].value;
					if (SelectedOption.search(/search/i)>=0) Search = 1; ReduceMenu = 0; // enable with 'search' 
					if (SelectedOption.search(/new/i)>=0)    Search = 0; ReduceMenu = 0; // disable with 'new' 
					if (SelectedOption.search(/filter/i)>=0) { Search = 1; ReduceMenu = 1; } 
				}
				k++;
				i++;
			}
	 	}
		var MenuIndex = k;
		var MenuField = f.elements[MenuIndex]; 

          	var options='';  
             	var choices=0;
            	var kills = 0;
            	var eliminate = new Array();
            	
		if (MenuField.length > MaxSearchLength) {
			alert(MenuField.name + ' too big to search (' + MenuField.length + ' records)');
		}
		
		for (var j=0; j<MenuField.length; j++) {
                	var choice = MenuField.options[j].value;
                	choice = choice.toUpperCase();
                	if (choice.match(TextString.toUpperCase())) {
                   		MenuField.options[j].selected=1;
                 		if (choices) {options = options + '\n' + choice;}
                   		else if (choices>10) {options = options + '.';}	
                   		else {options = options + choice;}
                   		choices++;
                	}
	  		else if (choice) {eliminate[kills++]=j;}      // eliminate non-matching elements from list            
		}
	  	if (choices && kills) {
               		for (j=kills-1; j>=0; j--) {
                		var kill_index = eliminate[j];
                		if (ReduceMenu > 0) MenuField.options[kill_index] = null;
               		}
	    	}  
		if ((Search || ReduceMenu) && (choices < 1)) {                      // clear search box if items found
       			alert('Nothing found matching ' + TextString);
			f.elements[TextIndex].value = '';
 		}
		else {
 			if (Search && (choices >= 1) ) {                              // if searching, clear search field
               			f.elements[TextIndex].value = '';
				if (ReduceMenu == 0) {
					if (choices > 1) {
					  alert(choices + ' Matching Entries for ' + TextString + ': \n _____________________ \n\n' + options);
					}	
				} else if (choices > 1) {
					alert('popdown Menu reduced to ' + choices + ' option(s)');
				}
 			} else if ((Search == 0) && (choices >=1) ) {                 // trying to add new entry that has a match
               			Warning = 'Warning: Similar Entries Exist: \n _____________________\n\n' + options;
	  			if (Warning != old_warning) {alert(Warning);}  // Only Warn once...
                 		old_warning = Warning;	
               		}  
	  	 } 
             }     
      }           // for 'ForceSearch'
   }        // per form
   return TextString;
}   // function

function HiddenMessage(f,find) {

<!-- This routine sends a text message -->
<!-- displaying whatever follows the string 'find' in all hidden fields -->
<!-- eg. if there is a hidden field: name=>'Data once upon a time' -->
<!--     the message ' once upon a time' would be displayed (when called with find='Data') -->
<!-- This allows a simple method of displaying a large section of text on demand -->

   var value = 0;
   var msg = find + ':\n*********************\n';

   for (var i=0; i<f.length; i++) {
      var e = f.elements[i];            // look at each form in turn...
      var elementName = e.name;
      if ((e.type == 'hidden') && (elementName.search(find)==0)) {
         var right = RegExp.rightContext;
	 if ((right.search(/\d+/) >=0) || (right.search(/[a-zA-Z]/)>=0)) 
		right = right + " = ";
	 var show = e.value;
         if ((show.search(/\d+/) >=0) || (show.search(/[a-zA-Z]/)>=0))
		msg += right + e.value + '\n';
      }  
   }
   alert(msg);
}


<!-- VERY SPECIFIC FUNCTIONS --->
 
function ResetSource(f) {

<!-- This function sets up the ReArray Plate fields particular to the form in 'SDB_Status.pm' -->
<!-- It fills in text fields for the Source Plate, and presets the library -->
<!-- Needed:                                                               -->
<!--         hidden fields Library $request_id:$library_name -->
<!--         radio fields with value = Request ID chosen -->
<!--         text fields 'Replace $request_id:$source_plate' -->
<!--         popup field 'SearchString' -->
<!--         (it fills in the library by filling in the textfield, calling MenuSearch) -->

   var chosen = 'Nothing';
   var msg = 'Messages:\n***********************\n';
   var e;
   var elementName;
   var requestID;
   var plateID;

   for (var i=0; i<f.length; i++) {
      e = f.elements[i];            // look at each form in turn...
      elementName = e.name;
      if ((e.type == 'radio') && (elementName.search(/requestids/i)>=0)) {
         if (e.checked) {
            chosen = e.value; 
         }
      }
   }

   var lib = '';
   for (var i=0; i<f.length; i++) {
      e = f.elements[i];            // look at each form in turn...
      elementName = e.name;

               // ###### replace Source Plate text fields...

      if (elementName.search(/replace (\d+):(\d+)/i) >=0)  {
         requestID = RegExp.$1;
         plateID = RegExp.$2;
         if (requestID == chosen) {e.value = plateID;}
         else {e.value = '';}
      }
      else if (elementName.search(/library (\d+):(.*)/i) >= 0) {
	 var thislib = RegExp.$2;
         if (chosen == RegExp.$1) {
            lib = thislib;
         }
// 	alert('chose lib: ' + lib + elementName);
      }
      else if ((elementName == 'Library') && (e.type == 'select-one')) {
	 for (var j=0; j<e.options.length; j++) {
         	var itemName = e.options[j].value;
		if (lib && (itemName.search(lib)==0)) {
			e.options[j].selected = 1;
			j = e.options.length;
		}
	}
         MenuSearch(f);
      }          
   }
}

function SSHome(thisForm,MenuShrink) {
	
	var sstring = MenuSearch(thisForm,0);	
	var FoundLibrary = 'none';

   	for (var i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i];            // look at each form in turn...
      		var elementName = e.name;
	 	if ((e.type == 'select-one') && (elementName == 'Use Library')) {
	 		for (var j=0; j<e.options.length; j++) {
				if (e.options[j].selected) {
					FoundLibrary = e.options[j].value;
				}
			}
		}
	}

	if (FoundLibrary.length >=5) {
	  FoundLibrary = FoundLibrary.substr(0,5);  // Get chosen Library Name
	  FoundLibrary = 'Max:'+FoundLibrary+',';
          
	  var MaxPlate = 1;
  	  for (i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i];            // look at each form in turn...
      		var elementName = e.name;
		if ((e.type == 'hidden') && (elementName.search(FoundLibrary) == 0)) {	
			MaxPlate = RegExp.rightContext;
		}
	 	else if ((elementName.search(/plate number/i)>=0) 
			&& (e.type == 'select-one') && (MaxPlate>0)) {
				MaxPlate++;
				e.options.length = MaxPlate;
				for (j=1; j<MaxPlate; j++) {
			   		e.options[j].text = j;
				}
		}
	  }
	}
}	

function BrewCalc(thisForm) {
/*
// BrewMix Caluculations...
//
// Let A = ul/well (original volumes...) 
// Let B = Plate Correction (Extra Brew (plates))
// Let C = Extra Brew 2 (extra rxns/overload)
//
// Let P = no. of plates.
// Let ov = overload threshold (overload)
// 
// ... Then Volume = A*(P + B)*96) 
//
// AND   if (P > ov) Volume = Volume + C*(P-ov)
*/ 
	var AddPremix;
	var AddPrimer;
	var AddBuffer;
	var AddWater;
	
	BD4ul = new Array(0.54,0.43,0.26,2.0,4.0,2.0+20.0/96,0,0.0);   // default variables
	BD10ul = new Array(2.0,0.0,0.64,1.5,10.0,94.0/96.0,8.0,2.0);   // default variables
	ET20ul = new Array(8.0,0.0,1.0,6.0,20.0,29.0/96,2.0,1.0);   // default variables (6th was 57/96)
	ETOH = new Array(2.0,0.0,0.0,0.0,62.0,60.0/96,0,5.0);   // default variables


// BD ready mix, 5X reaction buffer, Primer, DNA, Total Volume, Extra Brew (plates), overload, extra rxns/overload 	

	var Plates;
 	var Mixture = 'none';
	var Buffer = 'none';

	for (var i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i];           // look at each form in turn...
      		var elementName = e.name;
		if (elementName == 'Blocks') 
			Plates = parseInt(e.value);     // Get number of plates.
		if ((elementName == 'Mix') && (e.type=='radio') && (e.checked)) 
			Mixture = e.value;
		if ((elementName == 'Mix') && (e.type=='hidden'))
			Mixture = e.value;
		if ((elementName == 'Buffer') && (e.type=='text') && (e.checked) && Mixture.search('10u')>=0) 
			Buffer = parseInt(e.value);		
	}
						
// Set appropriate defaults

	var premix;
	var buffer;
	var primer;
	var prep  ;
	var volume;
	var adjust;
	var overld;
	var extra;

	if (Mixture.search('4u')==0) {
		premix = BD4ul[0];
		buffer = BD4ul[1];
		primer = BD4ul[2];
		prep   = BD4ul[3];
		volume = BD4ul[4];
		adjust = BD4ul[5];
		overld = BD4ul[6];
		extra  = BD4ul[7];
	}
	else if (Mixture.search('10u')==0) {
		premix = BD10ul[0];
		buffer = BD10ul[1];
		primer = BD10ul[2];
		prep   = BD10ul[3];
		volume = BD10ul[4];
		adjust = BD10ul[5];
		overld = BD10ul[6];
		extra  = BD10ul[7];
	}
	else if (Mixture.search('20u')==0) {
		premix = ET20ul[0];
		buffer = ET20ul[1];
		primer = ET20ul[2];
		prep   = ET20ul[3];
		volume = ET20ul[4];
		adjust = ET20ul[5];
		overld = ET20ul[6];
		extra  = ET20ul[7];
	}
	else if (Mixture.search('EtOH')>=0) {
		premix = ETOH[0];
		buffer = ETOH[1];
		primer = ETOH[2];
		prep   = ETOH[3];
		volume = ETOH[4];
		adjust = ETOH[5];
		overld = ETOH[6];
		extra  = ETOH[7];
	}
	
	if (Buffer>0) {
		buffer = Buffer;
	}

	var water = volume - prep - primer - buffer - premix;
	var factor = adjust;
	factor += Plates;
	factor *= 96;
	if (Plates > overld) factor += (Plates-overld)*extra;   // add Extra Brew 2

	Amounts = new Array;
	if (Mixture.search('u')>=0) Amounts = Array(factor*water,factor*premix,factor*primer,factor*buffer);
	else Amounts = Array(factor*water,factor*premix); 	

	var index = 0;
	for (var i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i];            // look at each form in turn...
      		var elementName = e.name;
		if (elementName.search('Std_Quantities')>=0) {
			Qty = Amounts[index]/1000;        // Set to appropriate value
			index++;
			var unit = ' m';
		
			if (Qty > 1000) {Qty /=1000; unit = ' L';}
			else if (Qty == 0) {unit = ' m';}
			else if (Qty < 0.001) {Qty *=1000000; unit = ' n';}
			else if (Qty < 1) {Qty *=1000; unit = ' u';}
			else if (Qty>0) {}			
			else {Qty = '0'; unit = ' m';}
			Qty = parseInt(Qty*100)/100;      // convert to two decimal places...
			e.value = Qty + unit;
		}
	}		
}

function MultiplyBy(thisForm,Field,TargetField,Factor,Decimals, Units) {
/*<!-- This routine is set up to set TargetField = Field X Factor -->
<!-- (Decimals shows the number of decimals -->
<!-- note: previously deciimals was handled differently (use 2 for 2 decimal places - (used to require 100 for 2 decimal places) -->*/
  	
	for (var i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i]   // look at each form in turn...
      		var elementName = e.name;
		if (elementName == Field) {
			var ThisValue = parseFloat(e.value);
		        if (!Units) { 
                            Units = e.value.replace(ThisValue,'') 
                            Units = Units.replace(/^ /,'');
                        }
                }
	}
	

        var NewValue = AutoAdjustUnits(ThisValue*Factor, Units, Decimals);
        
        for (var i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i];  // look at each form in turn...
      		var elementName = e.name;
		if (elementName == TargetField) {
			e.value = NewValue;
		}
	}

}

function AddWithUnits (total, total_units, add, add_units) {

    var base_units = total_units;
   
    var factor;
    if (total_units.match('u')) { factor = parseFloat(1000*1000); }
    else if (total_units.match('m')) { factor = parseFloat(1000); }
    else if (total_units.match('k')) { factor = parseFloat(1/1000); }
    
    var add_factor;
    if (add_units.match('m')) {
        add_factor = parseFloat(1000);
    }
    else if ( add_units.match('u') ) {
        add_factor = parseFloat(1000*1000);
    }
    else if ( add_units.match('n') ) {
        add_factor = parseFloat(1000*1000*1000);
    }
    else if ( add_units.match('p') ) {
        add_factor = parseFloat(1000*1000*1000*1000);
    }
    else if (add.match('k') || add.match('K')) {
        add_factor = parseFloat(1/1000);
    }
    else if (add_units.match('M')) {
        add_factor = parseFloat(1/(1000*1000));
    }
    else if (add_units.match('G')) {
        add_factor = parseFloat(1/(1000*1000*1000));
    }
    else {
        add_factor = parseFloat(1);
    }

    if (add_units.match(base_units)) { }
    factor /= add_factor;
   
    total = parseFloat(add)*factor + parseFloat(total);
    return total;
}

function AutoAdjustUnits (value, units, decimals) {
    
    var AdjustedVal = parseFloat(value);
    var AdjustedUnits = units;
    var Units = new Array('G', 'M', 'K', '', 'm', 'u', 'n', 'p');
  
    AdjustedUnits.replace(/^ /,'');  // clear leading space if applicable 
    var BaseUnits = units;
   
    var unit_index = 0;
    var count = Units.length;
    for (var i=0; i<count; i++) {
        var Unit = Units[i]; 
        if (AdjustedUnits.match(/^$/) && Unit.match(/^$/)) { unit_index = i+1; i = Units.length; }
        else if (Unit && AdjustedUnits.match(Unit)) { 
            unit_index = i+1; 
            i = Units.length; 
            BaseUnits = BaseUnits.replace(Unit,'');    
            BaseUnits = BaseUnits.replace(/^ /,'');
        }
    }
  
    if ( ! unit_index ) { 
        alert(units + ' units not recognized');
        var returnval = value.toString() + ' ' + units;
    }
    else {
        while ( AdjustedVal < 0.1 ) {
            if (unit_index < Units.length - 1) {
                AdjustedVal = parseFloat(1000*AdjustedVal);
                unit_index++;
            }
            else {
                AdjustedUnits = Units[unit_index-1];
                return NumberAsString(AdjustedVal, AdjustedUnits, decimals);
            }
        }
                
        while ( AdjustedVal > 10000 ) {
            if (unit_index > 1) {
                AdjustedVal = parseFloat(AdjustedVal/1000.0);
                unit_index--;
            }
            else {
                AdjustedUnits = Units[unit_index-1];
                return NumberAsString(AdjustedVal, AdjustedUnits, decimals);
            }
        }
        AdjustedUnits = Units[unit_index-1];
        return NumberAsString(AdjustedVal, AdjustedUnits + BaseUnits, decimals);
    }
}

/* This function returns a string when given a value and the units (optional number of decimal places) */
function NumberAsString (value, units, decimals) {
    
    var factor = 1000; //  Math.pow(10,decimals);
    var val =  Math.round(parseFloat(value*factor))/factor;
    
    var string;
    if (units) { 
        string = val.toString() + ' ' + units;
    }
    else { string = val }

    return string;
}

function TrackTotal(thisForm,SearchString,TargetField,IgnoreString) {	
/*<!-- This routine is set up primarily to total volumes.. -->
<!-- (Total is not incremented when entry contains IgnoreString -->
<!-- (this is used to ignore volumes if they are entered in grams) -->*/	
	var TotalSoFar = 0;

        var units_field = SearchString + '_Units';
        var units = document.getElementsByName(units_field);
        var units_index = 0;
       
        var default_units = 'ml';

   	for (var i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i];            // look at each form in turn...
      		var elementName = e.name;
		
                // if ((elementName.match(SearchString))  && e.value) { 
                
                var regex = new RegExp("^" + SearchString + "$"); 
                if ( elementName.match(regex) && e.value) {
                        var ThisValue = e.value;
                        
                        var this_unit;
                        if (units && units.length > units_index) {
                            this_unit = units[units_index].value;
                        }
                        
                        units_index++;
                        
                        if (IgnoreString && (ThisValue.search(IgnoreString)>=0)) {;}
			else { TotalSoFar = AddWithUnits(TotalSoFar, default_units, ThisValue, this_unit) }

		}	
	}

        TotalSoFar = AutoAdjustUnits(TotalSoFar, default_units, 2); 

        for (var i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i];            // look at each form in turn...
      		var elementName = e.name;
		if (elementName == TargetField) {
			e.value = TotalSoFar;
		}
	}
}	

function CalculateTotal(thisForm,SearchString,MultiplyBy,TargetField,Factor,CurrencyField) {
/*<!-- This routine is set up primarily to total costs. -->
<!-- (Total is not incremented when entry contains IgnoreString -->*/

	var TotalSoFar = 0;
	var Times = 0;
	var ThisValue = 0;
	var Currency = 'US';
	var CurrencyFactor=1;

   	for (var i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i];            // look at each form in turn...
      		var elementName = e.name;
		if ((elementName.search(SearchString) == 0)  && e.value) {
			ThisValue = e.value;
		}
		else if ((elementName.search(MultiplyBy) == 0)  && e.value) {
			Times = e.value;
		}
		else if (elementName.search(CurrencyField) == 0) {
			if (e.type=='select-one') {
				for (var j=0; j<e.options.length; j++)
					if (e.options[j].selected) Currency = e.options[j].value;
			}
			else if (e.type=='text') {		
				Currency = e.value;	
			}
		}
	}

	if (Currency.search('Can') == 0) {CurrencyFactor=1}
	else if (Currency.search('US') == 0) {CurrencyFactor=1.5}

	TotalSoFar = ThisValue*Times*Factor*CurrencyFactor;

   	for (var i=0; i<thisForm.length; i++) {
      		var e = thisForm.elements[i];            // look at each form in turn...
      		var elementName = e.name;
		if (elementName == TargetField) {
			e.value = TotalSoFar;
		}
	}
}	

function SetOpenDate(f,ThisDate) {
/*<!-- This routine sets open date depending on type  -->*/
                             
	var SolutionStatus;                 
	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
		var elementName = e.name;

		if (elementName == 'Opened') 
			if (e.checked) SolutionStatus = e.value;
	}	
	
	var SolutionCreated;
	var SolutionReceived;
	
	if (SolutionStatus == 'unopened') {
		SolutionCreated = '0';
		SolutionReceived = ThisDate;
	}
	else if (SolutionStatus == 'opened') {
		SolutionCreated = ThisDate;
		SolutionReceived = ThisDate;
	}
	else if (SolutionStatus == 'made in house') {
		SolutionCreated = ThisDate;
		SolutionReceived = '0';
	}
	
	for (var i=1; i<f.length; i++) {
		var e = f.elements[i];
		var elementName = e.name;

		if (elementName == 'Created') 
			e.value = SolutionCreated
		else if (elementName == 'Purchased')
			e.value = SolutionReceived;
	}
}

function SetMatrixBuffer (f) {
/*<!-- This routine sets type to Buffer/Matrix if appropriate -->*/
	var Buffer = 0;
	var Matrix = 0;
	var Megabace = 0;
	var Biosystems = 1;

	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
		var elementName = e.name;

		if (elementName.search(/name/i) == 0) {
			if (e.type=='text') {
				var Named = e.value;
				if (Named.search(/buffer/i) >= 0)
					Buffer = 1;
				else if (Named.search(/matrix/i) >= 0)
					Matrix = 1;
				else if (Named.search(/pop/i) >= 0)
					Matrix = 1;
				if (Named.search(/megabace/i)>=0)
					Megabace = 1;
				else if (Named.search(/3700/i)>=0)
					Biosystems = 1;
				else if (Named.search(/pop/i) == 0)
					Biosystems = 1;
			} 
			else if (e.type=='select-one') {
				for (var j=0; j<e.options.length; j++) {
					var popupValue = e.options[j].value;
					if ((popupValue.search(/buffer/i)>=0) && e.options[j].selected)
						Buffer = 1;
					else if ((popupValue.search(/matrix/i)>=0) && e.options[j].selected)
						Matrix = 1;
					else if ((popupValue.search(/pop/i)==0) && e.options[j].selected)
						Matrix = 1;
					if ((popupValue.search(/3700/i)>=0) && e.options[j].selected)
						Biosystems = 1;
					else if ((popupValue.search(/pop/i)==0) && e.options[j].selected)
						Biosystems = 1;
					else if ((popupValue.search(/megabace/i)>=0) && e.options[j].selected)
						Megabace = 1;
				}
			} 
		}
		else if (elementName.search(/type/i) == 0) {
			if (e.type=='select-one') {
				for (var j=0; j<e.options.length; j++) {
					var popupValue = e.options[j].value;
					if ((popupValue.search(/buffer/i)==0) && Buffer)
						e.options[j].selected = 1;
					else if ((popupValue.search(/matrix/i)==0) && Matrix)
						e.options[j].selected = 1;
				}		
			}
        	}
	} 
	if (Megabace) SetSelection(f,'Supplier Choice','Amersham Pharmacia Biotech Inc',1); 
	else if (Biosystems) SetSelection(f,'Supplier Choice','Applied Biosystems',1);
	                    
}

function openCustomWindow(s) {
/*
<!-- This routine opens a child window with the html string given -->
<!-- s = Name of the "Select All" checkbox -->
*/

	var wh = window.open('','CustomWindow','toolbar=no,resizable=no,scrollbars=yes,width=250,height=300');	
	var doc = wh.document;
	doc.write("<html>");
	doc.write("<head><script src='/SDB_jsantos/js/SDB.js'></script>");
	doc.write("<LINK rel=stylesheet type='text/css' href='/SDB_jsantos/css/links.css'>");
	doc.write("<LINK rel=stylesheet type='text/css' href='/SDB_jsantos/css/style.css'>");
	doc.write("<LINK rel=stylesheet type='text/css' href='/SDB_jsantos/css/common.css'>");
	doc.write("<LINK rel=stylesheet type='text/css' href='/SDB_jsantos/css/colour.css'></head>");
	doc.write("<center><form name='CustomWindow'><table border=1 width=200>");
	doc.write(s);

	doc.write("</form></center></body></html>");
}

function ToggleCheckBoxes(f,c,id) {
/*
<!-- This routine allows clicking on a "Select All" checkbox and check all the other checkboxes in the same form... -->
<!-- f = Name of the form -->
<!-- c = Name of the "Select All" checkbox -->	 	
*/
	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
	    	if (id && e.id && e.id != id) { continue }   // only perform for id specified if applicable 
		if ((e.type=='checkbox') && (e.name != c)) {
			e.checked = !(e.checked);
		}		
	} 
}

function ToggleNamedCheckBoxes(f,c,n) {
/*
<!-- This routine allows clicking on a "Select All" checkbox and check checkboxes named n* in the same form... -->
<!-- f = Name of the form -->
<!-- c = Name of the "Select All" checkbox -->	
<!-- n = First n letters of the name of the checkboxes (ie Row1,Row2,Row3) -->
*/
	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
		if ((e.type=='checkbox') && (e.name != c) && (e.name.indexOf(n) == 0)) {		
			e.checked = !(e.checked);
		}		
	} 
}

function ToggleRegExpCheckBoxesID(f,c,r) {
/*
<!-- This routine allows clicking on a "Select All" checkbox and check checkboxes matching a regexp in the same form... -->
<!-- f = Name of the form -->
<!-- c = Name of the "Select All" checkbox -->	
<!-- r = regular expression for the id of the checkboxes -->
*/
	var inputArray = f.getElementsByTagName('input');

	for (var i=0; i<inputArray.length; i++) {
		var e = inputArray[i];
                var nameRegExp = new RegExp(r);
		if ((e.type=='checkbox') && (e.name != c) && (nameRegExp.test(e.id))) {		
			e.checked = !(e.checked);
		}		
	} 
}

function ToggleRegExpCheckBoxesName(f,c,r) {
/*
<!-- This routine allows clicking on a "Select All" checkbox and check checkboxes matching a regexp in the same form... -->
<!-- f = Name of the form -->
<!-- c = Name of the "Select All" checkbox -->	
<!-- r = regular expression for the name of the checkboxes -->
*/
	var inputArray = f.getElementsByTagName('input');

	for (var i=0; i<inputArray.length; i++) {
		var e = inputArray[i];
                var nameRegExp = new RegExp(r);
		if ((e.type=='checkbox') && (e.name != c) && (nameRegExp.test(e.name))) {		
			e.checked = !(e.checked);
		}		
	} 
}

function ToggleNamedElements(f,n,value) {
/*
<!-- This routine allows disabling/enabling form elements named n* in the same form. It also clears the values set to the default value -->
<!-- f = Name of the form -->
<!-- n = First n letters of the name of the checkboxes (ie Row1,Row2,Row3) -->
<!-- value = Optional value to set (1=Enable or 2=Disable) -->
*/
	for (var i=0; i<f.length; i++) {
		var e = f.elements[i];
		if (e.name.indexOf(n) == 0) {	
                    if(value) {
                        if(value == 1) {
                            e.disabled = 0;
                        } else if(value==2) {
                            e.disabled = 1;
                        } else {
                            alert('Unknown value!');
                        }
                    } else {
			e.disabled = !(e.disabled);
                    }

                    if(e.disabled) {
                        if(e.value) {
                            e.setAttribute('OldValue',e.value);
                        }
                        e.value = '';	
                    } else {
                        if(e.hasAttribute('OldValue')){
                            e.value = e.getAttribute('OldValue');
                        }
                        e.removeAttribute('OldValue');
                    }
		}		
	} 
}

// Controls form elements underneat an object
// object:      The head node of which form elements underneat will be controlled
// value:       0=Toggle
//              1=Enable
//              2=Disable
function ToggleFormElements(object_id,value,pattern) {
        var object = document.getElementById(object_id);
        var dis=0;
        var en=0;
        var tog=0;
	for (var j=0;j<formElementTypes.length;j++) {
            var list = object.getElementsByTagName(formElementTypes[j]);
            for (var i=0;i<list.length;i++) {
                if(list[i].getAttribute('structname')) {
                    var structname = list[i].getAttribute('structname');
                    if(structname.indexOf(pattern+'.')==0 ) {
                        if(value == 2) {
                            list[i].disabled = 1;
                            //dis++;
                        } else if(value == 1) {
                            list[i].disabled = 0;
                            //en++;
                        } else {
                            list[i].disabled = !(list[i].disabled);
                            //tog++;
                        }
                    }
                }
            }
	}
        // alert('Disabled: ' + dis + ', Enabled: ' + en + ', Togged: ' + tog);
}

function disableElement (id, message) {
    var object = document.getElementById(id);
    var name   = object.value;
    // object.blur();
    object.disabled = true;
    object.style.display = 'none';
    if (message) { alert(message) }
}

function enableElement (id, message) {
    var object = document.getElementById(id);
    var name   = object.value;
    object.disabled = false;
    object.style.display = 'block';
    if (message) { alert(message) }
}

function NetscapeEventHandler_KeyDown(e) {
<!-- This routine is fired when user pressed the keyboard with the Netscape/Mozilla browser... -->
<!-- e = the actual event; in this case it will be Event.KEYDOWN -->
  if (e.which == 13 && e.target.type != 'textarea' && e.target.type != 'submit') {
    allow_submit = false;
    return false;
  }
  else {
    allow_submit = true;
    return true;
  }
}

function MicrosoftEventHandler_KeyDown() {
<!-- This routine is fired when user pressed the keyboard with the Internet Explorer browser... -->
  if (event.keyCode == 13 && event.srcElement.type != 'textarea' && event.srcElement.type != 'submit') {
    allow_submit = false;
    return false;
  }
  else {
    allow_submit = true;
    return true;
  }
}

function NetscapeEventHandler_MouseDown(e) {
<!-- This routine is fired when user clicked a mouse button with the Netscape/Mozilla browser... -->
<!-- e = the actual event; in this case it will be Event.MOUSEDOWN -->
  allow_submit = true;
  return true;
}

function MicrosoftEventHandler_MouseDown() {
<!-- This routine is fired when user clicked a mouse button with the Internet Explorer browser... -->
  allow_submit = true;
  return true;
}

function allowSubmit() {
<!-- This routine returns whether we are allowing the form to submit. This route is called by the onSubmit event of the HTML <FORM> tag... -->
  return allow_submit;
}

function goTo(url,addons,newwin) {
<!-- This routine redirects the current browser window to the new URL... -->
<!-- url = the new URL to be redirected to -->
<!-- addons = extra parameters to be appended to the URL -->
<!-- newwin = if a nonzero value is passed then the destination URL will be opened in a new window. -->
  if (addons != '-') { //If the addons is just '-' then do not redirect
        if (newwin) {
                window.open(url + addons,'alDente','height=800,width=1000,scrollbars=yes,resizable=yes,toolbar=yes,location=no,directories=no');	
        }
        else {
                document.location = url + addons;
        }
  }
}

//Gets the value of the specified form element.
function getElementValue(f,name,missing_ok, index) {
        
        var array = document.getElementsByName(name);
        var obj;
        
        if (array.length == 0) { 
            obj   = document.getElementById(name);
        }
        else if (array.length == 1) {
            obj = array[0];
        }
        else if ( (array.length > 1) &&  (index || index == 0) ) { 
                obj = array[index];
                array = [obj];
        }
        else {
            // no single element identified - return array values 
            if (array[0].type == 'radio') { 
                // radio or checkbox probably //
                return getCheckedValue(array); 
            }
            else if (array[0].type == 'text') {
                // standard text field 
                return array[0].value;    
            }
            else if (array[0].type == 'checkbox') {
                var List = getCheckedValue(array);
                return List;
            }
            else { 
                return array[0].value;    
    			alert('Need to upgrade to support' + array[0].type + ' types'); 
                return '';
            }
        }
        
        // continuing if single obj element identified... 
        if (obj == null) { 
            if (missing_ok) { return missing_ok }   // .. not used in any calls... not sure if this makes sense...
            return '';
        }
        else {
            if (obj.type == 'select-one') {
                for (var k=0; k < obj.length; k++) {
                    if (obj[k].selected == true) {
                        return obj[k].value;
                    }
                }
                return '';
            }
            else if (obj.type == 'text') {
                return obj.value; 
            }
            else if (obj.type == 'select-multiple') {
                var List = new Array();
                for (var k=0; k < obj.length; k++) {
                    if (obj[k].selected == true) {
                        List.push(obj[k].value);                    
                    }
                }
                var list_string = List.join(',');
                return list_string;
            }
            else {
                alert('unidentified type: ' + obj.type);
                return '';
            }
        }
}

//This function submit a form by using JavaScript. This allow control of properties of target window.
function submitForm(f,newwin) {
	if (newwin) {
		window.open('','alDente','height=800,width=1000,scrollbars=yes,resizable=yes,toolbar=yes,location=no,directories=no');
	}
	f.submit();
}

function showBranch(branch,disable_if_collapsed,pattern) {
      //branch: element ID of the branch to be displayed
      //disable_if_collapsed: If passed in as 1, will disable/enable the block when it is being hidden/displayed
      var objBranch = document.getElementById(branch);
      if(objBranch.style.display=="block") {
         objBranch.style.display="none";
	 if(disable_if_collapsed) {ToggleFormElements(branch,2,pattern);}
      } else {
         objBranch.style.display="block";
         if(disable_if_collapsed) {ToggleFormElements(branch,1,pattern);}
      }
}

function swapVisibility(id) {

    var element = document.getElementById(id);
       var v1 = element.style.display;

       if (v1 == 'none') {
           element.style.display = '';
       }
       else {
           element.style.display = 'none';
       }
}

function swapFolder(img, closedimg, openimg, closed_text, open_text) {

	var openImg = new Image();
	openImg.src = openimg;
   	var closedImg = new Image();
   	closedImg.src = closedimg;

      objImg = document.getElementById(img);
      if (objImg.src == closedImg.src) {
         objImg.src = openImg.src;

         // optionally toggle the display status of the open and closed title if supplied 
         if (open_text) {
             var otext = document.getElementById(open_text);
             if(otext!=null){otext.style.display = '';}
         }
         if (closed_text) {
             var ctext = document.getElementById(closed_text);
             if(ctext!=null){ctext.style.display = 'none';}
         }
      }
      else {
         objImg.src = closedImg.src;
         if (open_text) {
             var otext = document.getElementById(open_text);
             if(otext!=null){otext.style.display = 'none';}
         }
         if (closed_text) {
             var ctext = document.getElementById(closed_text);
             if(ctext!=null){ctext.style.display = '';}
         }
      }

}
      
      
function ToggleVisibility (obj1, type) {
    
      var E1 = document.getElementById(obj1);
      var Etype = type || 'block';
      var v1 = E1.style.display;
      
      if (v1 == 'none') {
          E1.style.display = Etype;
      } 
      else if (v1 == Etype) {
          E1.style.display = 'none';
      }
      else {
          E1.style.display = 'none';
          alert('unrecognized style display: ' + v1);
      }
}

function activateBranch(branch, key, hlcolor,bgcolor) {
    var elem = document.getElementById(branch).style;
    var divList = document.body.getElementsByTagName("div");    

    if (document.openBranch == branch) {
	return;
    }
    for (var i = 0; i < divList.length; i++){
	var e = divList[i];

        if (e.id){        
	    var a = e.id;
	    var searchstring = 'layer' + key;

            if (a.search(searchstring) >=0){
	 
            a.search(/(\d+)/i);
            var b = RegExp.$1;
            if (b > 0) {
		e.style.display = "none";
	        var code = key + b;
              
	   	var tdelement = document.getElementById(code).style;
 		tdelement.backgroundColor = bgcolor;
	    
            }
	    }
        }
	
    }
   
    branch.search(/(\d+)/i);
   
    var code = key + RegExp.$1;

    var tdelement = document.getElementById(code).style;
    var bgcolour = tdelement.backgroundColor;
    tdelement.backgroundColor = hlcolor;
    elem.display = 'block';

}

function highlightCell(branch) {
    var elem = document.getElementById(branch).style;
    element.backgroundColor='#ffcc33';
}

function hideBranch(branch) {
    var elem = document.getElementById(branch).style;
    elem.display = 'none';
}

function show_unique(f,key,closedimg,openimg) {

	var spanList = document.body.getElementsByTagName("span");
	
	for (var i=0; i<spanList.length; i++) {
		var e = spanList[i];
		var a = e.id;
		if (e.id){
		 	a.search(/(\d+)(.*)/i);	
			var fol = "Folder"+ RegExp.$1;
			var b = RegExp.$2;
			if (b == key){
			var st = e.style;
			if (st) {
				if(st.display=="block"){
        			 st.display="none";}
				else{
				 st.display="block";
				}
					
      				swapFolder(fol, closedimg,openimg);
			}	
			}
		}
	}
}

// START OF DHTML table sort functions

// function to get the text value of an html element
function getTextValue(el) {

  var i;
  var s;

  // define for browsers which do not support these node types
  if (document.ELEMENT_NODE == null) {
    document.ELEMENT_NODE = 1;
    document.TEXT_NODE = 3;
  }

  // Find and concatenate the values of all text nodes contained
  // within the element.
  s = "";

  // return '~' if undefined element sort as last (it has a higher ascii value than digits or alpha characters) 
  if ( typeof el === 'undefined' ) { return normalizeString('~'); }

  for (i = 0; i < el.childNodes.length; i++) {
    switch (el.childNodes[i].nodeType) {
      case document.TEXT_NODE:
        s += el.childNodes[i].nodeValue;
        break;
      case document.ELEMENT_NODE:
        if (el.childNodes[i].tagName == "BR") {
          s += " ";
        }
        else {
	  s += getTextValue(el.childNodes[i]);
        } 
        break;
    }
  }

  return normalizeString(s);
}

// function to remove multiple whitespace from a string
function normalizeString(s) {
  // Regular expressions for normalizing white space. 
  var whtSpEnds = new RegExp("^\\s*|\\s*$", "g");
  var whtSpMult = new RegExp("\\s\\s+", "g");

  s = s.replace(whtSpMult, " ");  // Collapse any multiple whites space.
  s = s.replace(whtSpEnds, "");   // Remove leading or trailing white
                                  // space.
  return s;
}


// function to compare two values (alphabetic or numeric)
function compareValues(v1, v2, a, col) {
  var f1, f2;

  // first, remove dashes (this is for dates)
  var dashRemoval = new RegExp("\-", "g");
  v1 = v1.replace(dashRemoval,"").toUpperCase();
  v2 = v2.replace(dashRemoval,"").toUpperCase();

  // If the values are numeric, convert them to floats.
  f1 = parseFloat(v1);
  f2 = parseFloat(v2);
  if (!isNaN(f1) && !isNaN(f2)) {
    v1 = f1;
    v2 = f2;
  }

  var ret = 0;
  // Compare the two values.
  if (v1 == v2)
    ret = 0;
  if (v1 > v2)
    ret = 1
  if (v1 < v2)
    ret = -1;
  if (a.reverseSort[col]) {
	ret = -ret;
  }
  return ret;
}


/*
// prototype a swap function for Moz or Firefox
Node.prototype.swapNode = function (node) {
  var nextSibling = this.nextSibling;
  var parentNode = this.parentNode;
  node.parentNode.replaceChild(this, node);
  parentNode.insertBefore(node, nextSibling);  
}
*/

/* Idea for sorting, and row swapping code from http://www.kryogenix.org/code/browser/sorttable/ */
function mergesort(col, tableName, mode) {
	// if mode is not 1, then it is a regular alphanumeric merge sort
        // so for example: A01 B02 B01 A02 is sorted to A01 A02 B01 B02
	// usage: onclick='return mergesort(0,78672672)'

	// if mode is 1, then the sort will swap digits and non-digits first and then sort with a smart sort
        // so for example: A01 B02 B01 A02 is sorted to A01 B01 A02 B02 
	// usage: onclick='return mergesort(0,78672672, 1)'

	// mode is passed to mergesort_helper and then passed to merge and then if mode == 1, uses smart_cmp (the smart sort) and else uses compareValues (the regular alphnumeric sort

	// Get the table section to sort.
	var tblEl = document.getElementById(tableName);
	
	// Set up an array of reverse sort flags, if not done already.
	if (tblEl.reverseSort == null) {
		tblEl.reverseSort = new Array();
	}

	// If this column was the last one sorted, reverse its sort direction.
	if (col == tblEl.lastColumn || !tblEl.lastColumn) 
		tblEl.reverseSort[col] = !tblEl.reverseSort[col];

	// Remember this column as the last one sorted.
	tblEl.lastColumn = col;
	
	// Set the table display style to "none" - necessary for Netscape 6 
	// browsers.
	var oldDsply = tblEl.style.display;
	tblEl.style.display = "none";

	// copy to auxilliary array first, sort, then rebuild table
        var i;
	var auxArray =  new Array(tblEl.rows.length);
        
	for (i = 0; i < tblEl.rows.length; i++) {
		auxArray[i] = tblEl.rows[i];
	}

	mergesort_helper(tblEl, col, auxArray, 0, (tblEl.rows.length - 1), mode);

        for (i = 0; i < tblEl.rows.length; i++) {
		tblEl.appendChild(auxArray[i]);
	}
	
	// Restore the table's display style.
	tblEl.style.display = oldDsply;

	return false;
}

function mergesort_helper (table,col, array, left, right, mode) {
    	var length, middle;


	if ( left < right ) {
		middle =  parseInt( (left + right) / 2);

		mergesort_helper(table,col,array,left,middle,mode);
		mergesort_helper(table,col,array,middle+1,right,mode);
		merge(table,array, col, left, middle, right,mode);
	}
}

function merge (table,a, col, left, middle, right, mode) {

    var i, j, k;

    i=0; 
    j=left;
    // create auxiliary array b
    var b = new Array();
    // copy first half of array a to auxiliary array b
    while (j <= middle) {
	 b[i++]=a[j++];
    }

    i=0; 
    k=left;
 
    // copy back next-greatest element at each time
    while ( (k < j) && (j <= right) ) {
         var v1, v2;

	 v1 = getTextValue(b[i].cells[col]);
         v2 = getTextValue(a[j].cells[col]);
	 
	 var cmp;
 	 if (mode==1) {
		var myRegExp = /(\D+)(\d+)/;
		v1 = v1.replace(myRegExp, "$2$1");
		v2 = v2.replace(myRegExp, "$2$1");
		cmp = smart_cmp(v1,v2,table,col);
	 }
	 else {
		cmp = compareValues(v1,v2,table,col);
	 }
	 if (cmp >= 0) {
	     a[k++]=b[i++];
         }
	 else {
	     a[k++]=a[j++];
         }
    }


    // copy back remaining elements of first half (if any)
    while (k<j) {
	 a[k++]=b[i++];
    }
}


// insertion sort algorithm
function sortTable(col,tableName) {

  // Get the table section to sort.
  var tblEl = document.getElementById(tableName);

  // Set up an array of reverse sort flags, if not done already.
  if (tblEl.reverseSort == null)
    tblEl.reverseSort = new Array();

  // If this column was the last one sorted, reverse its sort direction.
  if (col == tblEl.lastColumn)
    tblEl.reverseSort[col] = !tblEl.reverseSort[col];

  // Remember this column as the last one sorted.
  tblEl.lastColumn = col;

  // Set the table display style to "none" - necessary for Netscape 6 
  // browsers.
  var oldDsply = tblEl.style.display;
  tblEl.style.display = "none";

  // Sort the rows based on the content of the specified column
  // using a selection sort.

  var tmpEl;
  var i, j;
  var minVal, minIdx;
  var testVal;
  var cmp;

  for (i = 0; i < tblEl.rows.length - 1; i++) {

    // Assume the current row has the minimum value.
    minIdx = i;
    minVal = getTextValue(tblEl.rows[i].cells[col]);

    // Search the rows that follow the current one for a smaller value.
    for (j = i + 1; j < tblEl.rows.length; j++) {

      testVal = getTextValue(tblEl.rows[j].cells[col]);

      cmp = compareValues(minVal, testVal,tblEl, col);

      // If this row has a smaller value than the current minimum,
      // remember its position and update the current minimum value.
      if (cmp > 0) {
        minIdx = j;
        minVal = testVal;
      }
    }

    // By now, we have the row with the smallest value. Remove it from
    // the table and insert it before the current row.
    if (minIdx > i) {
      tmpEl = tblEl.removeChild(tblEl.rows[minIdx]);
      tblEl.insertBefore(tmpEl, tblEl.rows[i]);

    }
  }

  // Restore the table's display style.
  tblEl.style.display = oldDsply;

  return false;
}


/* replaced with simpler method in LampLite.js since Search Filter boxes are deprecated */
function phased_out_clearForm(f, x_ids, y_ids) {
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
        
        
        if (y_ids[0]) {
            // matrix list of form elements (format assumed to be 'x.y' for each x, y value provided
            getSearchFilterValue(xName + '.' + y_id_array[0], '');  // set first value to blank
            
            
            
            for (var y=1; y<y_id_array.length; y++) {
                var yName = y_id_array[y];  
                cellName = xName + '.' + yName;
                getSearchFilterValue(cellName, "''");
            }
        }
        else {
            // single list of form elements 
            getSearchFilterValue(xName, '');
        }
    }

   return;
}

/* replaced with simpler method in LampLite.js since Search Filter boxes are deprecated */
function phased_out_autofillForm (f, x_ids, y_ids) {
// provide comma-delimited lists of column names and row names
// element names will be assumed to be in format 'xname.yname' for each cell (and 'xname.yname Choice' for filtering)
//
//    	alert('found Elements: ' + x_ids + ' + ' + y_ids);
	
    var x_id_array = x_ids.split(',');
    var y_id_array = y_ids.split(',');
    
    for (var x=0; x<x_id_array.length; x++ ) {
        var xName = x_id_array[x];
        var cell_above = '';  
        for (var y=0; y<y_id_array.length; y++) {
            var yName = y_id_array[y];  
		    cellName = xName + '.' + yName;
		    var cell = getSearchFilterValue(cellName);

//	        if (cell && cell.length > 0) { alert(cellName + ' cell (' + x + y + ') = ' + cell ) }
		    if (!cell) { cell = '' }
		    
		    if (cell.match(/^''$/)) {
		        // set cell to value above if current value = '' (even if cell above is blank) 
		            cell = cell_above;
		            getSearchFilterValue(cellName, cell);
	        }		    
		    cell_above = cell;
	    }
    }
}

/* replaced with simpler method in LampLite.js since Search Filter boxes are deprecated */
function getSearchFilterValue (name, value) {   
    
//    var text = document.getElementById(name);    
//    var choice = document.getElementById(name + ' Choice');
    
    var text_element;
    var choice_element;

    var text = document.getElementsByName(name); 
    var alt_names = Array(name + ' Choice', name + '.Choice');
    
    var size = text.length;
    if (size) { 
        text_element = text[0];
    }
    else {
        text_element = document.getElementById(name);
        if (! text_element) { return; }
    }
    
    var alt_name;
    var alt_element;
    for (var i=0; i<alt_names.length; i++) {
        var  alt_id = document.getElementById(alt_names[i]);
        if ( alt_id ) {
            alt_element = alt_id;
            alt_name = alt_names[i];
            i = alt_names.length;
        }
    }
    if ( ! alt_element) {
        // if alternate element id not found, check alternate element names ... //
        for (var i=0; i<alt_names.length; i++) {
            var alt_elements = document.getElementsByName(alt_names[i]);
            if ( alt_elements.length && alt_elements.length < 2 ) {
                alt_name = alt_names[i];
                alt_element = alt_elements[0];
            }
        }
    }
   
    if (value == undefined || value == null ) { 
        // no value specified ... just retrieve value 
    }
    else {       
        if  ( alt_element ) { 
            if (alt_name.match('Choice')) { set_dropdown(alt_element, value, 1) }
            else { alt_element.value = value }
            
            set_autocomplete(alt_element, value, 1);
        }
        else {
            text_element.value = value;
        }
    }

    if (text_element.value && trim(text_element.value).length > 0) { return text_element.value }
    else {
        // check alternate names 
        if (alt_name) {
            var alt_val = getElementValue(this.form, alt_name);
            return alt_val;
        }
    }
    //( choice_element ) { return choice_element.value }
    return ''; 
}

function set_autocomplete (element, value, split) {
// set autocomplete values from autofill (need to populate options first)    
    var selectID = element.id;
    
    //alert('check for autocomplete with id = ' + selectID);
    
    var divID = selectID.replace("Choice","Autocomplete");
    var autoElement = document.getElementById(divID);
    
    // If element is an autocomplete list, 
    // add the repeated value to the list if it isn't there already
    if (element.nodeName == "SELECT" && element.getAttribute('name').match(/Choice/) && autoElement) {
       set_dropdown(element, value, split);
    }   
    else { element.value = value }
    
    return value;
}


function set_dropdown (element, value, split) {
// set value (used for autocomplete or dropdown list //
    var values = new Array();
        if (split) {
            // just in case we wish to set multiple values at one time 
            values = value.split(',');
        }
        else {
            values.push(value);
        }
        
        // first clear current list of items //
        for (var n = 0; n < element.options.length; n++) {
            element.options[n].selected = false;
        }

        for (var j=0; j<values.length; j++) {
            var found = false;
            var v = values[j];
            for (var n = 0; n < element.options.length; n++) {
                if (element.options[n].value == v) {
                    element.options[n].selected = true;
                    found = true;
                }
            }
            if (found == false) {
                element.options[element.options.length] = new Option(v,v);
                element.options[element.options.length - 1].selected = true;
            }
        }
    
    return element;
}

function populateDropdown(f, element, list) {
   var options = list.split(',');
   for (var i=0; i < options.length; i++) {
       element.options.push(options[i]);
       element.options[element.options.length] = new Option(options[i], options[i]);
   } 
}


//
//  This script _HAS_ to be called from whitin expandable_input() function
//  Error checkings are done there.
//
function get_options(objname,elements,option_type,keys,labels,headers,propmode) {
 	//objname:            expandable input object
	//elements:           elements for this object field
	//option_type:	      input type for available options (textfield or dropdown)
	//keys:               keys for available options
	//lables:	      lables for available options
	//headers:            headers for options
	//propmode:	      Propagate mode (0: No propagate, 1: Normal Propagate, 2:Incremental Propagate, 3:All)

	var flag_id = objname + '_windowOpen';
	var initials = '0';

	//Default values
	if(document.getElementById(objname).value!='')
		initials = document.getElementById(objname).value.split(',');

	//Flag element to find out if the window is open or no
	var flag = document.getElementById(flag_id);
	if(flag.value == 1) {
		wh = window.open('','GetValues: ' + objname);
		wh.focus();
		return;
	} else {
		wh = window.open('','GetValues: ' + objname,'toolbar=no,resizable=no,scrollbars=yes,width=250,height=300');
		//wh.moveTo(600,200);
		flag.value = 1;
	}

	//Start creating the popup window
	var doc = wh.document;
	doc.write("<html>");

	// Include this current javascript file in the newly created page
	doc.write("<head><script src='/" + URL_version + "/js/SDB.js'></script></head>");

	doc.write("<body onUnload=finish_popup('" + flag_id + "')>");
	doc.write("<center><form name='options'><table border=1 width=200>");
	doc.write("<tr><th>" + headers[0] + "</th><th>" + headers[1] + "</th></tr>");

	if(option_type == 'dropdown') {
		for(var i=0;i<elements.length;i++){
			doc.write("<tr><td><center>" + elements[i] + "</center></td>");
			doc.write("<td><center>");
			doc.write("<select name=" +elements[i]);
			if(propmode)
				doc.write(" onChange=propagate(this," + propmode + ",['" + keys.join("','") + "'])");
			doc.write(">");
			for (var j=0;j<keys.length; j++) {
				doc.write("<option value='" + keys[j] +"'");
				if(initials[i] == keys[j])
					doc.write(" selected='" + keys[j] + "'");
				doc.write(">" + labels[j] + "\n");
			}
			doc.write("</select></center></td></tr>");
		}

	} else if(option_type == 'text') {
		for(var i=0;i<elements.length;i++){
			doc.write("<tr>");
			doc.write("<td><center>" + elements[i] + "</center></td>");
			doc.write("<td><center>");
			doc.write("<input type='text' onDblClick=\"this.value=''\"");
			if(initials[i])
				doc.write("value='" + initials[i] + "'");
			if(propmode)
				doc.write(" onChange=propagate(this," + propmode + ")");
			doc.write("></td></tr>");
		}
	}

	doc.write("</table><br><input type='button' value='Cancel' onClick=finish_popup('" + flag_id + "')>&#160;&#160;&#160;");
	doc.write("<input type='button' value='OK' onClick=finish_popup('" + flag_id + "','" + objname + "')></form></center></body></html>");
}

function propagate(obj,mode,keys) {
	//mode: 1 for normal
	// 	2 for incremental
	//	3 all
	var position;
	if(mode == 3) {
		position=0;
	} else {
		for(var i=0;i<document.options.elements.length;i++) {
			if(document.options.elements[i] == obj) {
				position = i;
				break;
			}
		}
	}

	if(mode == 2) {
		var currVal = obj.value;
		var valPos;
		keys.splice(0,1); //remove the leading white space element

		//Get the position of the current element in the array
		for(var j=0;j<keys.length;j++) {
			if(currVal == keys[j]) {
				valPos=j;
				break;
			}
		}
		for(var i=position;i<document.options.elements.length;i++)
			if(obj.type == document.options.elements[i].type)
				document.options.elements[i].value = keys[valPos++%keys.length];
	} else 
		for(var i=position;i<document.options.elements.length;i++)
			if(obj.type == document.options.elements[i].type)
				document.options.elements[i].value = obj.value;
}

function finish_popup(flag_id,name) {
	window.close();
	opener.document.getElementById(flag_id).value=0;
	if(name!=null)
		opener.document.getElementById(name).value=get_values();
}


function swap_option_values(mylist,mylist1){
        var e = document.getElementById(mylist);
    var e1 = document.getElementById(mylist1);

        for (var i = 0; i< e.options.length; i++ )
        {
                if (e.options[i].selected)
                {
                        var t = e.options[i].text;
                        var v = e.options[i].value;
                        e1.options[e1.options.length] = new Option(t,v);
                }
        }
        for (var j = 0; j <e1.options.length;j++ )
        {
            var n = e1.options[j].text;
                for (var k = 0; k<e.options.length; k++ )
                {
                        if (e.options[k].text == n)
                        {
                                e.options[k] = null;
                        }
                }
        }
    //jQuery("select").trigger('chosen:updated');
}
function select_all_options(mylist){
        var e = document.getElementById(mylist);
        for (var i = 0; i<e.options.length;i++ )
        {
                e.options[i].selected = true;
        }
    //jQuery("select").trigger('chosen:updated');
}

function move_selected_options(mylist,down) {

    var e = document.getElementById(mylist);
    var sindex = e.options.selectedIndex;

    if (sindex == -1) {
        return false;
    } else {
        var j;
        if (down) {
            if (sindex != e.options.length - 1)
                j = sindex + 1;
            else
                return false;
        }
        else {
            if (sindex != 0)
                j = sindex - 1;
            else
                return false;
        }
    }

    var swapOption = new Object();
    swapOption.text = e.options[sindex].text;
    swapOption.value = e.options[sindex].value;
    swapOption.selected = e.options[sindex].selected;
    swapOption.defaultSelected = e.options[sindex].defaultSelected;
    var anIndex = sindex;
    for (var property in swapOption)
      e.options[anIndex][property] = e.options[j][property];
    for (var property in swapOption)
      e.options[j][property] = swapOption[property];

    return false;
}





function get_values() {
	var result;
	var size = document.options.elements.length;
	regEx = /,/g;
	for(var i=0;i<size;i++) 
		if(document.options.elements[i].type != 'button') {
			val = document.options.elements[i].value.replace(regEx,';');
			if(result)
				result = result + ',' + val;
			else
				if(val)
					result = val;
				else
					result = ' '; //To fix the first element bug
		}
	return result;
}

function highlightChanged(o) {
    if(o.hasAttribute('defaultValue')) {
        if(o.value != o.getAttribute('defaultValue')) {
            o.style.backgroundColor='#FC3';
        } else {
            o.style.backgroundColor='';
        }
    }

}

function saveWells(f,p) {
    document.getElementById('WellsForPlate' + p).value = '';

    var wellArray = f.getElementsByTagName('input');
    var count = 0;
    for (var i=0; i< wellArray.length; i++) {
        var e = wellArray[i];
        var nameExp = new RegExp('AssignPlate'+ p + 'Well.*');
        if (nameExp.test(e.id)) {
	    if ( e.checked ) {
                if ( count == 0) {
		    document.getElementById('WellsForPlate' + p).value = e.value;
                }
		else {
		    document.getElementById('WellsForPlate' + p).value = document.getElementById('WellsForPlate' + p).value + ',' + e.value;
                }
                count = count + 1;
            }
	}		
    }
    return false;
}

// Title: Timestamp picker
// Description: See the demo at url
// URL: http://us.geocities.com/tspicker/
// Script featured on: http://javascriptkit.com/script/script2/timestamp.shtml
// Version: 1.0
// Date: 12-05-2001 (mm-dd-yyyy)
// Author: Denis Gritcyuk <denis@softcomplex.com>; <tspicker@yahoo.com>
// Notes: Permission given to use this script in any kind of applications if
//    header lines are left unchanged. Feel free to contact the author
//    for feature requests and/or donations

function show_date_calendar(str_target, str_datetime, img_loc) {
	var arr_months = ["January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"];
	var week_days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
	var n_weekstart = 1; // day week starts from (normally 0 or 1)

	var dt_datetime = (str_datetime == null || str_datetime =="" ?  new Date() : str2d(str_datetime));
	var dt_prev_month = new Date(dt_datetime);
        var img_path = img_loc;
	dt_prev_month.setMonth(dt_datetime.getMonth()-1);
	var dt_next_month = new Date(dt_datetime);
	dt_next_month.setMonth(dt_datetime.getMonth()+1);
	var dt_firstday = new Date(dt_datetime);
	dt_firstday.setDate(1);
	dt_firstday.setDate(1-(7+dt_firstday.getDay()-n_weekstart)%7);
	var dt_lastday = new Date(dt_next_month);
	dt_lastday.setDate(0);
	
	// html generation (feel free to tune it for your particular application)
	// print calendar header
	var str_buffer = new String (
		"<html>\n"+
		"<head>\n"+
		"	<title>Calendar</title>\n"+
		"</head>\n"+
		"<body bgcolor=\"White\">\n"+
		"<table class=\"clsOTable\" cellspacing=\"0\" border=\"0\" width=\"100%\">\n"+
		"<tr><td bgcolor=\"#4682B4\">\n"+
		"<table cellspacing=\"1\" cellpadding=\"3\" border=\"0\" width=\"100%\">\n"+
		"<tr>\n	<td bgcolor=\"#4682B4\"><a href=\"javascript:window.opener.show_date_calendar('"+
		str_target+"', '"+ dt2dtstr(dt_prev_month)+"','"+ img_path + "');\">"+
		"<img src=\""+img_path+"prev.gif\" width=\"16\" height=\"16\" border=\"0\""+
		" alt=\"previous month\"></a></td>\n"+
		"	<td bgcolor=\"#4682B4\" colspan=\"5\">"+
		"<font color=\"white\" face=\"tahoma, verdana\" size=\"2\">"
		+arr_months[dt_datetime.getMonth()]+" "+dt_datetime.getFullYear()+"</font></td>\n"+
		"	<td bgcolor=\"#4682B4\" align=\"right\"><a href=\"javascript:window.opener.show_date_calendar('"
		+str_target+"', '"+dt2dtstr(dt_next_month)+"','"+ img_path + "');\">"+
		"<img src=\""+img_path+"next.gif\" width=\"16\" height=\"16\" border=\"0\""+
		" alt=\"next month\"></a></td>\n</tr>\n"
	);

	var dt_current_day = new Date(dt_firstday);
	// print weekdays titles
	str_buffer += "<tr>\n";
	for (var n=0; n<7; n++)
		str_buffer += "	<td bgcolor=\"#87CEFA\">"+
		"<font color=\"white\" face=\"tahoma, verdana\" size=\"2\">"+
		week_days[(n_weekstart+n)%7]+"</font></td>\n";
	// print calendar table
	str_buffer += "</tr>\n";
	while (dt_current_day.getMonth() == dt_datetime.getMonth() ||
		dt_current_day.getMonth() == dt_firstday.getMonth()) {
		// print row heder
		str_buffer += "<tr>\n";
		for (var n_current_wday=0; n_current_wday<7; n_current_wday++) {
				if (dt_current_day.getDate() == dt_datetime.getDate() &&
					dt_current_day.getMonth() == dt_datetime.getMonth())
					// print current date
					str_buffer += "	<td bgcolor=\"#FFB6C1\" align=\"right\">";
				else if (dt_current_day.getDay() == 0 || dt_current_day.getDay() == 6)
					// weekend days
					str_buffer += "	<td bgcolor=\"#DBEAF5\" align=\"right\">";
				else
					// print working days of current month
					str_buffer += "	<td bgcolor=\"white\" align=\"right\">";

				if (dt_current_day.getMonth() == dt_datetime.getMonth())
					// print days of current month
					str_buffer += "<a href=\"javascript:window.opener."+str_target+
					".value='"+dt2dtstr(dt_current_day)+"'; window.close();\">"+
					"<font color=\"black\" face=\"tahoma, verdana\" size=\"2\">";
				else 
					// print days of other months
					str_buffer += "<a href=\"javascript:window.opener."+str_target+
					".value=\'"+dt2dtstr(dt_current_day)+"\'; window.close();\">"+
					"<font color=\"gray\" face=\"tahoma, verdana\" size=\"2\">";
                                str_buffer += dt_current_day.getDate()+"</font></a></td>\n";
				dt_current_day.setDate(dt_current_day.getDate()+1);
		}
		// print row footer
		str_buffer += "</tr>\n";
	}
	// print calendar footer
	str_buffer +=
		//"<form name=\"cal\">\n<tr><td colspan=\"7\" bgcolor=\"#87CEFA\">"+
		//"<font color=\"White\" face=\"tahoma, verdana\" size=\"2\">"+
		//"Time: <input type=\"text\" name=\"time\" value=\""+dt2tmstr(dt_datetime)+
		//"\" size=\"8\" maxlength=\"8\"></font></td></tr>\n</form>\n" +
		"</table>\n" +
		"</tr>\n</td>\n</table>\n" +
		"</body>\n" +
		"</html>\n";

	var vWinCal = window.open("", "Calendar","width=200,height=250,status=no,resizable=yes,top=200,left=200");
	vWinCal.opener = self;
	var calc_doc = vWinCal.document;
	calc_doc.write (str_buffer);
	calc_doc.close();
}

function show_datetime_calendar(str_target, str_datetime, img_loc) {
	var arr_months = ["January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"];
	var week_days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
	var n_weekstart = 1; // day week starts from (normally 0 or 1)

	var dt_datetime = (str_datetime == null || str_datetime =="" ?  new Date() : str2dt(str_datetime));
	var dt_prev_month = new Date(dt_datetime);
        var img_path = img_loc;
	dt_prev_month.setMonth(dt_datetime.getMonth()-1);
	var dt_next_month = new Date(dt_datetime);
	dt_next_month.setMonth(dt_datetime.getMonth()+1);
	var dt_firstday = new Date(dt_datetime);
	dt_firstday.setDate(1);
	dt_firstday.setDate(1-(7+dt_firstday.getDay()-n_weekstart)%7);
	var dt_lastday = new Date(dt_next_month);
	dt_lastday.setDate(0);
	
	// html generation (feel free to tune it for your particular application)
	// print calendar header
	var str_buffer = new String (
		"<html>\n"+
		"<head>\n"+
		"	<title>Calendar</title>\n"+
		"</head>\n"+
		"<body bgcolor=\"White\">\n"+
		"<table class=\"clsOTable\" cellspacing=\"0\" border=\"0\" width=\"100%\">\n"+
		"<tr><td bgcolor=\"#4682B4\">\n"+
		"<table cellspacing=\"1\" cellpadding=\"3\" border=\"0\" width=\"100%\">\n"+
		"<tr>\n	<td bgcolor=\"#4682B4\"><a href=\"javascript:window.opener.show_datetime_calendar('"+
		str_target+"', '"+ dt2dtstr(dt_prev_month)+"'+document.cal.time.value'"+ img_path + "');\">"+
		"<img src=\""+ img_path +"prev.gif\" width=\"16\" height=\"16\" border=\"0\""+
		" alt=\"previous month\"></a></td>\n"+
		"	<td bgcolor=\"#4682B4\" colspan=\"5\">"+
		"<font color=\"white\" face=\"tahoma, verdana\" size=\"2\">"
		+arr_months[dt_datetime.getMonth()]+" "+dt_datetime.getFullYear()+"</font></td>\n"+
		"	<td bgcolor=\"#4682B4\" align=\"right\"><a href=\"javascript:window.opener.show_datetime_calendar('"
		+str_target+"', '"+dt2dtstr(dt_next_month)+"'+document.cal.time.value'"+ img_path + "');\">"+
		"<img src=\""+ img_path +"next.gif\" width=\"16\" height=\"16\" border=\"0\""+
		" alt=\"next month\"></a></td>\n</tr>\n"
	);

	var dt_current_day = new Date(dt_firstday);
	// print weekdays titles
	str_buffer += "<tr>\n";
	for (var n=0; n<7; n++)
		str_buffer += "	<td bgcolor=\"#87CEFA\">"+
		"<font color=\"white\" face=\"tahoma, verdana\" size=\"2\">"+
		week_days[(n_weekstart+n)%7]+"</font></td>\n";
	// print calendar table
	str_buffer += "</tr>\n";
	while (dt_current_day.getMonth() == dt_datetime.getMonth() ||
		dt_current_day.getMonth() == dt_firstday.getMonth()) {
		// print row heder
		str_buffer += "<tr>\n";
		for (var n_current_wday=0; n_current_wday<7; n_current_wday++) {
				if (dt_current_day.getDate() == dt_datetime.getDate() &&
					dt_current_day.getMonth() == dt_datetime.getMonth())
					// print current date
					str_buffer += "	<td bgcolor=\"#FFB6C1\" align=\"right\">";
				else if (dt_current_day.getDay() == 0 || dt_current_day.getDay() == 6)
					// weekend days
					str_buffer += "	<td bgcolor=\"#DBEAF5\" align=\"right\">";
				else
					// print working days of current month
					str_buffer += "	<td bgcolor=\"white\" align=\"right\">";

				if (dt_current_day.getMonth() == dt_datetime.getMonth())
					// print days of current month
					str_buffer += "<a href=\"javascript:window.opener."+str_target+
					".value='"+dt2dtstr(dt_current_day)+"'+document.cal.time.value; window.close();\">"+
					"<font color=\"black\" face=\"tahoma, verdana\" size=\"2\">";
				else 
					// print days of other months
					str_buffer += "<a href=\"javascript:window.opener."+str_target+
					".value='"+dt2dtstr(dt_current_day)+"'+document.cal.time.value; window.close();\">"+
					"<font color=\"gray\" face=\"tahoma, verdana\" size=\"2\">";
				str_buffer += dt_current_day.getDate()+"</font></a></td>\n";
				dt_current_day.setDate(dt_current_day.getDate()+1);
		}
		// print row footer
		str_buffer += "</tr>\n";
	}
	// print calendar footer
	str_buffer +=
		"<form name=\"cal\">\n<tr><td colspan=\"7\" bgcolor=\"#87CEFA\">"+
		"<font color=\"White\" face=\"tahoma, verdana\" size=\"2\">"+
		"Time: <input type=\"text\" name=\"time\" value=\""+dt2tmstr(dt_datetime)+
		"\" size=\"8\" maxlength=\"8\"></font></td></tr>\n</form>\n" +
		"</table>\n" +
		"</tr>\n</td>\n</table>\n" +
		"</body>\n" +
		"</html>\n";

	var vWinCal = window.open("", "Calendar", 
		"width=200,height=250,status=no,resizable=yes,top=200,left=200");
	vWinCal.opener = self;
	var calc_doc = vWinCal.document;
	calc_doc.write (str_buffer);
	calc_doc.close();
}

    
// datetime parsing and formatting routimes. modify them if you wish other datetime format
function str2dt (str_datetime) {
	var re_date = /^(\d+)\-(\d+)\-(\d+)\s+(\d+)\:(\d+)\:(\d+)$/;
	if (!re_date.exec(str_datetime)) {
            return alert("Invalid Datetime format: "+ str_datetime);
        }

        if (RegExp.$1 == '0000'){ 
            return new Date();
        }

	//return (new Date (RegExp.$3, RegExp.$2-1, RegExp.$1, RegExp.$4, RegExp.$5, RegExp.$6));
        return (new Date (RegExp.$1, RegExp.$2-1, RegExp.$3, RegExp.$4, RegExp.$5, RegExp.$6));
}

// date parsing and formatting routimes. modify them if you wish other datetime format
function str2d (str_date) {
	var re_date = /^(\d+)\-(\d+)\-(\d+)$/;

        if (!re_date.exec(str_date)) {
            return alert("Invalid Datetime format: "+ str_date);
        }
        if (RegExp.$1 == '0000'){ 
            return new Date();
        }

	re_date = /^(\w+)\-(\d+)\-(\d+)$/;
        

        return (new Date (RegExp.$1, RegExp.$2-1, RegExp.$3));
}
function dt2dtstr (dt_datetime) {

       var d  = dt_datetime.getDate();
       var day = (d < 10) ? '0' + d : d;
       var m = dt_datetime.getMonth() + 1;
       var month = (m < 10) ? '0' + m : m;
       var yy = dt_datetime.getYear();
       var year = (yy < 1000) ? yy + 1900 : yy;

       return (new String (year+"-"+month+"-"+day));

}
function dt2tmstr (dt_datetime) {
	return (new String (
			" "+dt_datetime.getHours()+":"+dt_datetime.getMinutes()+":"+dt_datetime.getSeconds()));
}


//set all drowdown with the same name the same value as obj
function setSameSelection(obj) {
  var v = obj.options[obj.selectedIndex].value; 
  var eo = document.getElementsByName(obj.name); 
  for (var j=0; j < eo.length; j++){
    var e = eo[j];
    if (e.type == 'select-one'){
      for (var i=0; i < e.options.length; i++) {
	if (e.options[i].value == v) {
	  e.options[i].selected = true;
	}
      }
    }
  }
}

function load_content_from_url(obj_id,attribute,url) {
    var obj = document.getElementById(obj_id);

    var myReq = new Ajax.Request(url, {
        method: 'get',
        asynchronous: true,
        onComplete: function(request) {
            try {
                var content = request.responseText;
                if (attribute) {
                    obj.setAttribute(attribute,content);
                } else {
                    obj.innerHTML = content;
                }
            } catch (err) {
                alert(err);
            }
        }
    }) ;
}

function scmp(a,b) { // standard comparison.
	return (b<a)-(a<b);
}

function smart_cmp(a,b,tbl,col) {
	var re1 = /(\d+)|\D+/g;
	var re2 = /(\d+)|\D+/g;
	re1.lastIndex = 0;re2.lastIndex=0; // Opera 8 bug.
	var res = 0;
	do {
		match1 = re1.exec(a);
		match2 = re2.exec(b);
		if (match1) {
			if (match2) {
				if (match1[1]) {
					if (match2[1]) { // fully numeric.
						res = Number(match1[1]) - Number(match2[1]) || scmp(match1[0],match2[0]);
					} else {
						res = -1;
					}
				} else {
					if (match2[1]) {
					res = 1;
					} else {
						res = scmp(match1[0],match2[0]);
					}
				}
			} else {
				res = 1;
			}
		} else {
			if (match2) {
				res = -1;
			} else {
				res = 0; break;
			}
		}
	} while (res == 0);
	
	if (tbl.reverseSort[col]) {
		res = -res;
	}
	return res;
}

function sub_cgi_app( sub_app_name ) {
	var field = document.getElementById('sub_cgi_application'); 
	field.name = 'sub_cgi_application'; 
	field.value = sub_app_name;
}

function controlVisibility (changeElement, parentElement, parentTest) {

  var pElem = parentElement // element visibility depends on
    if (! parentElement.id) {
      pElem = document.getElementById(parentElement);
    }

  var pVal = pElem.value;   // value of parent field
  var pname = pElem.name;
  var pid = pElem.id;
  
  var cv_array = changeElement.split(',');
  var cv_num=0;

  while (cv_num < cv_array.length) {
    var cv = cv_array[cv_num];
    var cE = document.getElementById(cv);
    
    var name = cv.split('.');  // customized for elements in format: table.name.row (need to remove customization)
    
    var match;
    
    
    if (parentTest.match('^>')) {
        // test for '> integer			
        var digit = parentTest.match(/\d+/);
		var other = parseInt(pVal);
		if (other > digit) { match = 1 }
    }
    else if (parentTest.match('^<')) {
        // test for '< integer'
        var digit = parentTest.match(/\d+/);
		var other = parseInt(pVal);
        if (other < digit) { match = 1 }
    }
    else if ( pVal && parentTest.match(pVal) ) { 
        // simple match 
        match = 1; 
    }

    if ( match ) {
      cE.style.display="";
      if (name[1]) { 
	set_mandatory_validators(document,name[1]);
      }
    }
    else {
      cE.style.display="none";
      if (name[1]) {
	unset_mandatory_validators(document,name[1]);
      }
        }
    cv_num+=1;
  }
}

function getCheckedValue(radioObj) {
    var List = new Array(0);
    for (i=0;i<radioObj.length;i++) {
        if (radioObj[i].type == 'radio') {
	    if (radioObj[i].checked) { return radioObj[i].value }
	}
        else if (radioObj[i].type == 'checkbox') { 
            if (radioObj[i].checked) { List.push(radioObj[i].value) } 
        }
	else if (radioObj[i].type == 'submit') {
            // do nothing since it is a submit button
	}
        else if (radioObj[i].type == 'hidden') {
            return radioObj[i].value;
        }
        else { alert('Error trying to get checked value of ' + radioObj[i].type) }
    }                    
    
    if (List.length == 1) { return List[0] }     
    else if (List.length > 1) {
        var joined = List.join(',');
        return joined; 
    }
    else {
        // if (radioObj[0].type == 'radio') { alert('no radio option chosen') } 
        return;
    }
}


function HideVisibilityRadio (changeElement, parentElement, parentTest) {

  var pElem = parentElement // element visibility depends on
  if (! parentElement.id) {
	pElem = document.getElementsByName(parentElement);
  }
  var selection =getCheckedValue(pElem);
  var pVal =selection;   // value of parent field
  var pname = pElem.name;
  var pid = pElem.id;
  
  var cv_array = changeElement.split(',');
  var pt_array = parentTest.split(',');
  var cv_num=0;
	
  while (cv_num < cv_array.length) {
    var cv = cv_array[cv_num];
    var cE = document.getElementById(cv);
    var name = cv.split('.');  // customized for elements in format: table.name.row (need to remove customization)
    var pt_num =0;
	while(pt_num <= pt_array.length){
	  if ( pVal && pt_array[pt_num].match(pVal) ) { 
        cE.style.display="none";
		return;
        if (name[1]) {
	       unset_mandatory_validators(document,name[1]);
        }	   
	  }
	  else {
	    cE.style.display="";
	    if (name[1]) { 
		  set_mandatory_validators(document,name[1]);
        }
      }
      pt_num+=1;
	}
	cv_num+=1;
    
  }
}

function fillList (list, URL) {

   var $j = jQuery; //.noConflict();
   $j.get(URL, function(data){
	fillOptions(list, data, 0);
   });
}

function dependentFilter(change,URL,update, autocomplete, click_searchlist) {  

  var Changed = document.getElementById(change);

    var re = new RegExp('\\.', 'g');
    var indicator_id = "#indicator_" + change.replace(re,"_");

    var $j = jQuery; //.noConflict();

    $j(indicator_id).bind("ajaxStart", function(){$j(this).show();})
    .bind("ajaxStop", function(){$j(this).hide();});

    var substr;
    if( click_searchlist ) {
        substr = Changed.options[Changed.selectedIndex].value;
    }
    else {
        substr = trim(Changed.value);
    }

    if (substr.match("\n")) {
        var search_list = substr.split("\n");
        if (search_list.length > 1) { 
            var string = '';
            for (var i=0; i<search_list.length; i++) {
                if (search_list[i].length > 0) { 
                    if (string.length > 0) { string = string + '|'}
                    string = string + search_list[i];
                }
            } 
            myregexp = new RegExp(string, "i");
        }
        substr = string;
    }
    
   $j.get(URL+"&Element_Value="+substr, function(data){ fillOptions(update, data, autocomplete) });
    $j(indicator_id).bind("ajaxStart", function(){$j(this).hide();});
}

function fillOptions (list, data, autocomplete) {

  var choiceName = list;
  if (! list.match('Choice')) { choiceName = list + '.Choice' }
  //alert('fill ' + choiceName);
  var List = document.getElementById(choiceName);
  if ( !List ) {
    // if no choice element, use baseline element
    List = document.getElementById(list);
  }

  var entries = new Array();
    
  entries = data.split(",");

  List.options.length = 0;
  
  for(var i=0; i<entries.length; i++) {
    List.options[i+1] = new Option(entries[i],entries[i]);
    // This seems to be incorrect so we are avoiding using it
    //if (autocomplete){
      //do nothing
    //}
    //else if (i>0) { List[i+1].selected = 1 }    
  }

  /* if we do want to auto-select value when only one option available in dropdown list, we could use line below: */
  // if (List.length == 2 && entries.length == 1) { List[entries.length].selected = 1; }

  if (autocomplete) {  
	if (!data) {
	   List.options[0] = new Option('--Enter string above to search list--','');
           alert("No matching results found");
	}

	var baseline_elenment = document.getElementById(list);
	baseline_elenment.value = '';
   }
   


  //  if (Update.options.length) {
  //  alert('add no valid options');
  //  Update.options[0] = new Option('-- no valid options', '-- no valid options --');
  //  }
  //    jQuery("select").trigger('chosen:updated');
}

// optional packages for alternate multi-select viewing tools: Chosen or Select2 (alternatives to using Bootstrap Multiselect)
function initializeChosen() {
   jQuery("select").not("#Available_Options").not("#Picked_Options").chosen({search_contains: true, width: "220px", disable_search_threshold: 10, allow_single_deselect: true });
}

function initializeSelect2() {
    jQuery("select").not("#Available_Options").not("#Picked_Options").select2({width:'220px', placeholder:'Select Some Options', allowClear:true, closeOnSelect:false});
}

function zoom_in_thumb (e) {
    var element = document.getElementById(e);

    // element.style.height=30px;
}

function zoom_out_thumb (e) {
    var element = document.getElementById(e);

    // element.style.height=15px;
}

