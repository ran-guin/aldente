// DB Form Navigator

var navCurrZIndex = 0;

function navDraw() {
    roadmapRefresh();
    formSetCurrent(roadMapObj.current_form,roadMapObj.current_form_instance);
    formDisplayContent();
}

function roadmapRefresh() {
    var original_form = roadMapObj['original_form'];
    var roadmap = document.getElementById('navRoadMap');
    roadmap.innerHTML='';
    
    var header = document.createElement('SPAN');

    var root = document.createElement('OL');
    root.id= 'navRoadMapRoot';
    roadmap.appendChild(root);

    if(roadMapObj['has_branches']) {
        var display_opts = getLinkNode('[ Show branch points ]',"javascript:roadmapToggleBranches();");
        display_opts.id = 'navDisplayBranchesLink';
        display_opts.className = 'roadmapToggleBranches';
        roadmap.appendChild(display_opts);
    }

    if(original_form) {
        var main = treeGetLeaf(original_form);
        if(main) {
            root.appendChild(main);
            roadmapAppendElement(original_form);
        }
    }
}

function roadmapToggleBranches() {
    var dispOptsNode = document.getElementById('navDisplayBranchesLink');

    var mode = formConfigs['displayBranches'];
    if(mode=='none') {
        mode = '';
        dispOptsNode.innerHTML = '[ Hide branch points ]';
    } else {
        mode = 'none';
        dispOptsNode.innerHTML = '[ Show branch points ]';
    }
    formConfigs['displayBranches'] = mode;

    var branch_list = document.getElementsByTagName('SPAN');
    for(var i=0; i<branch_list.length;i++) {
        if(branch_list[i].className=='navBranch') {
            branch_list[i].style.display=mode;
        }
    }
}

function roadmapUpdateBranch(form,branch_cond,prompt,value,instance) {
    // Update the road map object
    // First check to see if this branch 'prompt' exists in the tree
    //   (could be supplied a 'prompt' from the form & DB_Form is not defined to branch on that value)
    var exists;
    var branch_order;
   
    for(branch_order=0; branch_order<roadMapObj[form]['branch_on'].length; branch_order++) {
        var condition_choice = roadMapObj[form]['branch_on'][branch_order]['branch_name'];
        if(condition_choice == branch_cond) {
            for(var choice in roadMapObj[form]['branch_on'][branch_order]['choices']) {
                if( testMatch(choice, prompt, roadMapObj[form]['branch_on'][branch_order]['choices']) ) {
                    if(!value) {
                        //retrieve the value from choices (since we only know about the prompt) (coming from the form itself)
                        value = roadMapObj[form]['branch_on'][branch_order]['choices'][choice];
                    }
                    exists = 1;
                    break;
                }
            }
            break;
        }
    }
    // if no prompt is provied -> '' value was selected from drop down -> go ahead with setting the value
    // if exists -> go ahead with setting the value as well
    if(!prompt || exists) {
        roadMapObj[form]['branch_on'][branch_order]['active'+instance]=prompt;
        // Also update the value in the form if its currently active
        if(roadMapObj['current_form'] == form && formStruct[form]) {
            if(document.getElementById('formObject')[branch_cond]) {
                document.getElementById('formObject')[branch_cond].value=prompt;
            } else {
                alert('Branch element is not defined in the form!'); //report an issue?
            }
        }
    } else {
//        alert('form: ' + form + '\n branch_order: ' + branch_order);
        roadMapObj[form]['branch_on'][branch_order]['active'+instance]='!BDNE'; //Branch does not exist
    }
    
    roadmapRefresh();
    formSetCurrent(roadMapObj.current_form,roadMapObj.current_form_instance);
    formUpdateControls();
}

function testMatch(test, value, hash) {
// test match between test value (which may contain wildcards or > or < options) .. optional hash field will be updated for non equivalent matches 


    if (test == value) { return value }
   
    var pattern = '/^' + test + '/';
    if ( value.match(pattern) ) { 
        updateHash(hash, test, value);
        return value; 
    }
    
    
    if ( test.match(/\*/) ) {
        // alert('wildcard test: ' + value + ' matches ' + pattern + '?');
        // test wildcard ##
        var wctest = test;
        wctest.replace("*",".*");
        
        if ( value.match(wctest) ) { 
            updateHash(hash, test, value);
            return value;
        }
    }
    
    if ( test.match(/^>/) ) {
        var length = test.length;
        var number = test.substring(1,length)
        if (value > number) {
            updateHash(hash, test, value);
            return value;
        }
    }
    
    if ( test.match(/^\</) ) {
        var length = test.length;
        var number = test.substring(1,length)
        if (value < number) {
            updateHash(hash, test, value);
            return value;
        }
    }
    
    return 0;
}


function updateHash(hash, v1, v2) {    
// used to update hash with parallel keys if necessary (eg update_hash({A => 1, B =>2 }, A, C) ... {A => 1, B => 2, C => 2})

    if (hash && hash[v1]) {
        // in this case, we need to update the hash keys to enable v2 to mimic v1 
        var current = hash[v1];
        hash[v2] = hash[v1];
    }
    return;
}

