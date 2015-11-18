/**********************************************************************************   
*   Copyright (C) 2001 Thomas Brattli
*   This script was released at DHTMLCentral.com
*   Visit for more great scripts!
*   This may be used and changed freely as long as this msg is intact!
*   We will also appreciate any links you could give us.
*
*   Made by Thomas Brattli
*
*   Script date: 09/04/2001 (keep this date to check versions) 
*********************************************************************************/

/***************************************************************************************
Common functions and variables
***************************************************************************************/
function lib_bwcheck(){ //Browsercheck (needed)
	this.ver=navigator.appVersion
	this.agent=navigator.userAgent
	this.dom=document.getElementById?1:0
	this.opera5=(navigator.userAgent.indexOf("Opera")>-1 && document.getElementById)?1:0
	this.ie5=(this.ver.indexOf("MSIE 5")>-1 && this.dom && !this.opera5)?1:0; 
	this.ie6=(this.ver.indexOf("MSIE 6")>-1 && this.dom && !this.opera5)?1:0;
	this.ie4=(document.all && !this.dom && !this.opera5)?1:0;
	this.ie=this.ie4||this.ie5||this.ie6
	this.mac=this.agent.indexOf("Mac")>-1
	this.ns6=(this.dom && parseInt(this.ver) >= 5) ?1:0; 
	this.ns4=(document.layers && !this.dom)?1:0;
	this.bw=(this.ie6 || this.ie5 || this.ie4 || this.ns4 || this.ns6 || this.opera5)
	return this
}
var bw=lib_bwcheck()

//Makes crossbrowser object.
function makeObj(obj){								
   	this.evnt=bw.dom? document.getElementById(obj):bw.ie4?document.all[obj]:bw.ns4?document.layers[obj]:0;;
	if(!this.evnt) return false
	this.css=bw.dom||bw.ie4?this.evnt.style:bw.ns4?this.evnt:0;	
   	this.wref=bw.dom||bw.ie4?this.evnt:bw.ns4?this.css.document:0;	
	this.writeIt=b_writeIt;																
	return this;
}

// A unit of measure that will be added when setting the position of a layer.
var px = bw.ns4||window.opera?"":"px";

function b_writeIt(text){
	if (bw.ns4){this.wref.write(text);this.wref.close()}
	else this.wref.innerHTML = text
}

/***************************************************************************************
HTML_Table dynamics
***************************************************************************************/
function cloneRow(myelement) {
    var e = myelement.parentNode;
    if ($(e).tooltip){
        $(e).tooltip('hide');
    }
    while (e.nodeName != 'TR'){
        e = e.parentNode;
    }
    pe = e.parentNode;
    pe.insertBefore(e.cloneNode(true),e);
}

function removeRow(myelement) {
  var tre = myelement.parentNode;
  while (tre.nodeName != 'TR'){
      tre = tre.parentNode;
  }
  pe = tre.parentNode;
  
  var foundAttr = 0;
  var ps = tre.previousSibling;
  while (ps && ps.nodeName != 'TR'){
      ps = ps.previousSibling;
  }

  var ns = tre.nextSibling;
  while (ns && ns.nodeName != 'TR'){
      ns = ns.nextSibling;
  }
  
  var thisAttr = tre.getAttribute('clone_index');
  if(ps && ps.hasAttribute('clone_index')){
      var sibAttr= ps.getAttribute('clone_index');
      if (sibAttr == thisAttr){
          foundAttr = 1;
      }
  }
  if (ns && ns.hasAttribute('clone_index')){
      var sibAttr= ns.getAttribute('clone_index');
      if (sibAttr == thisAttr){
          foundAttr = 1;
      }
  }// else { alert('not found at all')}
  
  if (foundAttr){ pe.removeChild(tre); }
}
/***************************************************************************************
Show and Hide Layers
***************************************************************************************/
var oLayers = new Array();

function showLayer(index,content,height) {
	if (oLayers[index]) {
		oLayers[index].writeIt(content);			
		oLayers[index].css.top = 350+px;
		oLayers[index].css.left = 80+px;	
		oLayers[index].css.height = height+px;
		oLayers[index].css.visibility = 'visible';
	}
}
	
