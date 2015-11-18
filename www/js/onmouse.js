var app = navigator.appName.toLowerCase();
var ver = navigator.appVersion.toLowerCase();
var ver = parseInt(ver.substring(0,1));
var ie4 = (app.indexOf("microsoft") != -1 && ver >= 4);
var nn4 = (app.indexOf("netscape") != -1 && ver >= 4);
var scriptAllow = (ie4 || nn4);

function preload() {
  
  this.length = preload.arguments.length;
  for(var i=0;i<this.length;i++) {
    this[i+1] = new Image();
    this[i+1].src = preload.arguments[i];
  }
  
}

function select(imgobj,imgstate) {
  if(scriptAllow && document.images) {
    var src = imgobj.src;
    var ext = src.lastIndexOf(".") - 1 ;
    if(ext !=-1) {
      var newsrc = src.substring(0,ext)+imgstate+src.substring(ext+1,src.length);
      imgobj.src = newsrc;
    }
  }
}

function select2(imgobj,imgstate) {
  if(scriptAllow && document.images) {
    var src = imgobj.src;
    var ext = src.lastIndexOf(".") - 1 ;
    var num = src.lastIndexOf("-") + 2 ;
    if(ext !=-1) {
      var newsrc = src.substring(0,num)+imgstate+src.substring(ext+1,src.length);

      imgobj.src = newsrc;
    }
  }
}
