angular.module('requestApp', ['ngResource'])
    .controller('reqController', function ($scope, $http) {
                console.log('loaded request Controller');

                var currentUser = $scope.userName || 'Me';
                $scope.requester = currentUser 

                $scope.requestDate = '2015-03-16'

                $scope.items = [];
                
                $scope.testButton = function() {
                    console.log('testbutton');

                    var a = document.getElementById('Selected_Item-ms').value;
                    console.log('read ' + a);
                    alert('read');
                }

                $scope.searchButton = function () {
                    console.log('internal search..');
                    var query = document.getElementById('searchQuery').value;
                    var replace = document.getElementById('replaceQuery').value;
                    var replaceFields = replace.split(/,/);
                    for (var i=0; i< replaceFields.length; i++) {
                        var tag = '<' + replaceFields[i] + '>';
                        query = query.replace(tag, '%');
                    }
                    $("#query").html(query);
                    
                    var encoded = escape(query);
                    console.log('ENCODED: ' + encoded);
                    
                    var urlpath = "/search/q/" + encoded;
                    console.log("URL CALL: " + urlpath);
                    $.ajax({ 
                        type : 'GET',
                        url: urlpath,
                        dataType : 'json'
                    })
                    .success( function (result) {
                        alert('search success');
                        alert(JSON.stringify(result));
//                        $('#message').html( dumpData(result) );
                    })
                    .error(function(err) { alert("Error: " + err); })
                    .complete(function(result) { alert(result); });                  
                    
                }   
                    
                $scope.ajaxQuery = function () {
                    console.log('run Ajax from angular method...');
                    // var urlpath = "http://limsdemo.bcgsc.ca:3000/search/t/Item/Ninite" 
                    var urlpath = "./../html/test_partial.html";
                    $("#message").html("URL: " + urlpath);
                    $.ajax({ 
                        type : 'GET',
                        url: urlpath,
                        dataType : 'text',
                    })
                    .success( function (result) {
                        alert('success');
                        $("#message").html(result);
                    })
                    .error(function(err) { alert("Error: " + err); })
                    .complete(function(result) { alert(result); });
                
                }
                
                $scope.addItem = function() {
                    var count = $scope.items.length + 100;
                    console.log('add item ' + count);
                    
                    var newval = document.getElementById('Selected_Item-ms').value;  /* match with id from request template */
                    if (newval) {
                        console.log('selected: ' + newval);
                        $scope.itemName = newval;
                    }    
                    console.log($scope);
                    $scope.items.push( {
                            id: count,
                            name: $scope.itemName,
                            qty : $scope.itemQty,
                            cat : $scope.itemCat
                    });
                    $scope.itemName = '';
                    $scope.itemQty  = '';
                    $scope.itemCat  = '';
                }

                $scope.createRequest = function() {
                console.log('add request');
                console.log('found request with ' + $scope.items.length + ' Items');
                        $scope.requests.push( { requester: $scope.requester });
                }
});

/* special button ids */
$("#executeAjax").on("click", function() {
        console.log('clicked ajax button...');
        $("#message").html('AJAX Output from onclick');
});

function runAjax() {
        console.log('runAjax method...');
        // var urlpath = "http://limsdemo.bcgsc.ca:3000/search/t/Item/Ninite" 
        var urlpath = "./../html/test_partial.html"; 
        //var urlpath = "alDente.pl" 
        $("#message").html("URL: " + urlpath);
        $.ajax({ 
            type : 'GET',
            url: urlpath,
            dataType : 'text'
        })
            .success( function (result) {
                alert('success');
                $("#message").html(result);
            })
            .error(function(err) { alert("Error: " + err); })
            .complete(function(result) { alert(result); });
}