function roadmapAppendElement(childName) {
    var root = document.getElementById('navRoadMapRoot');
    if(childName=='') {
        alert('No childNames');
        return;
    }
    var branches = roadMapObj[childName]['branch_on'];
    var childs   = roadMapObj[childName]['child_form'];
   
    if(branches) {
        for(var branch_order=0; branch_order<branches.length; branch_order++) {
    
            var branch_condition = branches[branch_order]['branch_name'];
            // Store the select element in a branch called navBranch
            var branch_root = document.createElement('span');
            branch_root.style.display = formConfigs['displayBranches'];
            branch_root.className = 'navBranch';
            branch_root.id=childName + '_branch';
            branch_root.appendChild(getTextNode(branch_condition + '? '));
            var dropdown = document.createElement('select');
            dropdown.id=childName + '.' + branch_condition;

	    // array to check if branch is added already
	    var check_array = new Array();
	    var check_child_exist = 0;

	    // a new loop to loop through all active branch for different instances
	    for(var inst_count = 0; inst_count<roadMapObj[childName]['instances'].length; inst_count++) {
            var active_branch = roadMapObj[childName]['branch_on'][branch_order]['active'+inst_count];
	    if (typeof(active_branch)!="undefined") {check_child_exist = 1;}
            // First empty value
            var choiceElement = document.createElement('option');
            choiceElement.setAttribute('value','');

            // Set this branch as active and refresh the tree
            attachEventToNode(dropdown,'onchange',"roadmapUpdateBranch(" + childName + ",'" + branch_condition + "',this.options[this.selectedIndex].text,this.value," + inst_count + ")");

            dropdown.appendChild(choiceElement);

            // Populate the SELECT element
            for(var j in branches[branch_order]['choices']) {
                var choice_name = j;
                var choice_result = branches[branch_order]['choices'][choice_name];
                choiceElement = document.createElement('option');
                choiceElement.setAttribute('value',choice_result);
                choiceElement.innerHTML=choice_name;
                if(choice_name == active_branch) {
                    choiceElement.setAttribute('selected',1);
                }
                dropdown.appendChild(choiceElement);
            }
            branch_root.appendChild(dropdown);
            // Append the branch element to the root
            root.appendChild(branch_root);

            // If there are any active branches, list them
            if(active_branch) {
                if(active_branch != '!BDNE') {
                    var branch = roadMapObj[childName]['branch_on'][branch_order]['choices'][active_branch];
                    if(branch) {
                        for(var i=0; i<branch.length; i++) {
                            var sibs = treeGetLeaf(branch[i]);
			    var check_exist = 0;
			    for (var check=0; check<check_array.length; check++) {
				if (roadMapObj[branch[i]]['Form_Title'] == check_array[check]) {check_exist=1;}
			    }
                            if(sibs && !check_exist) {
				check_array[check_array.length] = roadMapObj[branch[i]]['Form_Title'];
                                root.appendChild(sibs);
                                roadmapAppendElement(branch[i]);
                            } else if (!check_exist) {
                                alert('no sibs returned for ' + branch[i]);
                            }
                        }
                    }
                }
            }
	    }


	    if (!check_child_exist) {
            var active_branch = roadMapObj[childName]['branch_on'][branch_order]['active'];
            // First empty value
            var choiceElement = document.createElement('option');
            choiceElement.setAttribute('value','');

            // Set this branch as active and refresh the tree
            attachEventToNode(dropdown,'onchange',"roadmapUpdateBranch(" + childName + ",'" + branch_condition + "',this.options[this.selectedIndex].text,this.value," + inst_count + ")");

            dropdown.appendChild(choiceElement);

            // Populate the SELECT element
            for(var j in branches[branch_order]['choices']) {
                var choice_name = j;
                
                var choice_result = branches[branch_order]['choices'][choice_name];
                choiceElement = document.createElement('option');
                choiceElement.setAttribute('value',choice_result);
                choiceElement.innerHTML=choice_name;
                if(choice_name == active_branch) {
                    choiceElement.setAttribute('selected',1);
                }
                dropdown.appendChild(choiceElement);
            }
            branch_root.appendChild(dropdown);
            // Append the branch element to the root
            root.appendChild(branch_root);

            // If there are any active branches, list them
            if(active_branch) {
                if(active_branch != '!BDNE') {
                    var branch = roadMapObj[childName]['branch_on'][branch_order]['choices'][active_branch];
                    if(branch) {
                        for(var i=0; i<branch.length; i++) {
                            var sibs = treeGetLeaf(branch[i]);
                            if(sibs) {
                                root.appendChild(sibs);
                                roadmapAppendElement(branch[i]);
                            } else {
                                alert('no sibs returned for ' + branch[i]);
                            }
                        }
                    }
                }
            }
	    }

        }
    }
    
    if(childs) {
        // If it has any childs, list them all
        for(var i=0; i<childs.length; i++) {
            var sibs = treeGetLeaf(childs[i]);
            if(sibs) {
                root.appendChild(sibs);
                roadmapAppendElement(childs[i]);
            }
        }
    }
}

