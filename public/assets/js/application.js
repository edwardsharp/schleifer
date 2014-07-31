var scheme   = "ws://";
var uri      = scheme + window.document.location.host + "/";
var ws       = new WebSocket(uri);
var videoContainer = document.getElementById("videoContainer");
var chan = "lobby";
var clients = 0;

ws.onmessage = function(message) {
  var data = JSON.parse(message.data);
  //set channel-dropdown-menu li w/ data
//  var iframeshit = "<iframe src='//www.youtube-nocookie.com/embed/v9AKH16--VE?rel=0' frameborder='0' allowfullscreen></iframe>";
  $("#currActive > .badge").html(data.clients);

  showVideoByID(videoContainer, data.videoid);
};

$("#input-form").on("submit", function(event) {
  event.preventDefault();
  var videoid   = $("#input-videoid")[0].value;
  chan = $("#input-channel")[0].value;

  //note the double bang to coerce a boolean, then invert. clever.
  if(!!$.trim($("#input-videoid").val()).length){
    //ws.send(JSON.stringify({ handle: handle, text: text }));
    ws.send(JSON.stringify({ chan: chan, videoid: videoid, clients: clients }));
    $("#input-videoid")[0].value = "";
  }
});

// $("#dropdown").on("change", function(event) {
//   //event.preventDefault();
//   console.log($("dropdown")[0].value);
//   //var videoid   = $("#input-videoid")[0].value;
//   //

//   //note the double bang to coerce a boolean, then invert. clever.
//   // if(!!$.trim($("#input-videoid").val()).length){
//   //   //ws.send(JSON.stringify({ handle: handle, text: text }));
//   //   ws.send(JSON.stringify({ videoid: videoid, chan: chan }));
//   //   $("#input-videoid")[0].value = "";
//   // }
// });

// "mini library" starts here
var youTubeAPILoaded = false;

function loadYouTubeAPI (callBack) {
    if (!youTubeAPILoaded) {
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/player_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
        
        window.onYouTubePlayerAPIReady = function () {
            youTubeAPILoaded = true;
            callBack();
        }
    } else {
        callBack();
    }
}

function showVideoByID (domElement, videoID) {
    loadYouTubeAPI(function () {
        if (!domElement.player) {
            domElement.player = new YT.Player(domElement, {
     
                videoId     : videoID,
                playerVars: {
                    'rel'       : 0,
                    'autoplay'  : 1,
                    'loop'      : 1,
                    'playlist'  : videoID,
                    controls    : 0,
                    showinfo    : 0 ,
                    modestbranding : 1,
                    wmode       : "opaque"
                },
                events: {
                  'onStateChange': onPlayerStateChange
                }
            });
        } else {
            //player.loadVideoById({videoId:String, startSeconds:Number, endSeconds:Number, suggestedQuality:String}):Void
            domElement.player.loadVideoById(videoID);
        }
        //nowPlaying = player;
       // currentPopup[0].previousLanguage = language
    });

}
// end of "mini library"


showVideoByID(videoContainer , "NoDTqebi860");
// when video ends
function onPlayerStateChange(event) {        
    if(event.data === 0) {            
        event.target.playVideo();
    }
}
    


    