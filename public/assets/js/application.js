var scheme   = "ws://";
var uri      = scheme + window.document.location.host + "/";
var ws       = new WebSocket(uri);
var videoContainer = document.getElementById("videoContainer");
var channel = "lobby0";
var clients = 0;
var videoid = "MwlU824cS4s";
var videoList = [];

ws.onmessage = function(message) {
  var data;
  try{
    data = JSON.parse(message.data);

  //console.log("message,YO:"+message);

  //set channel-dropdown-menu li w/ data
//  var iframeshit = "<iframe src='//www.youtube-nocookie.com/embed/v9AKH16--VE?rel=0' frameborder='0' allowfullscreen></iframe>";
  
    if(data.clients > 0){
      $("#currActive > .badge").html(data.clients);
      console.log("data.clients,YO:"+data.clients);
    }

    if(data.videoid.length < 25){
      showVideoByID(videoContainer, data.videoid);
      console.log("data.videoid,YO:"+data.videoid);
    }

    if(data.channel.length > 0 && data.channel.length < 25){
      //$("#input-channel").val(data.chennel);
      console.log("data.channel,YO:"+data.channel);
    }
  }catch(e){

    console.log("CAUGHT ERROR" + e);
  
  }
};

$("#input-form").on("submit", function(event) {
  event.preventDefault();
  videoid   = $("#input-videoid")[0].value;
  //channel = $("#input-channel")[0].value;

  //note the double bang to coerce a boolean, then invert. clever.
  if(!!$.trim($("#input-videoid").val()).length){
    //ws.send(JSON.stringify({ handle: handle, text: text }));
    ws.send(JSON.stringify({ channel: channel, videoid: videoid, clients: clients }));
    //$("#input-videoid")[0].value = "";
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
//   //   ws.send(JSON.stringify({ videoid: videoid, channel: channel }));
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
    videoid = videoID;
    //push thumb
    //$("#videoL").append('<img src="http://img.youtube.com/vi/'+videoid+'/0.jpg" class="navbar-image" border="0" />');
    loadYouTubeAPI(function () {
        if (!domElement.player) {
            domElement.player = new YT.Player(domElement, {
     
                videoId     : videoID,
                playerVars: {
                    'rel'           : 0,
                    'autoplay'      : 1,
                    'loop'          : 1,
                    'playlist'      : videoID,
                    'controls'      : 0,
                    'showinfo'      : 0 ,
                    'modestbranding'  : 1,
                    'wmode'          : "opaque"
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

function updateTimeTimeout() {

  // if (!sessionStorage['currentVideoTime']) {
  //   //get time!?
  //   sessionStorage['currentVideoTime'] = 0;
  // } else {
  //   sessionStorage['currentVideoId']++;
  // }

  // document.querySelector('#videoListContent').innerHTML = 
  //     '<p>' + sessionStorage.getItem('currentVideoId') + ' times</p>';
  
  var time = videoContainer.player.getCurrentTime();
  
  var hours = Math.floor(time / 3600);
  time -= hours * 3600;
  var minutes = Math.floor(time / 60);
  time -= minutes * 60;
  var seconds = parseInt(time % 60, 10);
  var currTime = (hours < 1 ? '' : (hours + ':')) + (minutes < 10 ? '0' + minutes : minutes) + ':' + (seconds < 10 ? '0' + seconds : seconds);
  $("#currTime").html(currTime);
  
}

var myTimer = setInterval(updateTimeTimeout, 1000);
// end of "mini library"


showVideoByID(videoContainer , videoid);
// when video ends
function onPlayerStateChange(event) {        
    if(event.data === 0) {    
      console.log("WOULD PLAY... WS SENDING!!!");        
      ws.send(JSON.stringify({ channel: channel, videoid: videoid}));   
    }
}



$(".videoListItem").on("click", function(event) {
  event.preventDefault();
  videoid   = $("#input-videoid")[0].value;
  //channel = $("#input-channel")[0].value;
  var value = $(this).data('value');
  showVideoByID(videoContainer , value);
});

        
    // when video ends
    function onPlayerStateChange(event) {        
        if(event.data === 0) {            
            event.target.playVideo();
        }
    }


    