function treeGetLeaf(id) {
    var struct = roadMapObj[id];
    if(!struct) {
        alert(id);
    }

    // Create an span element for the given form, and store the link for all instances of it here
    var myNode = document.createElement('SPAN');
    myNode.id=id;
    myNode.className = 'navLeaf';
    myNode.setAttribute('maxrecords',struct['Max_Records']);
    myNode.setAttribute('minrecords',struct['Min_Records']);
    var instances;
    if(!roadMapObj[id]['instances']) {
        //initialize
        roadMapObj[id]['instances'] = [];
        if(formData[id]) {
            instances=0;
            for (var i in formData[id]) {
                instances++;
            }
        } else {
            instances=1;
        }
    } else {
        instances = roadMapObj[id]['instances'].length;
    }

    var formInfo = []; formInfo = roadMapObj[id]['FormFullName'].split(':');
    for(var inst=0; inst<instances; inst++) {

        if(!roadMapObj[id]['instances'][inst]) {
            roadMapObj[id]['instances'][inst] = {};
        }

        // Create a link to as many objects as we have
        var entry = document.createElement('LI');
        entry.id=id + '!' + inst;
        var status = roadMapObj[id]['instances'][inst]['status'];
        var statusimage;
        switch(status) {
            case 'done':        statusimage = 'check_mark_green.gif';
                break;
            case 'partial':     statusimage = 'edit_mark_pen.gif';
                break;
            case 'skipped':     statusimage = 'cross_mark_red.gif';
                break;
            default: statusimage = '';
        }
        if(statusimage) {
            entry.style.backgroundImage = "url('" + URL_version + '/images/icons/' + statusimage + "')";
        }

        // So that can be easily accesible
        entry.setAttribute('form_id',id);
        entry.setAttribute('instance_number',inst);

        if(!formStruct[id]) {
            // Then load it from the server
            formStruct[id] = 'loading';

            var params = '';

            for(var x in formConfigs['default_parameters']) {
                params += x + '=' + encodeURIComponent(formConfigs['default_parameters'][x]) + '&';
            }
            
            params += "Form="+formInfo[0] + 
                      "&Database="+formConfigs['database'] +
                      "&Database_host="+formConfigs['database_host'];

            if(roadMapObj[id]['Grey']) {
                params += "&Grey=" + roadMapObj[id]['Grey'];
            }
            
            if(roadMapObj[id]['Omit']) {
                params += "&Omit=" + roadMapObj[id]['Omit'];
            }

            if(roadMapObj[id]['List']) {
                params += "&List=" + encodeURIComponent(ObjectToJSONString(roadMapObj[id]['List']));
            }

            for(var x in roadMapObj[id]['Preset']) {
                params += "&" + x + "=" + encodeURIComponent(roadMapObj[id]['Preset'][x]);
            }
                         
            if(roadMapObj[id]['Ancestors']) {
                params += "&Ancestors=" + roadMapObj[id]['Ancestors'];
            }
            if(formInfo[1]) {
                params += "&Class=" + formInfo[1];
            }

            //prompt('',params);
            var myReq = new Ajax.Request(formConfigs['formgen'], {
                postBody: params,
                asynchronous: true,
                onComplete: function(request) {
                    try {
                        formStruct[id] = request.responseText;
                        if(roadMapObj['current_form']==id) {
                            formMoveTo({'form':id,'inst':0});
                        }
                    } catch (err) {
                        alert(err);
                    }
                }
            }) ;
        }
        
        var formName = roadMapObj[id]['Form_Title'];
        var text = inst ? formName + ' #' + inst : formName;
        var textNode = getTextNode(text);

        entry.onclick = function () {
            if(!(roadMapObj.current_form == id && roadMapObj.current_form_instance == this.getAttribute('instance_number'))) {
                var save_interm = confirm("Save intermediate changes?");
                if(save_interm == true) {
                    if(formSaveCurrent(1)) { // don't validate, cuz its partial....
                        formUpdateStatus(roadMapObj.current_form,roadMapObj.current_form_instance,'partial');
                    }
                } else {
                    formUpdateStatus(roadMapObj.current_form,roadMapObj.current_form_instance,'skipped');
                }
                formMoveTo({'form':id,'inst':this.getAttribute('instance_number')},1);
            }
        }

        entry.appendChild(textNode);
        myNode.appendChild(entry);
    }
    return myNode;
}

function treeAddLeaf(id) {
    var roadmap = document.getElementById('navRoadMap');
    var entries = roadmap.getElementsByTagName('SPAN');
    
    var myNode;
    for(var i=0; i<entries.length; i++) {
        if(entries[i].id == id) {
            myNode = entries[i];
        }
    }

    if(!myNode) {
        alert("Can't find node for " + id);
        return 0;
    } else {
        // Find the number of current entries of this type
        var curr_count= roadMapObj[id]['instances'].length;

        if(curr_count < myNode.getAttribute('maxrecords') ) {
            roadMapObj[id]['instances'][curr_count] = {};
            roadmapRefresh();
        } else {
            alert('Max number of records has been reached for ' + id +'!');
        }
    }
}

function getTextNode(txt) {
    return document.createTextNode(txt);
}

function getLinkNode(txt,link) {
    var linkNode = document.createElement('a');
    linkNode.innerHTML=txt;
    linkNode.setAttribute('href',link);
    return linkNode;
}