function hideLayer(index) {
	if (oLayers[index]) {
		oLayers[index].css.clip.width = 0+px;
		oLayers[index].css.clip.height = 0+px;
		oLayers[index].css.visibility = 'hidden';	
	}
}

function setLayer(index) {
	var name = 'divLayer' + index;
	oLayers[index] = new makeObj(name);
}




//Tabbed browsing

/***********************************************
* DD Tab Menu script- © Dynamic Drive DHTML code library (www.dynamicdrive.com)
* This notice MUST stay intact for legal use
* Visit Dynamic Drive at http://www.dynamicdrive.com/ for full source code
***********************************************/

//Turn menu into single level image tabs (completely hides 2nd level)?
var turntosingle=0 //0 for no (default), 1 for yes

//Disable hyperlinks in 1st level tab images?
var disabletablinks=0 //0 for no (default), 1 for yes

var previoustab=""

if (turntosingle==1)
document.write('<style type="text/css">\n#tabcontentcontainer{display: none;}\n</style>')

function expandcontent(cid, aobject){
  if (disabletablinks==1)
    aobject.onclick=new Function("return false")
  if (document.getElementById){
    highlighttab(aobject)
    if (turntosingle==0){
      if (previoustab!="")
        document.getElementById(previoustab).style.display="none"
      document.getElementById(cid).style.display="block"
      previoustab=cid
    }
  }

  //alDente specific (cid=department);
  setcontent('Homepage',cid);
}

function highlighttab(aobject){
  if (typeof tabobjlinks=="undefined")
    collecttablinks()
  for (i=0; i<tabobjlinks.length; i++)
    tabobjlinks[i].className=""
  aobject.className="current"
}

function collecttablinks(){
  var tabobj=document.getElementById("tablist")
  tabobjlinks=tabobj.getElementsByTagName("LI")
}


// Set the initial tab when the page is loaded
function do_onload(s){
  collecttablinks()
  for (i=0; i<tabobjlinks.length; i++) {
    if(tabobjlinks[i].firstChild.nodeValue == s) {
      expandcontent(s,tabobjlinks[i]);
      break;
    }
  }

}
/*
if (window.addEventListener)
  window.addEventListener("load", do_onload, false)
else if (window.attachEvent)
  window.attachEvent("onload", do_onload)
else if (document.getElementById)
  window.onload=do_onload
*/
// End of Tabbed browsing

function setcontent(type,dept) {
  var divtags = document.getElementsByTagName('div'); //All the page div contents
  var active = document.getElementById('activecontent'); //Active page content
  var elementsFound = new Array();

  //Look for all the elements of type "type"
  for(i=0;i<divtags.length; i++) {
    if(divtags[i].getAttribute('type') == type) { // && divtags[i].getAttribute('dept') == dept) {
	elementsFound.push(i);
    }
  }

  //If only one element was found, just display it, otherwise this means that element is being shared
  //  between multiple departments => check for their department attribute
  if(elementsFound.length == 1) {
    active.innerHTML = divtags[elementsFound[0]].innerHTML;
    return;
  } else {
    for(i=0; i<elementsFound.length; i++) {
      if(divtags[elementsFound[i]].getAttribute('dept') == dept) {
        active.innerHTML = divtags[elementsFound[i]].innerHTML;
        return;
      }
    }
  }
}

function addOnLoadScript(s) {
    var body = document.getElementsByTagName('BODY');
    
    if (body) {
        var curr_code = body[0].getAttribute('onLoad');
        if (curr_code) {
            curr_code += s;
        } else {
            curr_code = s;
        }
        attachEventToNode(body[0],'onLoad',curr_code);
    }
}

function addOnUnLoadScript(s) {
    var body = document.getElementsByTagName('BODY');
    
    if (body) {
        var curr_code = body[0].getAttribute('onUnLoad');
        if (curr_code) {
            curr_code += s;
        } else {
            curr_code = s;
        }
        attachEventToNode(body[0],'onUnLoad',curr_code);
    }
    
}

