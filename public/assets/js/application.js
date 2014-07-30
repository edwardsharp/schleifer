var scheme   = "ws://";
var uri      = scheme + window.document.location.host + "/";
var ws       = new WebSocket(uri);
ws.onmessage = function(message) {
  var data = JSON.parse(message.data);
  var iframeshit = "<iframe width='1280' height='720' src='//www.youtube-nocookie.com/embed/v9AKH16--VE?rel=0' frameborder='0' allowfullscreen></iframe>";
  //data.videoid
  $("#sock-text").append("<div class='embed-responsive embed-responsive-16by9'>" + iframeshit + "</div>");
  $("#sock-text").stop().animate({
    scrollTop: $('#sock-text')[0].scrollHeight
  }, 800);
};

$("#input-form").on("submit", function(event) {
  event.preventDefault();
  var videoid   = $("#input-videoid")[0].value;
  //note the double bang to coerce a boolean, then invert. clever.
  if(!!$.trim($("#input-videoid").val()).length){
    //ws.send(JSON.stringify({ handle: handle, text: text }));
    ws.send(JSON.stringify({ videoid: videoid }));
    $("#input-videoid")[0].value = "";
  }
});