function getInputNode(options,events) {
    var inputNode = document.createElement('input');

    if (options['accesskey']) {
        var accesskey_tip = '(Shortcut: ALT+' + options['accesskey'] + ')';

        if(options['tooltip']) {
            options['tooltip'] += " " + accesskey_tip;
        } else {
            options['tooltip'] = accesskey_tip;
        }
    }
    
    for(var att in options) {
        inputNode.setAttribute(att,options[att])
        
        if (att == 'tooltip') {
            inputNode.setAttribute('onmouseover',"writetxt('" + options['tooltip'] + "')");
            inputNode.setAttribute('onmouseout',"writetxt(0)");
        }
    }

    for(var eve in events) {
        attachEventToNode(inputNode,eve,events[eve]);
    }
    return inputNode;
}

function attachEventToNode(node,e,e_code) {
        //if ie
        if(navigator.appVersion.indexOf('MSIE')>0) {
            //hack for IE
            e_code = e_code.replace(/this/g,'node');
            node.attachEvent(e,function () {eval(e_code)} );
        } else {
            node.setAttribute(e,e_code);
        }
}

function getLayerNode() {
    var node = document.createElement('div');
    node.className = 'navLayerForm';
    //if ie
    if(navigator.appVersion.indexOf('MSIE')>0) {
        node.style.position = 'absolute';
    } else {
        node.style.position = 'fixed';
    }
    node.style.zindex = ++navCurrZIndex;
    return node;
}

function formAddNew(formName,id,alternate_URL,id_randappend) {
    if (id_randappend) {
	id += id_randappend;
    }
    if (document.getElementById('formPlaceHolder')) {
        var layer = getLayerNode();
        layer.id = formName + '.Layer';
        var myForm = document.createElement('form');
        layer.appendChild(myForm);
        var params = '';
        
        for(var x in formConfigs['default_parameters']) {
            params += x + '=' + formConfigs['default_parameters'][x] + '&';
        }

        params += "Form="+formName + "&Database="+formConfigs['database'] + "&Database_host="+formConfigs['database_host'];

        var myReq = new Ajax.Request(formConfigs['formgen'], {
            postBody: params,
            asynchronous: true,
            onComplete: function(request) {
                try {
                    myForm.innerHTML = request.responseText;
                    myForm.appendChild(formAddNewControls(formName,id));
                } catch (err) {
                    alert(err);
                }
            }
        }) ;
        document.getElementById('formPlaceHolder').appendChild(layer);
    }
    else {
        window.open(alternate_URL,'addnewform','height=800,width=1000,scrollbars=yes,resizable=yes,toolbar=no,location=no,directories=no');
    }
}

function formAddNewControls(formName,target_id) {
    var controls = document.createElement('controls');
    controls.id = 'FormControls' + target_id;

    var script_hide = "var form_layer = document.getElementById('" + formName + ".Layer'); form_layer.parentNode.removeChild(form_layer);";
    controls.appendChild(getInputNode({'type':'button','value':'Cancel','class':'Std'},{'onclick':script_hide}));

    var script_save = "if(validateForm(this.form)) {this.disabled=1;formAddNewSubmit('"+formName+"','"+target_id+"')}";
    controls.appendChild(getInputNode({'type':'button','value':'Save','class':'Action','id': formName + ".SaveButton"},{'onclick':script_save}));

    return controls;
}

function formAddNewSubmit(formName,target_id) {

    var Data = {};
    Data[formName] = {};
    Data[formName][0] = saveForm(formName + '.Layer');
    Data[formName][0]['FormFullName'] = formName;

    var params   = '';
    for(var x in formConfigs['default_parameters']) {
        params += x + '=' + formConfigs['default_parameters'][x] + '&';
    }
    params     += 'Form=' + formName + 
                  '&Database=' + formConfigs['database'] + 
                  '&Database_host=' + formConfigs['database_host'] + 
                  '&Data=' + ObjectToJSONString(Data);

    var myReq   = new Ajax.Request(formConfigs['submitsingle'], {
        postBody: params,
        asynchronous: true,
        onComplete: function(request) {
            try {
                var n = request.responseText;
                if(n.match(/^Error:/)) {
                    alert(n);

                    //re-enable the button
                    document.getElementById(formName + '.SaveButton').disabled=0;
                } else if(n.match(/DBD::mysql::db do/)) {
                    // hardcoded for mysql
                    var begin = n.indexOf('failed:');
                    var end   = n.indexOf(' at ');
                    alert(n.substring(begin,end));

                    //re-enable the button
                    document.getElementById(formName + '.SaveButton').disabled=0;
                } else {
	          //alert('hide the popup');
                    var form_layer = document.getElementById(formName + '.Layer');
                    form_layer.parentNode.removeChild(form_layer);
                   var target = document.getElementById(target_id + '.Choice');
                   if (target) {
  			target_id = target_id + '.Choice';
                        target.options[target.length] = new Option(n,n);
                        target.options.selectedIndex = target.length-1;
                        target.style.backgroundColor='#99e699';
                        // target.options[target.options.selectedIndex].style.color='#ff0000';
                    } else {
                      	target = document.getElementById(target_id);
			if (target.type == "select-one") {
				// if simple pull-down menu 
                        	target.options[target.length] = new Option(n,n);
                        	target.options.selectedIndex = target.length-1;
			} else {
				// textfield 
				target.value = n;
			}
                    }
/*
                    // Deprecated feature ? 
                    alert('highlight the field...');
                     target.effect = new Effect.Highlight(target_id, {
                      startcolor: '66FF00',
                      endcolor: 'FFFF00',
                      restorecolor: 'AAFFAA'
                     });
*/
                    if (formStruct) {
                        // clear out the structure of the form so that it gets reloaded (if we are in Navigator mode ofcourse)
                        // formStruct[roadMapObj.current_form] = '';
                    }
                }
            } catch (err) {
                alert(err + " (Target id: " + target_id + ")");
            }
        }
    }) ;
}

