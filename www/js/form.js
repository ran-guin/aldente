/** Javascript functions for form elements **/

function SetElement(id,value) {
    var e = document.getElementById(id);
    e.value = value;
}

function ExpandList(id,count,type,multiplier) {
   
   var e = document.getElementById(id);
   if (e == undefined) { return }

   /* allow dynamic multiplier element */
   var xe = document.getElementById(multiplier);
   var x = 1; 
   if (xe && xe.value) { x = xe.value }
   
   count = count*x;

    /* keep track of original value entered */
    var ov;
    if (e.original) { ov = e.original }
    else { 
        ov = e.value;
        e.original = ov;
    }

    if (type.match(/^re/)) { 
        e.value = e.original; 
        e.original = '';
        return; 
    }
 
    var list = ov.split(/\s*,\s*/);
    var entered = list.length;

    if (entered == count) { return }
   
   var repeated = list.join(', ');
   var final = '';

   var repeat = parseInt(count / entered);
   if (repeat*entered == count) { 
       if ( type.match(/alt/) ) {
            /* alternate values repeatedly: ABAB.. */
            final = repeated;
            for (var i=1; i<repeat; i++) {
                final += ', ' + repeated;
            }
       }
       else {
           /* distribute values entered evenly across total: AA..BB.. */
           var list2 = new Array;
           for (var i=0; i<entered; i++) {
               for (var j=1; j<=repeat; j++) {
                   list2.push(list[i]);
               }
           }
           final = list2.join(', ');
       }       
       e.value = final;
    }
   else { 
        e.style.backgroundColor='#ffcc33'; 
        alert('Total # (' + count + ') should be evenly divisibly by number of values entered (' + entered + ')');
    }
    return;
}  
   
