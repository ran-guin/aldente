$(document).ready( function()  {
    /* Bootstrap Carousel Control Options */
    $(".cycle-slide").click(cycleCarousel);
    $(".pause-slide").click(pauseCarousel);
    $(".next-slide").click(nextCarousel);
    $(".prev-slide").click(prevCarousel);
    $(".first-slide").click(firstCarousel);
    $(".last-slide").click(lastCarousel);


    /**** Multiselect Specs ****/
$('.multiselect').multiselect({
        enableFiltering: true,
        enableCaseInsensitiveFiltering: true,
        filterPlaceholder: 'Search',
        includeSelectAllOption: true,
        includeSelectAllIfMoreThan: 15,
/*        includeSelectAllDivider: true,   Small bug with this option noted */
      /*  filterPlaceholder: 'Search', */ 
        buttonText: function(options, select) {
                var def = '';
                if ( $(this).attr('multiple') ) { def = 'None selected' }
                else { def = 'Select' }
                
                var selected = '';
                var count = 0;
                var separator = '<BR>';
                options.each(function () {
                    selected += $(this).text() + separator;
                    count = count+1;
                });
                var prompt;
                if (selected.length > separator.length) { prompt = selected.substr(0, selected.length - separator.length) }
                else { prompt = def }
               
                if (count > 4) { prompt = count + ' selected' }
                else if (count > 1) { prompt += '<BR>' } /* only use this if using br as a separator */
                
                prompt +=  ' <b class="caret"></b>';
                
                return prompt;
           },
    });

$('.multiselect').style = 'display:block';
  
    var ajaxElements = document.getElementsByClassName('ajax-populated');
    for(var i=0; i<ajaxElements.length; i++) {
            var searchFilters = ajaxElements[i].getElementsByClassName('multiselect-search');
            if (searchFilters.length) { 
                /** Watch this search filter element to enable ajax dropdown filtering **/
                searchFilters[0].addEventListener('change', watchSelect, false); 
            }
    }
});


function msPopulate (search, el, value) {
    var ajax = el.getAttribute('ajax');
    if (value) { ajax = ajax + '&Filter=' + value }
    
     var resetList = 0;
     var $j = jQuery;
     $j.get(ajax, function (data) {
        var options = data.split(',');
        var maxlength = 1000; 
        var data = new Array;
        
        if (! options || (options.length <= 1 && !options[0])) { data.push( { label:'-- no results --', value: '-- no results --'}); }
        else if (options.length > maxlength) {
            alert('Too many results found: (' + options.length + ') - please be more specific');
            return;    
        }    
        else {
            for (var i=0; i<options.length; i++) {
                data.push( {label:options[i], value:options[i]} );
            }
        }
        
        var msElement = '#' + el.id;
        $(msElement).multiselect('dataprovider', data);
    
        /** reset event listener - not sure why this is necessary, but perhaps dataprovider rebuilds element from scratch (?) **/
        var parent = el.parentNode;
        var searchElement = parent.getElementsByClassName('multiselect-search');
        searchElement[0].addEventListener('change', watchSelect, false);
     });
}

function watchSelect () {
    var parent = this.parentNode;
    if (parent) { 
        var gp = parent.parentNode;
        var value = this.value;
        if (gp && gp.parentNode) {
            var ggp = gp.parentNode;
            var ms = ggp.previousSibling;
            msPopulate(this, ms, value);
        }
    }
}

/* Bootstrap Carousel Control Options */
           function cycleCarousel() {
               var cid = '#' + this.getAttribute('data-target');
               $(this).carousel('cycle');
           }
           function pauseCarousel() {
               var cid = '#' + this.getAttribute('data-target');
               $(cid).carousel('pause');
           }
           function nextCarousel() {
               var cid = '#' + this.getAttribute('data-target');
               $(cid).carousel('next');
           }
           function prevCarousel() {
               var cid = '#' + this.getAttribute('data-target');
               $(cid).carousel('prev');
           }
           function firstCarousel() {
               var cid = '#' + this.getAttribute('data-target');
               $(cid).carousel(0);
           }
           function lastCarousel() {
               var cid = '#' + this.getAttribute('data-target');
               var targetSlide = '#' + this.getAttribute('target-slide');

               $(cid).carousel(targetSlide);
           }