function formElementTypes () {
    var FormElementTypes = new Array('input','textarea','select');
    return FormElementTypes;
}

function formDisplayContent(force_display) {
    var tdElement = document.createElement('td');
    var formElement = document.createElement('form');
    formElement.id='formObject';
    formElement.className='form-search';  /* Add Class specification to make consistent with Standard Bootstrap form-search elements */
    
    var curr_form = roadMapObj.current_form;
    var curr_inst = roadMapObj.current_form_instance;
    if(!curr_inst) { curr_inst = 0 }
    if(formStruct[curr_form] != 'loading') {
        formElement.innerHTML = formStruct[curr_form];
        if(roadMapObj[curr_form]['branch_on']) {
            for(var branch_order=0; branch_order<roadMapObj[curr_form]['branch_on'].length; branch_order++) {
                var branch_cond = roadMapObj[curr_form]['branch_on'][branch_order]['branch_name'];
                // Currently branches are done using drop downs (ie select elements)
                //   To find the branch element, the code used to loop over 'formElement.elements' array, but
                //   due to problems with firefox 1.0 this has been changed to loop over formElement.getElementsByTagName('SELECT')
                var inputElements = formElement.getElementsByTagName('SELECT');
                for (var element=0; element < inputElements.length; element++) {
                    var thisElement = inputElements[element];
                    if(thisElement['name'] == branch_cond) {
                        attachEventToNode(thisElement,'onchange',"roadmapUpdateBranch(" + curr_form + ",'" + branch_cond + "',this.options[this.selectedIndex].text,this.value," + curr_inst + ")");
                        thisElement.value = roadMapObj[curr_form]['branch_on'][branch_order]['active'+curr_inst];
                    }
                }
            }
        }

        try {
            if(formData[curr_form] && formData[curr_form][curr_inst]) {
                // Set the values;
                var myElementValues = formData[curr_form][curr_inst];
                for (var element_index=0;element_index<formElementTypes.length;element_index++) {
                    var list = formElement.getElementsByTagName(formElementTypes[element_index]);
                    for (var i=0;i<list.length;i++) {
                        if(myElementValues[list[i].name] || myElementValues[list[i].name] == '0') {
			  // go here if value is true OR value is equal to '0' (added or option to preset 0 fields)
                            switch(formElementTypes[element_index]) {
                                case 'input'        : list[i].setAttribute('value',myElementValues[list[i].name]);
                                break;
                                case 'textarea'     : list[i].innerHTML = myElementValues[list[i].name];
                                break;
                                case 'select'       : {
                                    // Go here if the scrolling list is filled by AJAX
                                    if( list[i].options.length == 1 && list[i].options[0].value == '' ) {

                                        if( myElementValues[list[i].name].length == 0 ) {
                                            list[i].options[0] = new Option('--Enter string above to search list--','');
                                        }
                                        else {
                                            list[i].options[0] = new Option('','');
                                            for(var index=0; index<myElementValues[list[i].name].length; index++) {
                                                list[i].options[index+1] = new Option(myElementValues[list[i].name][index], myElementValues[list[i].name][index]);
                                                list[i].options[index+1].selected = 1;
                                            }
                                        }
                                    }
                                        
                                    else {
                                        for(var index=0; index<myElementValues[list[i].name].length; index++) {
                                            for(var j=0; j<list[i].options.length; j++) {
                                                if(list[i].options[j].value == myElementValues[list[i].name][index]) {
                                                    // Found
                                                    list[i].options[j].selected=1;
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                                break;
                            }
                        }
                    }
                }
            }
        } catch (err) {
            alert(err)
        }
            

        // If there are any input fields, prompt them with form controls, otherwise move to next form
        var has_input_fields = 0; // Input fields meaning any form input element other than "hidden"
        
        for (var element_index=0;element_index<formElementTypes.length;element_index++) {
            var list = formElement.getElementsByTagName(formElementTypes[element_index]);
            if(list.length > 0) {
                if(formElementTypes[element_index] == 'textarea' || formElementTypes[element_index] == 'select') {
                    has_input_fields = 1;
                    continue;
                } else if(formElementTypes[element_index] == 'input') {
                    for(var i=0; i<list.length; i++) {
                        if(list[i].type != 'hidden') {
                            has_input_fields = 1;
                            continue;
                        }
                    }
                }
            }
        }

        tdElement.appendChild(formElement);
        document.getElementById('formPlaceHolder').innerHTML = '';
        document.getElementById('formPlaceHolder').appendChild(formElement);

        if(force_display || has_input_fields) {
                formElement.appendChild(formGetControls(curr_form,roadMapObj[curr_form]['instances'].length));
        } else {
                formSaveCurrent();
                var nextForm = formGetNext();
                if(nextForm) {
                    formMoveTo(nextForm);
                } else {
                    formElement.appendChild(formGetControls(curr_form,roadMapObj[curr_form]['instances'].length));
                }
        }
    } else {
        document.getElementById('formPlaceHolder').innerHTML = 'Please wait while the form is loading...';
    }
}

function formSaveCurrent(no_validation) {
    var curr_form_inst = roadMapObj.current_form_instance;
    var curr_form = roadMapObj.current_form;

    // Validate the current form...
    if (!no_validation && !validateForm(document.getElementById('formObject'))) {
        return 0;
    }
    
    if(!formData[curr_form]) {
        formData[curr_form] = [];
    }
    
    formData[curr_form][curr_form_inst] = saveForm('formObject');

    if(no_validation) {
        formUpdateStatus(curr_form,curr_form_inst,'partial');
    } else {
        formUpdateStatus(curr_form,curr_form_inst,'done');
    }
    return 1;
}


function formUpdateControls() {
    var formID          = roadMapObj.current_form;
    var instance        = roadMapObj[formID]['instances'].length;//roadMapObj.current_form_instance;
    // first check to see if form is loaded...
    if(formStruct[formID]) {
        var old_controls    = document.getElementById('CurrFormControls');
        var new_controls    = formGetControls(formID,instance);
        old_controls.parentNode.replaceChild(new_controls,old_controls);
    }
}

function formGetControls(formID,instance) {
    var controls = document.createElement('controls');
    controls.id = 'CurrFormControls';

    var prev_form = formGetPrevious();
    if(prev_form) {
        var script = "formSaveCurrent(1);formMoveTo(formGetPrevious(),1);";
        controls.appendChild(getInputNode({'type':'button','value':'<< Back','class':'Std'},{'onclick':script})); 
    }

    if(instance < roadMapObj[formID]['Max_Records']) {
        var script = "if(formSaveCurrent()){ treeAddLeaf('" + formID + "'); formMoveTo(formGetNext());}";
        controls.appendChild(getInputNode({'type':'button','value':'Add More ' + roadMapObj[formID]['Form_Title'] + ' (+)','class':'Std'},{'onclick':script})); 
    }

    if(instance > roadMapObj[formID]['Min_Records']) {
        var script = "formDeleteCurrent();";
        var desc;
        if (instance == 1) {
            desc = 'Skip';
        } else  {
            desc = 'Remove (-)';
        }
        controls.appendChild(getInputNode({'type':'button','value':desc,'class':'Std'},{'onclick':script})); 
    }
    
    var next_form = formGetNext();
    if(next_form) { // if not last form
        var script = 'if(formSaveCurrent()){ formMoveTo(formGetNext());}';
        controls.appendChild(getInputNode({'type':'button','value':'Next >>','class':'Std'},{'onclick':script})); 
    }

    if(!next_form || roadMapObj[formID]['Finish']) {
        if(formConfigs['SubmissionID']) {
            //part of a submission
            var script = "formSaveCurrent();formSubmit('UpdateSubmission');";
            controls.appendChild(getInputNode({'type':'button','value':'Update Draft','class':'Search'},{'onclick':script})); 
        } else if(formConfigs['allowSaveDraft']) {
            var script = "formSaveCurrent(1);formSubmit('Draft');";
            controls.appendChild(getInputNode({'type':'button','value':'Save Draft','class':'Search'},{'onclick':script})); 
        }

        if(formConfigs['target'] == 'Database') {
            //prompt them with finish button
            if(formConfigs['SubmissionID']) {
                var script = "if(formSaveCurrent()){formSubmit('ApproveSubmission');}"
                controls.appendChild(getInputNode({'type':'button','value':'Approve Submission','class':'Action'},{'onclick':script})); 
            } else {
                var script = "if(formSaveCurrent()){formSubmit('Database');}"
                controls.appendChild(getInputNode({'type':'button','value':"Finish",'class':'Action'},{'onclick':script})); 
            }
        } else if (formConfigs['target'] == 'Submission') {
            if (roadMapObj.current_form == 'Submission' || !roadMapObj['Submission']) {
                // either in 
                //      submisison edit mode. target is submission, but there is no submission form as it has already been entered into the database
                // or
                //      submitting the submission. we are at the submisison form
                var script = "if(formSaveCurrent()){formSubmit('Submission')};";
				if (!formConfigs['DisableCompletion']){
					controls.appendChild(getInputNode({'type':'button','value':'Complete Submission','class':'Action'},{'onclick':script})); 
				}
			} else {
                // in submission mode, completed the last data table, and moving to Submisison table
                var script = "if(formSaveCurrent()){formMoveTo(eval({'form':'Submission','inst':'0'}))};";
                if (!formConfigs['DisableCompletion']){
				   controls.appendChild(getInputNode({'type':'button','value':'Complete Submission','class':'Std'},{'onclick':script})); 
				}
			}
        }
    }
    return controls;
}

function formDeleteCurrent() {
    var conf = confirm('Are you sure you want to delete this entry?');

    if(conf) {
        var form = roadMapObj.current_form;
        var inst = roadMapObj.current_form_instance;
        var nextform = formGetNext();
        
        if(form == nextform['form']) {
            // if next form is another instance of the current form, reduce the instance of next form
            nextform['inst']--;
        } else if(!nextform) {
            // if last form, goto previous form
            nextform = formGetPrevious();
        }

        //remove the entry in roadmap
        roadMapObj[form]['instances'].splice(inst,1);
        //remove the entry in saved forms (formData)
        if(roadMapObj[form]['instances'][inst]) {
            formData[form].splice(inst,1);
        }
        roadmapRefresh();
        if(nextform['form']) {
            formMoveTo(nextform,1);
        }
    }
}

function formMoveTo(forminfo,force) {
    formSetCurrent(forminfo['form'],forminfo['inst']);
    formDisplayContent(force);    
}

function formGetNext() {
    return _getForm('next');
}

function formGetPrevious() {
    return _getForm('prev');
}

function formSetCurrent(formName,instance) {
    if(formName) {
        roadMapObj.current_form = formName;
        roadMapObj.current_form_instance = instance;
    }

    var currobj = document.getElementById(roadMapObj.current_form + '!' + roadMapObj.current_form_instance);
    currobj.style.fontWeight = 'bold';
    currobj.style.fontSize  = '16px';
}

function formUpdateStatus(form,inst,req_status) {
    if(roadMapObj[form]['instances'][inst]) {
        roadMapObj[form]['instances'][inst]['status'] = req_status;
    } else {
        alert('Form: ' + form + '!' + inst + ' does not exist');
    }
    roadmapRefresh();
}

function formSubmit(type) {
    if(!type) {
        //<CONSTRUCTION> Submit an error notification by ajax
        alert('Error: No type specified. Please report an issue')
        return 0;
    }

    var formObj = document.getElementById('formObject');
    var Data = {};

    var formList = document.getElementById('navRoadMapRoot').getElementsByTagName('LI');

    if(type == 'Draft' || type == 'UpdateSubmission') {
        //Keep everything the same, just save it, no error checking requierd
        if(formList.length > 1) {
            var c = confirm('Save all forms?')
            if(!c) {
                return 0;
            }
        }
        for(var i=0;i<formList.length; i++) {
            var node = formList[i];
            this_form = node.getAttribute('form_id');
            this_inst = node.getAttribute('instance_number');
            this_form_name = roadMapObj[this_form]['FormFullName'];
            this_form_status = roadMapObj[this_form]['instances'][this_inst]['status'];
            if(this_form_status) {
                if(!Data[this_form]) { Data[this_form] = {} }
                Data[this_form][this_inst] = formData[this_form][this_inst];
                Data[this_form][this_inst]['FormFullName'] = this_form_name;
            }
        }

        if (roadMapObj.current_form = 'Submission') {
            roadMapObj.current_form = roadMapObj.original_form;
        }

    } else if (type == 'Database' || type == 'Submission' || type == 'ApproveSubmission') {
        //Retrieve only the current forms that are shown
        var reached_current = 0; // Indicates whether every form upto and including current is done
        var skipped = [];
        var partial = [];
        for(var i=0; i<formList.length; i++) {
            var node = formList[i];
            this_form = node.getAttribute('form_id');
            this_inst = node.getAttribute('instance_number');
            this_form_name = roadMapObj[this_form]['FormFullName'];
            this_form_title = roadMapObj[this_form]['Form_Title']
            this_form_prompt = this_inst > 0 ? this_form_title + ' (' + this_inst + ')' : this_form_title;
            this_form_status = roadMapObj[this_form]['instances'][this_inst]['status'];

            if(!reached_current) {
                if(this_form_status == 'done') {
                    if(!Data[this_form]) { Data[this_form] = {} }
                    Data[this_form][this_inst] = formData[this_form][this_inst];
                    Data[this_form][this_inst]['FormFullName'] = this_form_name;
                } else if (this_form_status == 'partial' || this_form_status=='skipped') {
                    // Once they have clicked on it, it should be filled no matter what.
                    partial.push(this_form_prompt);
                } else {
                    skipped.push(this_form_prompt);
                }
            } else {
                skipped.push(this_form_prompt);
            }

            if(this_form == roadMapObj.current_form && this_inst == roadMapObj.current_form_instance) {
                reached_current = 1;
            }
        }

        //Error checkings before insertion to the database
        if(partial.length > 0) {
            alert("The following forms are not completed yet:\n" + partial.join("\n"));
            return 0;
        } else if(skipped.length > 0) {
            var ok = confirm("Are you sure you want to skip the following forms?\n" + skipped.join("\n"));
            if(!ok) { return 0; }
        } else if(formList.length > 1) {
            var c = confirm('Submit all forms?');
            if(!c) {
                return 0;
            }
        }
        roadMapObj.current_form = roadMapObj.original_form;
    }


    roadMapObj.current_form_instance = 0;

    //formObj.setAttribute('action',URL_version + '/cgi-bin/barcode.pl');
    formObj.setAttribute('action',formConfigs['submitpage']);
    formObj.setAttribute('method','POST');
    formObj.setAttribute('enctype','multipart/form-data');
    formObj.innerHTML='';
    formObj.appendChild(getInputNode({'type':'hidden','name':'FormData','value':ObjectToJSONString(Data)}));
    formObj.appendChild(getInputNode({'type':'hidden','name':'roadMap','value':ObjectToJSONString(roadMapObj)}));
    formObj.appendChild(getInputNode({'type':'hidden','name':'FormNav' ,'value':1}));
    formObj.appendChild(getInputNode({'type':'hidden','name':'FormType','value':type}));
    formObj.appendChild(getInputNode({'type':'hidden','name':'cgi_application','value':'alDente::Submission_App'}));
    formObj.appendChild(getInputNode({'type':'hidden','name':'rm','value':'Parse Submission'}));

    if(formConfigs['allowRepeat']) {
        var repeat = 1;
        repeat = prompt('How many times should this action be repeated?',1);
        formObj.appendChild(getInputNode({'type':'hidden','name':'FormNavRepeat','value':repeat}));
    }

    if(document.getElementById('FormNavExtraHTML')) {
        formObj.appendChild(document.getElementById('FormNavExtraHTML'));
    }

    for(var x in formConfigs['default_parameters']) {
        formObj.appendChild(getInputNode({'type':'hidden','name':x,'value':formConfigs['default_parameters'][x]}));
    }

    for(var x in formConfigs['submit_parameters']) {
        formObj.appendChild(getInputNode({'type':'hidden','name':x,'value':formConfigs['submit_parameters'][x]}));
    }

    formObj.submit();

    document.getElementById('formNavigator').innerHTML = 'Please wait while the forms are being submitted...';
    return 1;
}

function formUniqueCheck(table,field,object,prompt) {
    var params = "Database="+formConfigs['database'] + "&Database_host="+formConfigs['database_host'] + "&Table="+table + "&Field="+field + "&Value="+object.value ;

    var myReq = new Ajax.Request(formConfigs['uniquecheck'], {
        postBody: params,
        asynchronous: true,
        onComplete: function(request) {
            try {
                var result = request.responseText;
                if (result == 1) {
                    alert(prompt + ' is a unique field and "' + object.value + '" already exists. Please choose a different value.');
                    new Effect.Highlight(object, {
                      startcolor: 'CCCC33',
                      endcolor: 'FF3333',
                      restorecolor: 'FF3333'
                    });
                    object.value='';
                } else if (result == -1) {
                    alert("Error in unique check. Please Repor");
                } else {
                    object.style.backgroundColor='#ffffff';
                }
            } catch (err) {
                alert(err);
            }
        }
    }) ;

}

function _getForm(mode) { // 'next' or 'prev'
    var formList = document.getElementById('navRoadMapRoot').getElementsByTagName('LI');
    var curr_form = roadMapObj.current_form;
    var curr_form_inst = roadMapObj.current_form_instance;

    var result;
    if(mode == 'next') {
        for(var i=0; i<formList.length; i++) {
            var node = formList[i];
            if(node && node.getAttribute('form_id') == curr_form && node.getAttribute('instance_number') == curr_form_inst) {
                result = i+1;
                break;
            }
        }
    } else if(mode == 'prev') {
        for(var i=formList.length-1; i>=0; i--) {
            var node = formList[i];
            if(node && node.getAttribute('form_id') == curr_form && node.getAttribute('instance_number') == curr_form_inst) {
                result = i-1;
                break;
            }
        }
    }

    if(result >= 0 && formList[result]) {
        var ret = [];
        ret['form'] = formList[result].getAttribute('form_id');
        ret['inst'] = formList[result].getAttribute('instance_number');
        return ret;
    } else {
        return 0;
    }
}

function saveForm(formid) {
    var formObj = document.getElementById(formid);
    var myElementValues = {};
    
    for (var j=0;j<formElementTypes.length;j++) {
        var list = formObj.getElementsByTagName(formElementTypes[j]);
        for (var i=0;i<list.length;i++) {
            // Skip the form control buttons (ie next, add, ...)
            if(!(list[i].className == 'Action' || list[i].className=='Std' || list[i].className=='Search')) {
                var result;
                switch(formElementTypes[j]) {
                    case 'input'    : result = list[i].value;
                    break;
                    case 'textarea' : result = list[i].value;
                    break;
                    case 'select'   : {
                        var selected = [];
                        if(list[i].type == 'select-multiple') {
                            for(var option=0; option<list[i].options.length; option++) {
                                if(list[i].options[option].selected) {
                                    selected.push(list[i].options[option].value);
                                }
                            }
                        } else {
                            selected.push(list[i].value);
                        }
                        result = selected;
                    }
                    break;
                }
                myElementValues[list[i].name] = result;
            }
        }
    }
   return myElementValues;
}

